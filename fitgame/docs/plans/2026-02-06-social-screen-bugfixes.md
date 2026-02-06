# Social Screen Bugfixes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix 7 bugs across the social feature so the activity feed, challenges, and friend data display correctly with real Supabase data.

**Architecture:** Fixes span 2 main files (social_screen.dart + active_workout_screen.dart) + 1 Supabase migration. No new files, no new dependencies.

**Tech Stack:** Flutter/Dart, Supabase (PostgreSQL)

---

## Task 1: Enrich activity metadata in workout completion

The `createActivity()` call in workout completion only saves `session_id`, `duration_minutes`, and `personal_records` count. But the social screen reads `muscles`, `volume_kg`, `exercise_count` from metadata - and needs `exercises` array for topExercises and `pr` object for PRBadge.

**Files:**
- Modify: `fitgame/lib/features/workout/tracking/active_workout_screen.dart:407-421`

**Fix:** Replace the createActivity metadata block (lines 407-421) with enriched metadata:

```dart
        // Create activity feed entry
        try {
          // Build top exercises for social feed (top 3 by weight)
          final topExercisesData = _exercises
              .map((ex) {
                final maxSet = ex.sets
                    .where((s) => s.isCompleted && !s.isWarmup)
                    .fold<({double weight, int reps})>(
                      (weight: 0, reps: 0),
                      (best, s) => s.actualWeight > best.weight
                          ? (weight: s.actualWeight, reps: s.actualReps)
                          : best,
                    );
                return {
                  'name': ex.name,
                  'shortName': ex.name.length > 4 ? ex.name.substring(0, 4).toUpperCase() : ex.name.toUpperCase(),
                  'weightKg': maxSet.weight,
                  'reps': maxSet.reps,
                };
              })
              .where((e) => (e['weightKg'] as double) > 0)
              .toList()
            ..sort((a, b) => (b['weightKg'] as double).compareTo(a['weightKg'] as double));

          // Build muscles string
          final muscles = _exercises
              .map((ex) => ex.muscle)
              .where((m) => m.isNotEmpty)
              .toSet()
              .take(3)
              .join(' • ');

          // Build PR data for social feed
          Map<String, dynamic>? prData;
          if (prs.isNotEmpty) {
            final topPr = prs.first;
            prData = {
              'exerciseName': topPr['exerciseName'],
              'value': topPr['weightKg'],
              'gain': (topPr['weightKg'] as double) - (topPr['previousBest'] as double),
              'unit': 'kg',
            };
          }

          await SupabaseService.createActivity(
            activityType: 'workout_completed',
            title: '$_dayName terminée',
            description: '$totalSets séries • ${(_totalVolume / 1000).toStringAsFixed(1)}t volume',
            metadata: {
              'session_id': _sessionId,
              'duration_minutes': (_workoutSeconds / 60).round(),
              'volume_kg': _totalVolume,
              'exercise_count': _exercises.length,
              'muscles': muscles,
              'exercises': topExercisesData.take(3).toList(),
              if (prData != null) 'pr': prData,
              'personal_records': prs.length,
            },
          );
        } catch (e) {
          debugPrint('Error creating activity: $e');
        }
```

---

## Task 2: Parse topExercises + PR + respectGivers from metadata (social_screen.dart)

Three data fields are never parsed from the activity data: `topExercises`, `pr`, and `respectGivers`.

**Files:**
- Modify: `fitgame/lib/features/social/social_screen.dart:77-96`

**Fix:** Replace the activity mapping block (lines 77-96) to parse exercises and PR from metadata:

