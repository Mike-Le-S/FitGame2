# FitGame2 Audit Remediation - Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix all critical and high-priority findings from the 4 audits (security, DB coherence, Flutter quality, React quality) in priority order.

**Architecture:** Remediation in 6 phases -- Phase 1 (security hotfixes, no code architecture changes), Phase 2 (DB schema fixes via Supabase migrations), Phase 3 (cross-platform type alignment), Phase 4 (React quick fixes), Phase 5 (Flutter quick fixes), Phase 6 (code quality improvements). Each phase is independently deployable.

**Tech Stack:** Flutter/Dart, React/TypeScript, Supabase (PostgreSQL + Auth + RLS), Zustand stores

**Source audits:**
- `fitgame/docs/audits/security-audit.md` (20 findings)
- `fitgame/docs/audits/database-coherence-audit.md` (26 findings)
- `fitgame/docs/audits/flutter-quality-audit.md` (24 findings)
- `fitgame/docs/audits/react-quality-audit.md` (24 findings)

---

## Phase 1: Security Hotfixes (P0/P1 Security)

### Task 1: Remove hardcoded credentials from coach-web login

**Fixes:** VULN-005, QR-001
**Files:**
- Modify: `coach-web/src/pages/auth/login-page.tsx:22-23`

**Step 1: Fix the code**

```tsx
// Before (line 22-23):
const [email, setEmail] = useState('coach@fitgame.app')
const [password, setPassword] = useState('password')

// After:
const [email, setEmail] = useState('')
const [password, setPassword] = useState('')
```

**Step 2: Verify build**

Run: `cd coach-web && npm run build`
Expected: BUILD SUCCESS

**Step 3: Commit**

```bash
git add coach-web/src/pages/auth/login-page.tsx
git commit -m "fix(security): remove hardcoded login credentials from login page

VULN-005, QR-001: Login form was pre-filled with real credentials
that shipped in the production bundle."
```

---

### Task 2: Remove Supabase anon key from documentation

**Fixes:** VULN-001
**Files:**
- Modify: `docs/BACKEND_PLAN.md:26` (remove the hardcoded key)

**Step 1: Read the file and locate the key**

Read `docs/BACKEND_PLAN.md` and find the line containing `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

**Step 2: Replace key with placeholder**

Replace the actual JWT value with:
```
<SUPABASE_ANON_KEY from .env>
```

Do the same for the Supabase URL if it appears hardcoded -- replace with `<SUPABASE_URL from .env>`.

**Step 3: Commit**

```bash
git add docs/BACKEND_PLAN.md
git commit -m "fix(security): remove hardcoded Supabase anon key from docs

VULN-001: Anon key was committed in plaintext. Replaced with env var reference.
Note: key persists in git history -- consider rotating if repo is public."
```

---

### Task 3: Remove fake 2FA implementation

**Fixes:** VULN-003
**Files:**
- Modify: `coach-web/src/components/modals/setup-2fa-modal.tsx`
- Modify: `coach-web/src/pages/settings/settings-page.tsx` (remove 2FA toggle that calls fake modal)

**Step 1: Read both files fully**

Read `coach-web/src/components/modals/setup-2fa-modal.tsx` and `coach-web/src/pages/settings/settings-page.tsx` to understand the 2FA UI integration.

**Step 2: Replace 2FA modal with "coming soon" notice**

Replace the entire `Setup2FAModal` component body with a simple notice:

```tsx
export function Setup2FAModal({ isOpen, onClose }: Setup2FAModalProps) {
  if (!isOpen) return null

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50">
      <div className="bg-zinc-900 border border-zinc-800 rounded-2xl p-8 max-w-md w-full mx-4">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-bold text-white">Authentification 2FA</h2>
          <button onClick={onClose} className="text-zinc-400 hover:text-white">
            <X className="w-5 h-5" />
          </button>
        </div>
        <div className="text-center py-8">
          <Shield className="w-12 h-12 text-zinc-500 mx-auto mb-4" />
          <p className="text-zinc-300 mb-2">Bientot disponible</p>
          <p className="text-zinc-500 text-sm">
            L'authentification a deux facteurs sera disponible dans une prochaine mise a jour.
          </p>
        </div>
        <button
          onClick={onClose}
          className="w-full py-3 rounded-xl bg-zinc-800 text-white font-medium hover:bg-zinc-700 transition-colors"
        >
          Fermer
        </button>
      </div>
    </div>
  )
}
```

Remove the `onSuccess` prop from the interface and all callers.

**Step 3: Update settings page to remove 2FA toggle behavior**

In `settings-page.tsx`, find the 2FA toggle and change it so clicking it just opens the "coming soon" modal without pretending to enable 2FA. Remove any state that sets `two_factor_enabled = true`.

**Step 4: Verify build**

Run: `cd coach-web && npm run build`
Expected: BUILD SUCCESS

**Step 5: Commit**

```bash
git add coach-web/src/components/modals/setup-2fa-modal.tsx coach-web/src/pages/settings/settings-page.tsx
git commit -m "fix(security): replace fake 2FA with coming soon notice

