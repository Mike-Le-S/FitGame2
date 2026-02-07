# Profile Screen Bugfixes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix 6 bugs in the profile screen so missing columns exist, RLS policies work, avatar is displayed, profile refreshes after edit, and achievements load from Supabase.

**Architecture:** Fixes span 3 Flutter files + 1 Supabase migration. No new files needed (except migration).

**Tech Stack:** Flutter/Dart, Supabase (PostgreSQL)

---

## Task 1: Supabase migration - add missing columns + fix RLS policies

The `profiles` table is missing 4 columns that the app reads/writes. Additionally, 3 RLS policies are broken.

### Fix 1a: Add missing columns to profiles

```sql
-- Add missing columns to profiles table
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS avatar_index integer DEFAULT 0,
ADD COLUMN IF NOT EXISTS workout_reminders boolean DEFAULT true,
ADD COLUMN IF NOT EXISTS rest_day_reminders boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS progress_alerts boolean DEFAULT true;
```

### Fix 1b: Add INSERT policy for Google sign-in

`signInWithGoogle()` manually inserts a profile row, but there's no INSERT RLS policy. The `handle_new_user()` trigger uses SECURITY DEFINER so it bypasses RLS, but the manual Google sign-in insert from the client needs an INSERT policy.

```sql
-- Allow authenticated users to insert their own profile
CREATE POLICY "Users can insert own profile"
ON public.profiles FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = id);
```

### Fix 1c: Add SELECT policy for friends

Social features need to read friend profiles (names, avatars). Currently SELECT only allows own profile + coach's students.

```sql
-- Allow users to view profiles of their friends
CREATE POLICY "Users can view friend profiles"
ON public.profiles FOR SELECT
TO authenticated
USING (
  auth.uid() = id
  OR id IN (
    SELECT friend_id FROM public.friendships
    WHERE user_id = auth.uid() AND status = 'accepted'
    UNION
    SELECT user_id FROM public.friendships
    WHERE friend_id = auth.uid() AND status = 'accepted'
  )
);
```

**IMPORTANT:** This policy overlaps with the existing "Users can view own profile" policy. Since PostgreSQL OR's all policies together, this is fine - but check if the existing policy should be dropped to avoid confusion.

### Fix 1d: Fix challenges UPDATE policy for participants

Currently only `creator_id = auth.uid()` can UPDATE. Participants need to update too (for joinChallenge and updateChallengeProgress).

```sql
-- Drop existing restrictive policy
DROP POLICY IF EXISTS "Users can update own challenges" ON public.challenges;

-- Allow creator and participants to update challenges
CREATE POLICY "Users can update own or joined challenges"
ON public.challenges FOR UPDATE
TO authenticated
USING (
  creator_id = auth.uid()
  OR participants::text LIKE '%' || auth.uid()::text || '%'
);
```

---

## Task 2: Fix avatar display + profile refresh after edit

**Files:**
- Modify: `fitgame/lib/features/profile/profile_screen.dart`

### Fix 2a: Add avatar_index state variable

After line 42 (`String _memberSince = '';`), add:

```dart
int _avatarIndex = 0;
```

### Fix 2b: Load avatar_index from profile

In `_loadUserProfile()`, inside the setState block, after line 78 (`_progressAlerts = ...`), add:

```dart
_avatarIndex = profile['avatar_index'] ?? 0;
```

### Fix 2c: Display avatar emoji instead of first letter

Replace line 344 (`_userName[0].toUpperCase(),`) with code that shows the emoji:

```dart
// BEFORE (line 342-349):
child: Center(
  child: Text(
    _userName[0].toUpperCase(),
    style: FGTypography.h1.copyWith(
      fontSize: 32,
      color: FGColors.textOnAccent,
    ),
  ),
),

// AFTER:
child: Center(
  child: Text(
    _getAvatarEmoji(_avatarIndex),
    style: const TextStyle(fontSize: 36),
  ),
),
```

Add a helper method after `_getAchievementIcon`:

```dart
String _getAvatarEmoji(int index) {
  const avatars = ['💪', '🏋️', '🏃', '🧘', '🚴', '⚡', '🔥', '🎯'];
  if (index < 0 || index >= avatars.length) return avatars[0];
  return avatars[index];
}
```

### Fix 2d: Pass correct avatar_index to EditProfileSheet

Replace line 363 (`currentAvatarIndex: 0,`) with:

```dart
currentAvatarIndex: _avatarIndex,
```

### Fix 2e: Await EditProfileSheet and refresh profile

Replace lines 357-364 (the onTap handler):

```dart
// BEFORE:
onTap: () {
  HapticFeedback.lightImpact();
  EditProfileSheet.show(
    context,
    currentName: _userName,
    currentEmail: _userEmail,
    currentAvatarIndex: 0,
  );
},

// AFTER:
onTap: () async {
  HapticFeedback.lightImpact();
  await EditProfileSheet.show(
    context,
    currentName: _userName,
    currentEmail: _userEmail,
    currentAvatarIndex: _avatarIndex,
  );
  _loadUserProfile();
},
```

---

## Task 3: Wire up AchievementsSheet to Supabase backend

The sheet is a StatelessWidget with a hardcoded empty list. Convert to StatefulWidget that loads from `SupabaseService.getAchievements()`.

**Files:**
- Modify: `fitgame/lib/features/profile/sheets/achievements_sheet.dart`

### Fix 3a: Add SupabaseService import

After line 8 (`import '../../../core/theme/fg_typography.dart';`), add:

```dart
import '../../../core/services/supabase_service.dart';
```

### Fix 3b: Convert to StatefulWidget

Replace `class AchievementsSheet extends StatelessWidget` with StatefulWidget pattern:

```dart
class AchievementsSheet extends StatefulWidget {
  const AchievementsSheet({super.key});

  static Future<void> show(BuildContext context) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const AchievementsSheet(),
    );
  }

  @override
  State<AchievementsSheet> createState() => _AchievementsSheetState();
}

class _AchievementsSheetState extends State<AchievementsSheet> {
  List<Achievement> _achievements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    try {
      final data = await SupabaseService.getAchievements();
      if (mounted) {
        setState(() {
          _achievements = data.map((a) => Achievement(
            id: a['id'] as String,
            name: a['name'] as String? ?? '',
            description: a['description'] as String? ?? '',
            icon: _getIcon(a['icon'] as String? ?? ''),
            unlocked: a['unlocked'] as bool? ?? false,
            unlockedAt: a['unlocked_at'] != null
                ? DateTime.tryParse(a['unlocked_at'] as String)
                : null,
            rarity: _getRarity(a['category'] as String? ?? ''),
          )).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading achievements: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'emoji_events': return Icons.emoji_events_rounded;
      case 'local_fire_department': return Icons.local_fire_department_rounded;
      case 'whatshot': return Icons.whatshot_rounded;
      case 'fitness_center': return Icons.fitness_center_rounded;
      case 'group': return Icons.group_rounded;
      case 'restaurant': return Icons.restaurant_rounded;
      case 'trending_up': return Icons.trending_up_rounded;
      case 'military_tech': return Icons.military_tech_rounded;
      case 'bolt': return Icons.bolt_rounded;
      case 'star': return Icons.star_rounded;
      default: return Icons.emoji_events_rounded;
    }
  }

  AchievementRarity _getRarity(String category) {
    switch (category) {
      case 'legendary': return AchievementRarity.legendary;
      case 'epic': return AchievementRarity.epic;
      case 'rare': return AchievementRarity.rare;
      default: return AchievementRarity.common;
    }
  }
```

### Fix 3c: Move rarity helpers to instance methods

The `_getRarityColor` and `_getRarityLabel` methods were on the StatelessWidget. Move them into the State class (they remain unchanged).

### Fix 3d: Add loading state to build method

In the `build()` method, before the list/empty state section, add a loading check:

```dart
// Show loading spinner while fetching
if (_isLoading) {
  return const Center(
    child: CircularProgressIndicator(color: FGColors.accent),
  );
}
```

Replace `_buildEmptyState()` to show a different message when loaded but empty vs never loaded.

---

## Task 4: Update CHANGELOG

Add changelog entry for all profile screen fixes.

---

## Agent Dispatch Strategy

| Agent | Tasks | Files |
|-------|-------|-------|
| **Agent A** | Task 1 | Supabase migration (4 columns + 3 RLS policies) |
| **Agent B** | Task 2 | `profile_screen.dart` (5 edits: avatar state, load, display, pass index, refresh) |
| **Agent C** | Task 3 | `achievements_sheet.dart` (convert to StatefulWidget + load from Supabase) |

Agents A, B, C can all run **in parallel** since they touch different files.
Agent for Task 4 (CHANGELOG) runs after all others complete.