```dart
          _activities = activityData.map((data) {
            final user = data['user'] as Map<String, dynamic>?;
            final metadata = data['metadata'] as Map<String, dynamic>? ?? {};

            // Parse top exercises from metadata
            final exercisesList = metadata['exercises'] as List? ?? [];
            final topExercises = exercisesList.map((e) {
              final ex = e as Map<String, dynamic>;
              return ExerciseSummary(
                name: ex['name'] ?? '',
                shortName: ex['shortName'] ?? '',
                weightKg: (ex['weightKg'] as num?)?.toDouble() ?? 0,
                reps: (ex['reps'] as num?)?.toInt() ?? 0,
              );
            }).toList();

            // Parse PR from metadata
            final prData = metadata['pr'] as Map<String, dynamic>?;
            PersonalRecord? pr;
            if (prData != null) {
              pr = PersonalRecord(
                exerciseName: prData['exerciseName'] ?? '',
                value: (prData['value'] as num?)?.toDouble() ?? 0,
                gain: (prData['gain'] as num?)?.toDouble() ?? 0,
                unit: prData['unit'] ?? 'kg',
              );
            }

            return Activity(
              id: data['id'] ?? '',
              userName: user?['full_name'] ?? 'Utilisateur',
              userAvatarUrl: user?['avatar_url'] ?? '',
              workoutName: data['title'] ?? '',
              muscles: metadata['muscles'] ?? '',
              durationMinutes: (metadata['duration_minutes'] as num?)?.toInt() ?? 0,
              volumeKg: (metadata['volume_kg'] as num?)?.toDouble() ?? 0,
              exerciseCount: (metadata['exercise_count'] as num?)?.toInt() ?? 0,
              timestamp: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
              topExercises: topExercises,
              pr: pr,
              respectCount: 0,
              hasGivenRespect: false,
              respectGivers: [],
            );
          }).toList();
```

---

## Task 3: Load challenges + fix current user avatar

Challenges are **never loaded** from Supabase - `getChallenges()` is never called in `_loadSocialData()`. Also, the current user's avatar URL is missing from `ChallengeParticipant` objects (hardcoded `''`).

**Files:**
- Modify: `fitgame/lib/features/social/social_screen.dart`

### Fix 3a: Add `_currentUserAvatarUrl` state variable

After line 41 (`String _currentUserName = 'Toi';`), add:
```dart
  String _currentUserAvatarUrl = '';
```

### Fix 3b: Capture avatar URL in `_loadSocialData()`

After line 74 (`_currentUserName = userName;`), add:
```dart
          _currentUserAvatarUrl = profile?['avatar_url'] ?? '';
```

### Fix 3c: Load challenges in `_loadSocialData()`

After line 68 (`final unreadCount = ...`), add challenges loading:
```dart
      final challengesData = await SupabaseService.getChallenges();
```

Inside the `setState` block, after `_unreadNotifications = unreadCount;` (line 112), add challenges conversion:
```dart
          // Convert challenges data
          _challenges = challengesData.map((data) {
            final participantsRaw = data['participants'] as List? ?? [];
            final participants = participantsRaw.map((p) {
              final participant = p as Map<String, dynamic>;
              return ChallengeParticipant(
                id: participant['id'] ?? '',
                name: participant['name'] ?? '',
                avatarUrl: participant['avatar_url'] ?? '',
                currentValue: (participant['current_value'] as num?)?.toDouble() ?? 0,
                hasCompleted: participant['has_completed'] == true,
                completedAt: participant['completed_at'] != null
                    ? DateTime.tryParse(participant['completed_at'])
                    : null,
              );
            }).toList();

            return Challenge(
              id: data['id'] ?? '',
              title: data['title'] ?? '',
              exerciseName: data['exercise_name'] ?? '',
              type: ChallengeType.values.firstWhere(
                (t) => t.name == data['type'],
                orElse: () => ChallengeType.weight,
              ),
              targetValue: (data['target_value'] as num?)?.toDouble() ?? 0,
              unit: data['unit'] ?? 'kg',
              deadline: data['deadline'] != null ? DateTime.tryParse(data['deadline']) : null,
              status: ChallengeStatus.values.firstWhere(
                (s) => s.name == data['status'],
                orElse: () => ChallengeStatus.active,
              ),
              creatorId: data['creator_id'] ?? '',
              creatorName: data['creator_name'] ?? '',
              participants: participants,
              createdAt: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
            );
          }).toList();
```

### Fix 3d: Fix avatarUrl in `_participateInChallenge()`

Replace line 257 (`avatarUrl: '',`) with:
```dart
                avatarUrl: _currentUserAvatarUrl,
```

### Fix 3e: Fix avatarUrl in `_createChallenge()`

Replace line 332 (`avatarUrl: '',`) with:
```dart
          avatarUrl: _currentUserAvatarUrl,
```

---

## Task 4: Fix Friend.isOnline and lastActive

Both `isOnline` and `lastActive` are hardcoded. The profiles table has an `updated_at` field that we can use as an approximation: if updated in last 5 minutes → online.

**Files:**
- Modify: `fitgame/lib/features/social/social_screen.dart:99-110`

**Fix:** Replace the friends mapping block (lines 99-110):