VULN-003: 2FA was accepting any 6-digit code with a hardcoded secret.
Replaced with honest 'coming soon' notice until real Supabase MFA is implemented."
```

---

### Task 4: Move Google OAuth Client IDs to environment variables

**Fixes:** VULN-004, QF-002
**Files:**
- Modify: `fitgame/lib/core/services/supabase_service.dart:88-91`
- Modify: `fitgame/.env` (add new variables)

**Step 1: Read the .env file**

Read `fitgame/.env` to see current env vars format.

**Step 2: Add OAuth client IDs to .env**

Add to `fitgame/.env`:
```
GOOGLE_IOS_CLIENT_ID=241707453312-24n1s72q44oughb28s7fjhiaehgop7ss.apps.googleusercontent.com
GOOGLE_WEB_CLIENT_ID=241707453312-bcdt4drl7bi0t10pga3g83f9bp123384.apps.googleusercontent.com
```

**Step 3: Update supabase_service.dart to read from env**

```dart
// Before (lines 88-91):
const iosClientId = '241707453312-24n1s72q44oughb28s7fjhiaehgop7ss.apps.googleusercontent.com';
const webClientId = '241707453312-bcdt4drl7bi0t10pga3g83f9bp123384.apps.googleusercontent.com';

// After:
final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID']!;
final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']!;
```

Note: Change `const` to `final` since env vars aren't compile-time constants. The method already has access to `dotenv` (imported at line 4).

**Step 4: Ensure .env is in .gitignore**

Verify `fitgame/.gitignore` contains `.env`. If not, add it.

**Step 5: Commit**

```bash
git add fitgame/lib/core/services/supabase_service.dart
git commit -m "fix(security): move OAuth client IDs to environment variables

VULN-004, QF-002: Google OAuth client IDs were hardcoded in source.
Now loaded from .env via flutter_dotenv, consistent with Supabase credentials."
```

---

### Task 5: Fix notifications INSERT RLS policy

**Fixes:** VULN-002, DB-006
**Uses:** Supabase MCP tool `apply_migration`

**Step 1: Apply migration**

Use `mcp__plugin_supabase_supabase__apply_migration` with:
- project_id: `snqeueklxfdwxfrrpdvl`
- name: `fix_notifications_insert_policy`
- query:
```sql
-- Drop the overly permissive INSERT policy
DROP POLICY IF EXISTS "System can create notifications" ON public.notifications;

-- Only allow authenticated users to create notifications
-- In production, should be further restricted to service_role via Edge Functions
CREATE POLICY "Authenticated users can create notifications" ON public.notifications
  FOR INSERT WITH CHECK ((select auth.uid()) IS NOT NULL);
```

**Step 2: Verify**

Use `mcp__plugin_supabase_supabase__execute_sql` to confirm:
```sql
SELECT policyname, cmd, qual, with_check FROM pg_policies
WHERE tablename = 'notifications' AND cmd = 'INSERT';
```

Expected: New policy with `(select auth.uid()) IS NOT NULL` in `with_check`.

**Step 3: Commit note** (no local files changed, DB-only migration)

---

### Task 6: Fix handle_new_user search_path + duplicate profile creation

**Fixes:** VULN-007, DB-005, DB-003
**Uses:** Supabase MCP tool `apply_migration`

**Step 1: Apply migration to fix the trigger function**

Use `mcp__plugin_supabase_supabase__apply_migration`:
- name: `fix_handle_new_user_function`
- query:
```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role, goal, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'role', 'athlete'),
    'maintain',
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;
```

**Step 2: Remove manual profile INSERT from Flutter**

Modify `fitgame/lib/core/services/supabase_service.dart:62-70`:

```dart
// Before:
// Create profile after signup
if (response.user != null) {
  await client.from('profiles').insert({
    'id': response.user!.id,
    'email': email,
    'full_name': fullName,
    'role': role,
  });
}

// After:
// Profile is auto-created by handle_new_user() trigger
// Metadata (full_name, role) is passed via signUp data above
```

Delete lines 62-70 (the manual insert block).

**Step 3: Remove manual profile INSERT from React**

Read `coach-web/src/store/auth-store.ts` and find the manual profile insert after signUp (around line 155-162). Remove it and add a comment explaining the trigger handles it.

**Step 4: Verify build for both apps**

Run: `cd fitgame && flutter analyze`
Run: `cd coach-web && npm run build`
Expected: Both succeed

**Step 5: Commit**

```bash
git add fitgame/lib/core/services/supabase_service.dart coach-web/src/store/auth-store.ts
git commit -m "fix(auth): remove duplicate profile creation, fix trigger search_path

VULN-007, DB-005, DB-003: handle_new_user trigger now has fixed search_path,
uses ON CONFLICT DO NOTHING, and reads role/full_name from user metadata.
Removed manual profile INSERTs from both Flutter and React since the trigger handles it."
```

---

### Task 7: Implement real password change in settings

**Fixes:** VULN-015
**Files:**
- Modify: `coach-web/src/pages/settings/settings-page.tsx`

**Step 1: Read the settings page**

Read `coach-web/src/pages/settings/settings-page.tsx` and find the `handleChangePassword` function (~line 146).

**Step 2: Replace fake password change with real Supabase call**

```tsx
// Before:
// In real app, would call API to change password
setIsChangingPassword(false)
setPasswordChanged(true)

// After:
import { supabase } from '@/lib/supabase'

// Inside handleChangePassword, after validation:
try {
  const { error } = await supabase.auth.updateUser({ password: passwordForm.new })
  if (error) throw error
  setIsChangingPassword(false)
  setPasswordChanged(true)
  setPasswordForm({ current: '', new: '', confirm: '' })
} catch (err: unknown) {
  const message = err instanceof Error ? err.message : 'Erreur lors du changement de mot de passe'
  setError(message)
}
```

**Step 3: Implement real forgot password**

Read `coach-web/src/components/modals/forgot-password-modal.tsx` and replace the `setTimeout` simulation with:

```tsx
import { supabase } from '@/lib/supabase'

// Replace the setTimeout block:
const { error } = await supabase.auth.resetPasswordForEmail(email)
if (error) {
  setError(error.message)
  setLoading(false)
  return
}
setLoading(false)
setEmailSent(true)
```

**Step 4: Verify build**

Run: `cd coach-web && npm run build`

**Step 5: Commit**

```bash
git add coach-web/src/pages/settings/settings-page.tsx coach-web/src/components/modals/forgot-password-modal.tsx
git commit -m "fix(auth): implement real password change and forgot password

VULN-015, QR-009: Password change now calls supabase.auth.updateUser().
Forgot password now calls supabase.auth.resetPasswordForEmail() instead of setTimeout."
```

---

### Task 8: Enable leaked password protection + add .env to coach-web .gitignore

**Fixes:** VULN-008, VULN-014
**NOTE:** VULN-008 requires manual action in Supabase dashboard.

**Step 1: Add .env patterns to coach-web/.gitignore**

Read `coach-web/.gitignore`, then append:
```
# Environment variables
.env
.env.*
.env.local
```

**Step 2: Document the manual Supabase action**

Print instruction for Mike:
> **Manual action required:** Go to Supabase Dashboard > Authentication > Settings > Password Security > Enable "Reject leaked passwords"
> URL: https://supabase.com/dashboard/project/snqeueklxfdwxfrrpdvl/auth/settings

**Step 3: Commit**

```bash
git add coach-web/.gitignore
git commit -m "fix(security): add .env to coach-web gitignore

VULN-014: coach-web/.gitignore was missing .env patterns.
VULN-008: Leaked password protection must be enabled manually in Supabase dashboard."
```

---

## Phase 2: Database Schema Fixes

### Task 9: Fix FK references + add missing indexes

**Fixes:** DB-004, DB-014
**Uses:** Supabase MCP `apply_migration`

**Step 1: Apply migration**

- name: `fix_fk_references_and_indexes`
- query:
```sql
-- Fix FK references: change from auth.users to profiles with CASCADE
ALTER TABLE public.daily_nutrition_logs
  DROP CONSTRAINT daily_nutrition_logs_user_id_fkey,
  ADD CONSTRAINT daily_nutrition_logs_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.user_favorite_foods
  DROP CONSTRAINT user_favorite_foods_user_id_fkey,
  ADD CONSTRAINT user_favorite_foods_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.meal_templates
  DROP CONSTRAINT meal_templates_user_id_fkey,
  ADD CONSTRAINT meal_templates_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.community_foods
  DROP CONSTRAINT community_foods_contributed_by_fkey,
  ADD CONSTRAINT community_foods_contributed_by_fkey
    FOREIGN KEY (contributed_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

-- Add missing FK indexes
CREATE INDEX IF NOT EXISTS idx_community_foods_contributed_by ON public.community_foods(contributed_by);
CREATE INDEX IF NOT EXISTS idx_daily_nutrition_logs_diet_plan ON public.daily_nutrition_logs(diet_plan_id);
CREATE INDEX IF NOT EXISTS idx_weekly_schedule_day_type ON public.weekly_schedule(day_type_id);
```

**Step 2: Verify constraints**

```sql
SELECT tc.table_name, kcu.column_name, ccu.table_name AS foreign_table
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
WHERE constraint_type = 'FOREIGN KEY'
AND tc.table_name IN ('daily_nutrition_logs', 'user_favorite_foods', 'meal_templates', 'community_foods');
```

Expected: All reference `profiles` not `users`.

---

### Task 10: Create increment_total_sessions RPC + fix broken fallback

**Fixes:** DB-002, QF-003
**Uses:** Supabase MCP `apply_migration`
**Files:**
- Modify: `fitgame/lib/core/services/supabase_service.dart:366-377`

**Step 1: Create the RPC function**

- name: `create_increment_total_sessions_rpc`
- query:
```sql
CREATE OR REPLACE FUNCTION public.increment_total_sessions(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.profiles
  SET total_sessions = COALESCE(total_sessions, 0) + 1
  WHERE id = p_user_id;
END;
$$;
```

**Step 2: Fix the Flutter fallback code**

Read `fitgame/lib/core/services/supabase_service.dart` around line 366-377. Replace:

```dart
// Before:
await client.rpc('increment_total_sessions', params: {
  'user_id': currentUser!.id,
}).catchError((_) {
  client
      .from('profiles')
      .update({'total_sessions': client.rpc('get_total_sessions')})
      .eq('id', currentUser!.id);
});

// After:
try {
  await client.rpc('increment_total_sessions', params: {
    'p_user_id': currentUser!.id,
  });
} catch (e) {
  debugPrint('Error incrementing total_sessions: $e');
}
```

Note: parameter name is `p_user_id` (matching the SQL function parameter).

**Step 3: Commit**

```bash
git add fitgame/lib/core/services/supabase_service.dart
git commit -m "fix(db): create increment_total_sessions RPC, fix broken fallback

DB-002, QF-003: RPC function now exists. Removed broken fallback that
passed a Future object as an update value."
```

---

### Task 11: Create challenges table

**Fixes:** DB-001
**Uses:** Supabase MCP `apply_migration`

**Step 1: Apply migration**

- name: `create_challenges_table`
- query:
```sql
CREATE TABLE public.challenges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  creator_name text NOT NULL,
  title text NOT NULL,
  exercise_name text NOT NULL,
  type text NOT NULL CHECK (type IN ('weight', 'reps', 'time', 'custom')),
  target_value numeric NOT NULL,
  unit text NOT NULL,
  deadline timestamptz,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'expired')),
  participants jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.challenges ENABLE ROW LEVEL SECURITY;