```dart
          _friends = friendsData.map((data) {
            final friend = data['friend'] as Map<String, dynamic>?;
            final lastActiveAt = friend?['updated_at'] != null
                ? DateTime.tryParse(friend!['updated_at'])
                : null;
            final isRecentlyActive = lastActiveAt != null &&
                DateTime.now().difference(lastActiveAt).inMinutes < 5;
            return Friend(
              id: friend?['id'] ?? '',
              name: friend?['full_name'] ?? 'Ami',
              avatarUrl: friend?['avatar_url'] ?? '',
              isOnline: isRecentlyActive,
              streak: friend?['current_streak'] ?? 0,
              totalWorkouts: friend?['total_sessions'] ?? 0,
              lastActive: lastActiveAt,
            );
          }).toList();
```

---

## Task 5: Update challenge progress after workout completion

When a workout completes, check active challenges and update progress if the workout includes a matching exercise.

**Files:**
- Modify: `fitgame/lib/core/services/supabase_service.dart` (add getActiveChallengesForExercises)
- Modify: `fitgame/lib/features/workout/tracking/active_workout_screen.dart` (call after completion)

### Step 1: Add helper method in supabase_service.dart

After `updateChallengeProgress()` (after line 1526), add:

```dart
  /// Get active challenges where current user participates
  static Future<List<Map<String, dynamic>>> getActiveChallenges() async {
    if (currentUser == null) return [];
    try {
      final response = await client
          .from('challenges')
          .select()
          .eq('status', 'active');

      // Filter to challenges where user is a participant
      return List<Map<String, dynamic>>.from(response).where((c) {
        final participants = c['participants'] as List? ?? [];
        return participants.any((p) => (p as Map)['id'] == currentUser!.id);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching active challenges: $e');
      return [];
    }
  }
```

### Step 2: Call in active_workout_screen.dart

After the activity feed entry block (after line ~421, before the catch), add:

```dart
        // Update challenge progress
        try {
          final activeChallenges = await SupabaseService.getActiveChallenges();
          for (final challenge in activeChallenges) {
            final exerciseName = challenge['exercise_name'] as String? ?? '';
            final challengeType = challenge['type'] as String? ?? '';

            // Find matching exercise in this workout
            for (final ex in _exercises) {
              if (ex.name.toLowerCase() == exerciseName.toLowerCase()) {
                double value = 0;
                if (challengeType == 'weight') {
                  value = ex.sets
                      .where((s) => s.isCompleted && !s.isWarmup)
                      .fold<double>(0, (max, s) => s.actualWeight > max ? s.actualWeight : max);
                } else if (challengeType == 'reps') {
                  value = ex.sets
                      .where((s) => s.isCompleted && !s.isWarmup)
                      .fold<double>(0, (max, s) => s.actualReps > max ? s.actualReps.toDouble() : max);
                }
                if (value > 0) {
                  await SupabaseService.updateChallengeProgress(
                    challenge['id'],
                    value,
                  );
                }
                break;
              }
            }
          }
        } catch (e) {
          debugPrint('Error updating challenge progress: $e');
        }
```

---

## Task 6: Friendships updated_at trigger (Supabase migration)

The `updated_at` column on `friendships` defaults to `now()` on insert but never auto-updates on changes (e.g., pending → accepted).

**Files:**
- Supabase migration: Create trigger

**SQL:**

```sql
-- Create or replace the generic updated_at trigger function
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add trigger to friendships table
DROP TRIGGER IF EXISTS set_friendships_updated_at ON public.friendships;
CREATE TRIGGER set_friendships_updated_at
  BEFORE UPDATE ON public.friendships
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();
```

---

## Task 7: Update CHANGELOG and SCREENS docs

Add changelog entry for all social screen fixes.

---

## Summary

| Task | Bug | Files | Impact |
|------|-----|-------|--------|
| 1 | Activity metadata incomplete | active_workout_screen.dart | Social feed shows exercises, muscles, volume, PRs |
| 2 | topExercises + PR never parsed | social_screen.dart | Exercise cards and PR badges display |
| 3 | Challenges never loaded + avatar missing | social_screen.dart | Challenges tab works, avatars display |
| 4 | Friend online/lastActive fake | social_screen.dart | Real online status and timestamps |
| 5 | Challenge progress never updated | active_workout_screen.dart + supabase_service.dart | Challenge progress tracks from workouts |
| 6 | Friendships updated_at stale | Supabase migration | Correct timestamps on status changes |
| 7 | Docs outdated | CHANGELOG.md | Documentation current |