CREATE INDEX idx_challenges_creator ON public.challenges(creator_id);
CREATE INDEX idx_challenges_status ON public.challenges(status);

CREATE POLICY "Users can view own and participated challenges" ON public.challenges
  FOR SELECT USING (
    creator_id = (select auth.uid())
    OR EXISTS (
      SELECT 1 FROM jsonb_array_elements(participants) p
      WHERE p->>'id' = (select auth.uid())::text
    )
  );

CREATE POLICY "Users can create challenges" ON public.challenges
  FOR INSERT WITH CHECK ((select auth.uid()) = creator_id);

CREATE POLICY "Creators can update challenges" ON public.challenges
  FOR UPDATE USING ((select auth.uid()) = creator_id);

CREATE POLICY "Creators can delete challenges" ON public.challenges
  FOR DELETE USING ((select auth.uid()) = creator_id);
```

**Step 2: Verify table exists**

```sql
SELECT column_name, data_type, is_nullable FROM information_schema.columns
WHERE table_name = 'challenges' ORDER BY ordinal_position;
```

---

### Task 12: Create atomic increment RPCs for race conditions

**Fixes:** QF-001
**Uses:** Supabase MCP `apply_migration`

**Step 1: Create RPCs**

- name: `create_atomic_increment_rpcs`
- query:
```sql
CREATE OR REPLACE FUNCTION public.increment_food_use_count(p_table text, p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_table = 'user_favorite_foods' THEN
    UPDATE public.user_favorite_foods
    SET use_count = COALESCE(use_count, 0) + 1, last_used_at = NOW()
    WHERE id = p_id;
  ELSIF p_table = 'community_foods' THEN
    UPDATE public.community_foods
    SET use_count = COALESCE(use_count, 0) + 1
    WHERE id = p_id;
  END IF;
END;
$$;
```

**Step 2: Update Flutter code**

Modify `fitgame/lib/core/services/supabase_service.dart` -- replace `updateFavoriteFoodUsage` (~line 816) and `incrementCommunityFoodUseCount` (~line 946):

```dart
// updateFavoriteFoodUsage - replace read-then-write with RPC:
static Future<void> updateFavoriteFoodUsage(String id) async {
  try {
    await client.rpc('increment_food_use_count', params: {
      'p_table': 'user_favorite_foods',
      'p_id': id,
    });
  } catch (e) {
    debugPrint('Error updating food usage: $e');
  }
}

// incrementCommunityFoodUseCount - replace read-then-write with RPC:
static Future<void> incrementCommunityFoodUseCount(String id) async {
  try {
    await client.rpc('increment_food_use_count', params: {
      'p_table': 'community_foods',
      'p_id': id,
    });
  } catch (e) {
    debugPrint('Error incrementing community food: $e');
  }
}
```

**Step 3: Commit**

```bash
git add fitgame/lib/core/services/supabase_service.dart
git commit -m "fix(db): replace race-condition increments with atomic RPCs

QF-001: updateFavoriteFoodUsage and incrementCommunityFoodUseCount
now use server-side atomic increment instead of read-then-write."
```

---

## Phase 3: Cross-Platform Type Alignment

### Task 13: Add missing fields to React types

**Fixes:** DB-012, DB-013
**Files:**
- Modify: `coach-web/src/lib/supabase.ts` (Profile interface)
- Modify: `coach-web/src/types/index.ts` (DietPlan interface)
- Modify: `coach-web/src/store/nutrition-store.ts` (dbToDietPlan mapping)

**Step 1: Read the files**

Read `coach-web/src/lib/supabase.ts`, `coach-web/src/types/index.ts`, and `coach-web/src/store/nutrition-store.ts`.

**Step 2: Add `goal` to Profile interface**

In `coach-web/src/lib/supabase.ts`, add to the Profile interface:
```typescript
goal?: 'lose' | 'maintain' | 'gain' | 'bulk' | 'cut' | 'performance'
```

**Step 3: Add `isActive` and `activeFrom` to DietPlan**

In `coach-web/src/types/index.ts`, add to the DietPlan interface:
```typescript
isActive: boolean
activeFrom?: string
```

**Step 4: Update dbToDietPlan mapping**

In `coach-web/src/store/nutrition-store.ts`, add to the `dbToDietPlan` function:
```typescript
isActive: row.is_active ?? false,
activeFrom: row.active_from ?? undefined,
```

**Step 5: Verify build**

Run: `cd coach-web && npm run build`

**Step 6: Commit**

```bash
git add coach-web/src/lib/supabase.ts coach-web/src/types/index.ts coach-web/src/store/nutrition-store.ts
git commit -m "fix(types): add missing goal, isActive, activeFrom fields to React types

DB-012, DB-013: Profile now includes goal field. DietPlan now includes
isActive and activeFrom, matching the database schema and Flutter types."
```

---

### Task 14: Fix notification metadata key mismatch

**Fixes:** DB-021
**Files:**
- Modify: `fitgame/lib/core/services/supabase_service.dart` (~line 1322)

**Step 1: Search for the issue**

Search for `'metadata'` in `supabase_service.dart` in the notifications insert context.

**Step 2: Replace `metadata` with `data`**

```dart
// Before:
'metadata': {'challenge_id': response['id']},

// After:
'data': {'challenge_id': response['id']},
```

**Step 3: Commit**

```bash
git add fitgame/lib/core/services/supabase_service.dart
git commit -m "fix(db): use correct column name 'data' for notification metadata

DB-021: Flutter was inserting into 'metadata' key but the DB column is 'data'.
The challenge_id data was being silently lost."
```

---

## Phase 4: React Quick Fixes

### Task 15: Fix duplicateProgram/duplicateDietPlan not awaited

**Fixes:** QR-023
**Files:**
- Modify: `coach-web/src/pages/programs/programs-list-page.tsx` (~line 64)
- Modify: `coach-web/src/pages/nutrition/nutrition-list-page.tsx` (similar pattern)

**Step 1: Read both files to find the exact handleDuplicate functions**

**Step 2: Make handlers async and await the result**

```tsx
// Before:
const handleDuplicate = (programId: string) => {
  setOpenMenuId(null)
  const newId = duplicateProgram(programId)
  if (newId) {
    navigate(`/programs/${newId}`)
  }
}

// After:
const handleDuplicate = async (programId: string) => {
  setOpenMenuId(null)
  const newId = await duplicateProgram(programId)
  if (newId) {
    navigate(`/programs/${newId}`)
  }
}
```

Apply same fix to nutrition-list-page.tsx for `duplicateDietPlan`.

**Step 3: Verify build**

Run: `cd coach-web && npm run build`

**Step 4: Commit**

```bash
git add coach-web/src/pages/programs/programs-list-page.tsx coach-web/src/pages/nutrition/nutrition-list-page.tsx
git commit -m "fix(react): await duplicateProgram/duplicateDietPlan before navigating

QR-023: Navigation was going to /programs/[object Promise] because
the async result was not awaited."
```

---

### Task 16: Fix NaN division + hardcoded sidebar badge

**Fixes:** QR-017, QR-007
**Files:**
- Modify: `coach-web/src/pages/students/students-list-page.tsx` (~line 54)
- Modify: `coach-web/src/components/layout/sidebar.tsx` (~line 22)

**Step 1: Fix NaN division**

```tsx
// Before:
const avgCompliance = Math.round(
  students.reduce((acc, s) => acc + s.stats.complianceRate, 0) / students.length
)

// After:
const avgCompliance = students.length > 0
  ? Math.round(students.reduce((acc, s) => acc + s.stats.complianceRate, 0) / students.length)
  : 0
```

**Step 2: Fix hardcoded badge**

In `sidebar.tsx`, replace the hardcoded `badge: 3` with a dynamic value from the messages store:

```tsx
import { useMessagesStore } from '@/store/messages-store'

// Inside the component:
const totalUnread = useMessagesStore(state => state.getTotalUnread())

// In the nav items array, replace:
{ path: '/messages', icon: MessageSquare, label: 'Messages', badge: 3 }
// With:
{ path: '/messages', icon: MessageSquare, label: 'Messages', badge: totalUnread || undefined }
```

**Step 3: Verify build**

Run: `cd coach-web && npm run build`

**Step 4: Commit**

```bash
git add coach-web/src/pages/students/students-list-page.tsx coach-web/src/components/layout/sidebar.tsx
git commit -m "fix(react): fix NaN on empty students list, use real unread badge count

QR-017: Division by zero when no students exist now returns 0.
QR-007: Sidebar message badge now uses getTotalUnread() instead of hardcoded 3."
```

---

### Task 17: Remove unused TanStack React Query

**Fixes:** QR-003
**Files:**
- Modify: `coach-web/src/App.tsx` (remove QueryClientProvider)
- Modify: `coach-web/package.json` (remove dependency)

**Step 1: Read App.tsx**

Read `coach-web/src/App.tsx` to find the QueryClientProvider wrapper.

**Step 2: Remove QueryClientProvider and QueryClient**

Remove the import, the `new QueryClient()` instantiation, and the `<QueryClientProvider>` wrapper from JSX.

**Step 3: Uninstall the package**

Run: `cd coach-web && npm uninstall @tanstack/react-query`

**Step 4: Check if recharts is also unused**

Search for `recharts` imports: `grep -r "from 'recharts'" coach-web/src/`
If no results, also run: `cd coach-web && npm uninstall recharts`

**Step 5: Verify build**

Run: `cd coach-web && npm run build`

**Step 6: Commit**

```bash
git add coach-web/src/App.tsx coach-web/package.json coach-web/package-lock.json
git commit -m "chore(react): remove unused @tanstack/react-query dependency

QR-003: React Query was installed and wrapped the app but zero hooks were used.
Removed ~12KB gzipped from the bundle."
```

---

### Task 18: Consolidate goalConfig duplications

**Fixes:** QR-005
**Files:**
- Modify: `coach-web/src/pages/students/students-list-page.tsx`
- Modify: `coach-web/src/pages/programs/programs-list-page.tsx`
- Modify: `coach-web/src/pages/nutrition/nutrition-list-page.tsx`
- Modify: `coach-web/src/components/modals/assign-program-modal.tsx`
- Modify: `coach-web/src/components/modals/assign-diet-modal.tsx`
- Reference: `coach-web/src/constants/goals.ts`

**Step 1: Read the centralized goalConfig**

Read `coach-web/src/constants/goals.ts` to see the canonical version.

**Step 2: In each of the 5 files with local goalConfig:**

1. Remove the local `goalConfig` definition
2. Add `import { goalConfig } from '@/constants/goals'`
3. Adjust any property accesses if the shape differs (e.g., if local had `.label` and centralized has `.name`)

**Step 3: Verify build**

Run: `cd coach-web && npm run build`

**Step 4: Commit**

```bash
git add coach-web/src/pages/students/students-list-page.tsx coach-web/src/pages/programs/programs-list-page.tsx coach-web/src/pages/nutrition/nutrition-list-page.tsx coach-web/src/components/modals/assign-program-modal.tsx coach-web/src/components/modals/assign-diet-modal.tsx
git commit -m "refactor(react): consolidate goalConfig to single source of truth

QR-005: Removed 5 local goalConfig duplicates. All files now import
from @/constants/goals for consistent labels and behavior."
```

---

### Task 19: Add Error Boundary

**Fixes:** QR-004
**Files:**
- Create: `coach-web/src/components/shared/error-boundary.tsx`
- Modify: `coach-web/src/components/layout/app-shell.tsx`

**Step 1: Create ErrorBoundary component**

```tsx
import { Component, type ReactNode } from 'react'
import { AlertTriangle, RefreshCw } from 'lucide-react'

interface ErrorBoundaryProps {
  children: ReactNode
  fallback?: ReactNode
}

interface ErrorBoundaryState {
  hasError: boolean
  error?: Error
}

export class ErrorBoundary extends Component<ErrorBoundaryProps, ErrorBoundaryState> {
  state: ErrorBoundaryState = { hasError: false }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { hasError: true, error }
  }

  handleReset = () => {
    this.setState({ hasError: false, error: undefined })
  }

  render() {
    if (this.state.hasError) {
      if (this.props.fallback) return this.props.fallback

      return (
        <div className="flex flex-col items-center justify-center min-h-[400px] p-8">
          <AlertTriangle className="w-12 h-12 text-orange-500 mb-4" />
          <h2 className="text-xl font-bold text-white mb-2">Une erreur est survenue</h2>
          <p className="text-zinc-400 text-center mb-6 max-w-md">
            {this.state.error?.message || "Quelque chose s'est mal passe."}
          </p>
          <button
            onClick={this.handleReset}
            className="flex items-center gap-2 px-4 py-2 rounded-xl bg-zinc-800 text-white hover:bg-zinc-700 transition-colors"
          >
            <RefreshCw className="w-4 h-4" />
            Reessayer
          </button>
        </div>
      )
    }

    return this.props.children
  }
}
```

**Step 2: Wrap Outlet in AppShell with ErrorBoundary**

In `app-shell.tsx`, import and wrap:
```tsx
import { ErrorBoundary } from '@/components/shared/error-boundary'

// In JSX, wrap the Outlet:
<ErrorBoundary>
  <Outlet />
</ErrorBoundary>
```

**Step 3: Verify build**

Run: `cd coach-web && npm run build`

**Step 4: Commit**

```bash
git add coach-web/src/components/shared/error-boundary.tsx coach-web/src/components/layout/app-shell.tsx
git commit -m "feat(react): add ErrorBoundary to catch page-level render errors

QR-004: App no longer crashes to white screen on runtime errors.
ErrorBoundary wraps the Outlet in AppShell with a retry button."
```

---

## Phase 5: Flutter Quick Fixes

### Task 20: Cache _screens list in MainNavigation

**Fixes:** QF-010
**Files:**
- Modify: `fitgame/lib/main.dart`

**Step 1: Read main.dart**

Read the file and find the `_screens` getter.

**Step 2: Convert getter to cached list**

```dart
// Before:
List<Widget> get _screens => [
  HomeScreen(onNavigateToTab: _navigateToTab),
  const WorkoutScreen(),
  const SocialScreen(),
  NutritionScreen(key: _nutritionScreenKey),
  const HealthScreen(),
  const ProfileScreen(),
];

// After (in initState or as late final):
late final List<Widget> _screens = [
  HomeScreen(onNavigateToTab: _navigateToTab),
  const WorkoutScreen(),
  const SocialScreen(),
  NutritionScreen(key: _nutritionScreenKey),
  const HealthScreen(),
  const ProfileScreen(),
];
```

**Step 3: Verify**

Run: `cd fitgame && flutter analyze`

**Step 4: Commit**

```bash
git add fitgame/lib/main.dart
git commit -m "perf(flutter): cache _screens list to prevent recreation on every build

QF-010: IndexedStack children were being recreated on every build cycle,
defeating its purpose of preserving state."
```

---

### Task 21: Fix FGEffects getters to static final

**Fixes:** QF-015
**Files:**
- Modify: `fitgame/lib/core/theme/fg_effects.dart`

**Step 1: Read the file**

Read `fitgame/lib/core/theme/fg_effects.dart`.

**Step 2: Convert all `static get` to `static final`**

For each getter that returns a constant value (like `neonGlow`, `glassBlur`), change from `static X get name =>` to `static final X name =`.

Note: If any getter uses runtime values that can't be `final` (like `FGColors.accent.withValues()`), those may need to stay as getters. Check each one.

**Step 3: Verify**

Run: `cd fitgame && flutter analyze`

**Step 4: Commit**

```bash
git add fitgame/lib/core/theme/fg_effects.dart
git commit -m "perf(flutter): convert FGEffects getters to static final constants

QF-015: Getters were creating new BoxShadow/List objects on every call,
including in 60fps animation paths."
```

---

### Task 22: Extract shared FGMeshGradient widget

**Fixes:** QF-009
**Files:**
- Create: `fitgame/lib/shared/widgets/fg_mesh_gradient.dart`
- Modify: 8 screen files that duplicate `_buildMeshGradient()`

**Step 1: Read one existing implementation**

Read `fitgame/lib/features/home/home_screen.dart` and find `_buildMeshGradient()` to understand the pattern.

**Step 2: Create the shared widget**

Create `fitgame/lib/shared/widgets/fg_mesh_gradient.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:fitgame/core/theme/fg_colors.dart';

class FGMeshGradient extends StatelessWidget {
  final List<Color>? colors;
  final List<Alignment>? positions;

  const FGMeshGradient({
    super.key,
    this.colors,
    this.positions,
  });

  @override
  Widget build(BuildContext context) {
    // Use the common mesh gradient implementation from the existing code
    // with configurable colors/positions
    final gradientColors = colors ?? [
      FGColors.accent.withValues(alpha: 0.08),
      Colors.purple.withValues(alpha: 0.05),
      Colors.blue.withValues(alpha: 0.03),
    ];

    final gradientPositions = positions ?? [
      const Alignment(-1.2, -0.8),
      const Alignment(1.0, 0.2),
      const Alignment(-0.5, 1.2),
    ];

    return Positioned.fill(
      child: Stack(
        children: List.generate(gradientColors.length, (i) {
          return Positioned.fill(
            child: Align(
              alignment: gradientPositions[i],
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [gradientColors[i], Colors.transparent],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
```

**Step 3: Replace in each screen file**

In each of the 8 files, replace the local `_buildMeshGradient()` method call with `const FGMeshGradient()` (or with custom colors if they differ).

Files to modify:
- `fitgame/lib/features/home/home_screen.dart`
- `fitgame/lib/features/workout/workout_screen.dart`
- `fitgame/lib/features/nutrition/nutrition_screen.dart`
- `fitgame/lib/features/health/health_screen.dart`
- `fitgame/lib/features/social/social_screen.dart`
- `fitgame/lib/features/profile/profile_screen.dart`
- `fitgame/lib/features/workout/tracking/active_workout_screen.dart`
- `fitgame/lib/features/workout/create/program_creation_flow.dart`

**Step 4: Verify**

Run: `cd fitgame && flutter analyze`

**Step 5: Commit**

```bash
git add fitgame/lib/shared/widgets/fg_mesh_gradient.dart fitgame/lib/features/
git commit -m "refactor(flutter): extract shared FGMeshGradient widget from 8 files

QF-009: Removed ~300 lines of duplicated mesh gradient code.
All screens now use the shared widget with configurable colors."
```

---

### Task 23: Move _initializeExercisesForDays out of build()

**Fixes:** QF-016
**Files:**
- Modify: `fitgame/lib/features/workout/create/program_creation_flow.dart`

**Step 1: Read the file around line 320**

**Step 2: Move the call from build() to _nextStep()**

Find where `_nextStep()` advances to step 3 and call `_initializeExercisesForDays()` there instead of in `build()`.

**Step 3: Verify**

Run: `cd fitgame && flutter analyze`

**Step 4: Commit**

```bash
git add fitgame/lib/features/workout/create/program_creation_flow.dart
git commit -m "fix(flutter): move side-effect out of build() into step transition

QF-016: _initializeExercisesForDays was called inside build() on every
rebuild when on step 3. Moved to _nextStep() transition."
```

---

## Phase 6: RLS Performance + Additional Fixes

### Task 24: Optimize RLS policies with (select auth.uid()) wrapper

**Fixes:** DB-015
**Uses:** Supabase MCP `apply_migration`

**Step 1: Get all current policies**

```sql
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies WHERE schemaname = 'public' ORDER BY tablename, policyname;
```

**Step 2: For each policy, regenerate with (select auth.uid())**

Apply migration `optimize_rls_auth_uid_wrapper` that drops and recreates each policy replacing `auth.uid()` with `(select auth.uid())`.

This is a large migration. Build the full SQL by reading each policy from Step 1 and wrapping `auth.uid()` calls. Be careful to preserve the exact logic of each policy.

**Step 3: Verify all policies**

Re-run the query from Step 1 and confirm all `qual` and `with_check` values now use `(select auth.uid())`.

---

### Task 25: Add DELETE policy to community_foods + friendships UPDATE fix

**Fixes:** VULN-009, VULN-020
**Uses:** Supabase MCP `apply_migration`

**Step 1: Apply migration**

- name: `fix_community_foods_and_friendships_policies`
- query:
```sql
-- Allow contributors to delete their own community foods
CREATE POLICY "Contributors can delete own community foods" ON public.community_foods
  FOR DELETE USING ((select auth.uid()) = contributed_by);

-- Fix friendships UPDATE: only recipients can accept/reject
DROP POLICY IF EXISTS "Users can update their own friendships" ON public.friendships;
CREATE POLICY "Recipients can update friend requests" ON public.friendships
  FOR UPDATE
  USING ((select auth.uid()) = friend_id)
  WITH CHECK (status IN ('accepted', 'blocked'));
```

---

### Task 26: Update documentation (CHANGELOG + SCREENS)

**Files:**
- Modify: `fitgame/docs/CHANGELOG.md`
- Modify: `fitgame/docs/SCREENS.md` (if relevant)

**Step 1: Add changelog entry**

```markdown
## 2026-02-06 - Security & Quality Audit Remediation

### Security Fixes
- Removed hardcoded credentials from coach-web login page
- Removed Supabase anon key from documentation
- Replaced fake 2FA with "coming soon" notice
- Moved Google OAuth client IDs to environment variables
- Fixed notifications INSERT policy (was unrestricted)
- Fixed handle_new_user search_path vulnerability
- Implemented real password change and forgot password
- Added .env to coach-web .gitignore

### Database Fixes
- Fixed FK references (4 tables now reference profiles instead of auth.users)
- Created increment_total_sessions RPC function
- Created challenges table with RLS policies
- Created atomic increment RPCs for race conditions
- Added 3 missing FK indexes
- Optimized all RLS policies with (select auth.uid()) wrapper
- Fixed community_foods DELETE policy
- Fixed friendships UPDATE policy

### Cross-Platform Fixes
- Added missing goal field to React Profile type
- Added isActive/activeFrom to React DietPlan type
- Fixed notification metadata column name mismatch

### React Fixes
- Fixed duplicateProgram navigation to [object Promise]
- Fixed NaN on empty students list
- Fixed sidebar message badge (was hardcoded to 3)
- Removed unused @tanstack/react-query dependency
- Consolidated goalConfig to single source
- Added ErrorBoundary for page-level error recovery

### Flutter Fixes
- Cached _screens list in MainNavigation
- Converted FGEffects getters to static final
- Extracted shared FGMeshGradient widget (removed 300 lines duplication)
- Moved side-effect out of build() in ProgramCreationFlow
- Fixed broken workout completion fallback
```

**Step 2: Commit**

```bash
git add fitgame/docs/CHANGELOG.md
git commit -m "docs: update CHANGELOG with audit remediation changes"
```

---

## Summary

| Phase | Tasks | Fixes | Estimated Time |
|-------|-------|-------|----------------|
| 1. Security Hotfixes | 1-8 | VULN-001 to 008, 014, 015 | 2-3 hours |
| 2. DB Schema Fixes | 9-12 | DB-001 to 006, DB-014, QF-001, QF-003 | 1-2 hours |
| 3. Type Alignment | 13-14 | DB-012, DB-013, DB-021 | 30 min |
| 4. React Quick Fixes | 15-19 | QR-003 to 007, QR-017, QR-023 | 1-2 hours |
| 5. Flutter Quick Fixes | 20-23 | QF-009, QF-010, QF-015, QF-016 | 1-2 hours |
| 6. RLS + Docs | 24-26 | DB-015, VULN-009, VULN-020 | 1 hour |
| **Total** | **26 tasks** | **~45 findings addressed** | **~8-12 hours** |

### Not addressed in this plan (require larger architectural changes):
- QF-004/005/006: God-class decomposition (SupabaseService, NutritionScreen, WorkoutScreen)
- QF-007: State management introduction (Riverpod)
- QF-017: Typed model classes for Map<String, dynamic> usage
- QR-010: Large page decomposition
- QR-011: useMemo/useCallback optimization
- QR-006: Events store Supabase integration
- QR-014: Student invite flow replacement
- DB-007/008: Flutter/React FoodEntry and WorkoutSession JSONB alignment (needs data migration)
