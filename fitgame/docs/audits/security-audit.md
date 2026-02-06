# Security Audit Report - FitGame2

**Date**: 2026-02-06
**Auditor**: Claude Opus 4.6 (automated)
**Scope**: Flutter mobile app + React coach web portal + Supabase backend
**Supabase Project ID**: `snqeueklxfdwxfrrpdvl`

---

## Executive Summary

**Overall Security Posture: MODERATE - Requires Attention**

The FitGame2 project has a reasonable security foundation with RLS enabled on all public tables and proper use of environment variables for Supabase credentials. However, several critical and high-severity findings require immediate attention, particularly around hardcoded secrets in version control, an overly permissive RLS policy on notifications, a fake 2FA implementation, hardcoded Google OAuth client IDs, and the absence of mobile-specific security measures.

| Severity | Count |
|----------|-------|
| Critical (P0) | 3 |
| High (P1) | 5 |
| Medium (P2) | 7 |
| Low (P3) | 5 |
| **Total Findings** | **20** |

---

## Critical Findings (P0 - Fix Immediately)

### [VULN-001] Supabase Anon Key Hardcoded in Version-Controlled Documentation

- **Risk**: Critical
- **Location**: `docs/BACKEND_PLAN.md:26`
- **Description**: The Supabase anon key (JWT) is hardcoded in plain text in the `BACKEND_PLAN.md` file, which is committed to Git. The full key is exposed:
  ```
  eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNucWV1ZWtseGZkd3hmcnJwZHZsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk5NDExMTMsImV4cCI6MjA4NTUxNzExM30.0fiwCVZU4kuK2aWMBSI6FCPp5YLa3L9PN9XobPQ2m3Y
  ```
- **Impact**: While the anon key is designed to be public-facing (restricted by RLS), having it in Git history alongside the Project URL makes it trivially easy for attackers to enumerate tables and attempt API abuse. Combined with the permissive notifications INSERT policy (VULN-002), this becomes exploitable. Even if the key is rotated, it will persist in Git history forever.
- **Remediation**:
  1. Remove the anon key from `docs/BACKEND_PLAN.md`.
  2. Use `git filter-branch` or `BFG Repo-Cleaner` to purge the key from Git history if the repository is public or shared.
  3. Reference the key only via `.env` files or Supabase dashboard links.

### [VULN-002] Notifications Table Has Unrestricted INSERT Policy (RLS Bypass)

- **Risk**: Critical
- **Location**: Supabase RLS policy `"System can create notifications"` on `public.notifications`
- **Description**: The `notifications` INSERT policy uses `WITH CHECK (true)`, meaning **any authenticated user** can insert a notification for **any other user**. The Supabase security advisor flagged this as well. The policy is granted to the `public` role (i.e., all authenticated users via the anon key).
- **Impact**: Any authenticated user can:
  - Spam any user with fake notifications
  - Inject phishing content into notification titles/bodies (social engineering)
  - Create fake "coach_message" or "challenge_invite" notifications to trick users
  - Perform data injection via the `data` JSONB column
- **Remediation**:
  Replace the policy with a proper check. Notifications should only be insertable by the system (via a service role key in an Edge Function or database trigger), not directly by clients:
  ```sql
  -- Option 1: Restrict to service_role only (requires Edge Function for creation)
  DROP POLICY "System can create notifications" ON public.notifications;
  CREATE POLICY "Service role can create notifications"
    ON public.notifications FOR INSERT
    TO service_role
    WITH CHECK (true);

  -- Option 2: If client-side creation needed, restrict to own notifications only
  CREATE POLICY "Users can create own notifications"
    ON public.notifications FOR INSERT
    WITH CHECK (auth.uid() = user_id);
  ```

### [VULN-003] Fake 2FA Implementation - Accepts Any 6-Digit Code

- **Risk**: Critical
- **Location**: `coach-web/src/components/modals/setup-2fa-modal.tsx:19, 29`
- **Description**: The 2FA setup modal is entirely fake/mock:
  - Uses a hardcoded secret key: `JBSWY3DPEHPK3PXP` (line 19)
  - Displays a static fake SVG QR code (not generated from any real TOTP secret)
  - Accepts **any 6-digit number** as valid verification (line 29: `code.length === 6 && /^\d+$/.test(code)`)
  - Does not call any Supabase MFA API
  - Sets `two_factor_enabled` in local state only (no server-side enforcement)
- **Impact**: Users who believe they have enabled 2FA have zero additional security. The `coaches.two_factor_enabled` database field may be `true`, giving a false sense of security. There is no actual TOTP verification at login time.
- **Remediation**:
  Either:
  1. Remove the 2FA UI entirely and communicate that it is not yet implemented.
  2. Implement real 2FA using Supabase Auth MFA API:
     ```typescript
     // Enroll
     const { data } = await supabase.auth.mfa.enroll({ factorType: 'totp' })
     // data.totp.qr_code contains the real QR code
     // data.totp.secret contains the real secret

     // Verify
     const { data: challenge } = await supabase.auth.mfa.challenge({ factorId })
     const { data: verify } = await supabase.auth.mfa.verify({
       factorId, challengeId: challenge.id, code: userCode
     })
     ```

---

## High Findings (P1 - Fix Soon)

### [VULN-004] Hardcoded Google OAuth Client IDs in Source Code

- **Risk**: High
- **Location**: `fitgame/lib/core/services/supabase_service.dart:89-91`
- **Description**: Google OAuth Client IDs are hardcoded directly in the Dart source code:
  ```dart
  const iosClientId = '241707453312-24n1s72q44oughb28s7fjhiaehgop7ss.apps.googleusercontent.com';
  const webClientId = '241707453312-bcdt4drl7bi0t10pga3g83f9bp123384.apps.googleusercontent.com';
  ```
  The iOS Client ID is also present in `fitgame/ios/Runner/Info.plist:32` as a URL scheme.
- **Impact**: While OAuth Client IDs are not as sensitive as client secrets, exposing them in source code allows attackers to:
  - Impersonate the application in OAuth flows
  - Attempt OAuth phishing attacks using the legitimate client ID
  - Makes credential rotation harder (requires code changes + deployment)
- **Remediation**: Move these to environment variables or a config file excluded from version control:
  ```dart
  final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID']!;
  final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']!;
  ```

### [VULN-005] Coach Web Login Page Has Hardcoded Default Credentials

- **Risk**: High
- **Location**: `coach-web/src/pages/auth/login-page.tsx:22-23`
- **Description**: The login form is pre-filled with real credentials:
  ```typescript
  const [email, setEmail] = useState('coach@fitgame.app')
  const [password, setPassword] = useState('password')
  ```
  These are actual credentials that work against the production Supabase instance, not demo/test values.
- **Impact**: Anyone who inspects the source code of the coach web portal (which is client-side and fully visible) can immediately log in as a coach. If this is a real account, it gives full access to the coach dashboard.
- **Remediation**:
  ```typescript
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  ```

### [VULN-006] Student Account Creation Uses Weak Random Password

- **Risk**: High
- **Location**: `coach-web/src/store/students-store.ts:163`
- **Description**: When a coach adds a new student, a temporary password is generated using `Math.random()`:
  ```typescript
  const tempPassword = Math.random().toString(36).slice(-12)
  ```
  - `Math.random()` is not cryptographically secure
  - The password is generated but never communicated to the student
  - The student has no way to know their password or reset it
  - No password change is forced on first login
- **Impact**: Students created this way have accounts with weak, unknown passwords. They cannot log in. The coach uses `supabase.auth.signUp()` from the client with the anon key, which creates a real auth account - but the coach's own session may be overridden depending on Supabase client config.
- **Remediation**:
  1. Use Supabase invite/magic link flow instead of creating passwords:
     ```typescript
     const { data } = await supabase.auth.admin.inviteUserByEmail(email)
     ```
  2. Or use an Edge Function with the service role key to create users server-side and send invite emails.

### [VULN-007] `handle_new_user` Database Function Has Mutable Search Path

- **Risk**: High
- **Location**: Supabase function `public.handle_new_user`
- **Description**: The Supabase security linter flagged that this function does not set a fixed `search_path`. The function inserts into `public.profiles` whenever a new user signs up.
  ```sql
  -- Current: no search_path set (proconfig is null)
  BEGIN
    INSERT INTO public.profiles (id, email, full_name, role, ...)
    VALUES (NEW.id, NEW.email, ...);
    RETURN NEW;
  END;
  ```
- **Impact**: A malicious user could potentially exploit search path manipulation to redirect the function's table references to a different schema, though this requires schema creation privileges. This is a defense-in-depth concern.
- **Remediation**:
  ```sql
  ALTER FUNCTION public.handle_new_user() SET search_path = public, auth;
  ```
  See: https://supabase.com/docs/guides/database/database-linter?lint=0011_function_search_path_mutable

### [VULN-008] Leaked Password Protection is Disabled

- **Risk**: High
- **Location**: Supabase Auth configuration
- **Description**: The Supabase security advisor reports that leaked password protection (integration with HaveIBeenPwned.org) is disabled. Users can sign up with passwords that are known to be compromised in data breaches.
- **Impact**: Users may use passwords that are already in attacker dictionaries, making brute-force and credential stuffing attacks much more likely to succeed.
- **Remediation**: Enable leaked password protection in the Supabase dashboard:
  - Go to Authentication > Settings > Password Security
  - Enable "Reject leaked passwords"
  - See: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

---

## Medium Findings (P2)

### [VULN-009] No DELETE Policy on `community_foods` - Data Can Never Be Removed

- **Risk**: Medium
- **Location**: Supabase RLS policies on `public.community_foods`
- **Description**: The `community_foods` table has SELECT (anyone), INSERT (authenticated), and UPDATE (own) policies, but **no DELETE policy**. Once a community food is created, it can never be deleted by anyone - not even the contributor.
- **Impact**: Malicious users can pollute the community food database with fake or offensive entries that cannot be cleaned up without direct database access. This is a data integrity and moderation issue.
- **Remediation**:
  ```sql
  CREATE POLICY "Contributors can delete own community foods"
    ON public.community_foods FOR DELETE
    USING (auth.uid() = contributed_by);
  ```

### [VULN-010] Profiles Table Missing INSERT Policy - Relies on Database Trigger

- **Risk**: Medium
- **Location**: Supabase RLS policies on `public.profiles`
- **Description**: The `profiles` table has SELECT (own + coach's students) and UPDATE (own) policies, but **no INSERT policy**. New profiles are created by:
  1. The `handle_new_user()` trigger (runs as SECURITY DEFINER, bypasses RLS)
  2. Client-side code in `supabase_service.dart` and `auth-store.ts` that manually inserts profiles after signup
  The manual client-side insert will fail silently due to RLS (no INSERT policy), and relies entirely on the trigger.
- **Impact**: If the trigger fails or is not configured correctly, users will be created in `auth.users` but have no corresponding `profiles` entry. The client-side fallback insert (e.g., in `signUp()` at `supabase_service.dart:64`) will be blocked by RLS. This creates a potential authentication-profile mismatch.
- **Remediation**: Either:
  1. Add an INSERT policy: `WITH CHECK (auth.uid() = id)` - users can only create their own profile.
  2. Or ensure all profile creation goes through the trigger and remove client-side INSERT calls.

### [VULN-011] No Rate Limiting on Community Food Contributions

- **Risk**: Medium
- **Location**: `public.community_foods` INSERT policy + `supabase_service.dart:920-943`
- **Description**: Any authenticated user can insert unlimited community foods. There is no rate limiting, no spam prevention, no moderation queue. The `verified` field defaults to `false` but unverified foods are still visible to all users.
- **Impact**: A malicious user could:
  - Flood the database with fake food entries
  - Insert offensive content in food names
  - Insert malicious URLs in `image_url`
- **Remediation**:
  1. Add server-side rate limiting via an Edge Function
  2. Filter unverified foods from default queries
  3. Add a moderation queue for new contributions

### [VULN-012] Auth Token Persisted in localStorage (Coach Web)

- **Risk**: Medium
- **Location**: `coach-web/src/store/auth-store.ts:224-230` (Zustand persist middleware)
- **Description**: The auth store uses Zustand's `persist` middleware with `localStorage`, which stores the access token, coach profile, and authentication state. The persist key is `fitgame-coach-auth`.
- **Impact**: `localStorage` is vulnerable to XSS attacks. If any XSS vulnerability exists (or is introduced via a third-party dependency), the attacker can steal the session token. While Supabase handles its own token storage, the additional persistence in Zustand doubles the attack surface.
- **Remediation**:
  1. Remove `token` from the persisted state - rely on Supabase's own session management instead.
  2. The `partialize` function already selects specific fields, but `token` should be excluded:
     ```typescript
     partialize: (state) => ({
       coach: state.coach,
       isAuthenticated: state.isAuthenticated,
       // Remove: token: state.token,
     }),
     ```

### [VULN-013] No Input Sanitization on `searchCommunityFoods` (Potential SQL-like Injection)

- **Risk**: Medium
- **Location**: `fitgame/lib/core/services/supabase_service.dart:913`
- **Description**: The community food search uses `.ilike('name', '%$query%')` where `$query` is directly interpolated from user input. While Supabase's PostgREST API parameterizes queries (preventing classic SQL injection), the `%` characters in the ILIKE pattern combined with user-supplied `%` or `_` wildcards could cause unexpected pattern matching (e.g., searching for `%` returns all entries).
- **Impact**: Low risk of SQL injection (mitigated by PostgREST), but users can craft search queries that return excessive results or behave unexpectedly.
- **Remediation**: Sanitize the query string before using it in ILIKE:
  ```dart
  final sanitized = query.replaceAll('%', '\\%').replaceAll('_', '\\_');
  .ilike('name', '%$sanitized%')
  ```

### [VULN-014] Coach Web Missing `.env` in `.gitignore`

- **Risk**: Medium
- **Location**: `coach-web/.gitignore` (does NOT include `.env` pattern)
- **Description**: The root `.gitignore` includes `*.env` and `*.env.*`, but the `coach-web/.gitignore` does not include any `.env` pattern. While `coach-web/.env` is currently not tracked (confirmed by `git log` showing no commits of .env files), any nested `.gitignore` override could cause accidental commits.
- **Impact**: Risk of accidentally committing the `.env` file containing the Supabase anon key if the root `.gitignore` is modified or if Git's ignore behavior changes with nested directories.
- **Remediation**: Add `.env*` to `coach-web/.gitignore`:
  ```
  # Secrets
  .env
  .env.*
  .env.local
  ```

### [VULN-015] Password Change in Settings Page is Not Implemented

- **Risk**: Medium
- **Location**: `coach-web/src/pages/settings/settings-page.tsx:146-165`
- **Description**: The `handleChangePassword` function validates the new password client-side (length >= 8, confirm match) but then simply:
  ```typescript
  // In real app, would call API to change password
  setIsChangingPassword(false)
  setPasswordChanged(true)
  ```
  It never calls `supabase.auth.updateUser({ password: newPassword })`. The UI shows success but the password is not actually changed.
- **Impact**: Users who attempt to change their password believe they have done so but their old password remains active. This is particularly dangerous after a suspected compromise.
- **Remediation**:
  ```typescript
  const { error } = await supabase.auth.updateUser({ password: passwordForm.new })
  if (error) throw error
  ```

---

## Low Findings (P3)

### [VULN-016] Excessive Debug Logging in Production Code

- **Risk**: Low
- **Location**: Multiple files in `fitgame/lib/` (30+ instances)
- **Description**: `debugPrint()` and `print()` statements are used throughout the production code, including in `supabase_service.dart`, `health_service.dart`, `nutrition_screen.dart`, and `nutrition_scanner_sheet.dart`. Notable examples:
  - `health_service.dart:79`: Prints health authorization errors
  - `nutrition_scanner_sheet.dart:186`: Prints raw OCR text
  - `supabase_service.dart:545-1261`: Prints various API error details
- **Impact**: In debug/development builds, this data appears in system logs which could leak sensitive information (user IDs, error messages, OCR data). In release builds, `debugPrint` is stripped but `print()` is not.
- **Remediation**:
  1. Replace all `print()` calls with `debugPrint()` (stripped in release mode)
  2. Or use a proper logging framework with log levels (e.g., `logger` package)

### [VULN-017] No Certificate Pinning on Mobile App

- **Risk**: Low
- **Location**: `fitgame/lib/core/services/supabase_service.dart` (absence)
- **Description**: The Flutter app does not implement SSL certificate pinning. All HTTPS connections trust the system certificate store.
- **Impact**: Susceptible to man-in-the-middle attacks if an attacker can install a rogue CA certificate on the device (common in corporate environments or with physical device access).
- **Remediation**: Consider implementing certificate pinning for the Supabase API domain using a package like `http_certificate_pinning` or custom `HttpOverrides`.

### [VULN-018] No `flutter_secure_storage` Usage for Sensitive Data

- **Risk**: Low
- **Location**: `fitgame/` (absence - no references to `flutter_secure_storage`)
- **Description**: The app does not use `flutter_secure_storage` or any secure storage mechanism. Supabase Flutter SDK uses `shared_preferences` by default for token storage, which is stored in plaintext on the device (UserDefaults on iOS, SharedPreferences on Android).
- **Impact**: On rooted/jailbroken devices, the Supabase session token could be extracted from plaintext storage.
- **Remediation**: Configure Supabase to use secure storage:
  ```dart
  await Supabase.initialize(
    url: ...,
    anonKey: ...,
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureLocalStorage(), // Custom implementation using flutter_secure_storage
    ),
  );
  ```

### [VULN-019] Supabase Integration Test Has Hardcoded URL

- **Risk**: Low
- **Location**: `coach-web/src/__tests__/integration/api/supabase-integration.test.ts:28`
- **Description**: The Supabase project URL is hardcoded in the integration test file:
  ```typescript
  const SUPABASE_URL = 'https://snqeueklxfdwxfrrpdvl.supabase.co'
  ```
  While the anon key is loaded from environment variables, the URL is static.
- **Impact**: Minor information disclosure. The URL reveals the project reference ID and confirms the Supabase region.
- **Remediation**: Load from environment variable:
  ```typescript
  const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL || process.env.VITE_SUPABASE_URL
  ```

### [VULN-020] Friendships UPDATE Policy Allows Status Manipulation

- **Risk**: Low
- **Location**: Supabase RLS policy `"Users can update their own friendships"` on `public.friendships`
- **Description**: The UPDATE policy allows both `user_id` (requester) and `friend_id` (recipient) to update any column on the friendship row:
  ```sql
  USING ((auth.uid() = user_id) OR (auth.uid() = friend_id))
  ```
  There is no `WITH CHECK` clause to restrict which columns can be updated.
- **Impact**: The requester can change the status from `pending` to `accepted` themselves (self-accepting friend requests), bypass the intended accept flow, or set status to `blocked` for a friend request they sent.
- **Remediation**: Add a WITH CHECK that restricts updates:
  ```sql
  -- Only the friend_id (recipient) can accept/reject
  CREATE POLICY "Recipients can accept friend requests"
    ON public.friendships FOR UPDATE
    USING (auth.uid() = friend_id)
    WITH CHECK (status IN ('accepted', 'blocked'));
  ```

---

## Supabase RLS Audit

### Table-by-Table Analysis

| Table | RLS Enabled | Policies | Assessment |
|-------|------------|----------|------------|
| `profiles` | Yes | SELECT (own + coach), UPDATE (own) | **WARN**: No INSERT policy, no DELETE policy. INSERT relies on trigger. |
| `coaches` | Yes | ALL (own) | OK - properly scoped to own ID. |
| `programs` | Yes | ALL (own), SELECT (assigned students) | OK - good multi-role access. |
| `workout_sessions` | Yes | ALL (own), SELECT (coach of user) | OK - properly scoped. |
| `diet_plans` | Yes | ALL (own), SELECT (assigned students) | OK - good multi-role access. |
| `assignments` | Yes | ALL (coach), SELECT (student) | OK - properly scoped. |
| `messages` | Yes | INSERT (coach-student only), SELECT (sender/receiver), UPDATE (receiver for read_at) | OK - good bidirectional restriction. |
| `friendships` | Yes | SELECT/DELETE (both parties), INSERT (requester), UPDATE (both) | **WARN**: UPDATE too broad (VULN-020). |
| `activity_feed` | Yes | INSERT (own), SELECT (own + friends) | OK - properly uses friendship join. |
| `notifications` | Yes | SELECT/UPDATE (own), INSERT (anyone) | **CRITICAL**: INSERT allows any user (VULN-002). |
| `community_foods` | Yes | SELECT (public), INSERT (authenticated), UPDATE (own) | **WARN**: No DELETE policy (VULN-009). |
| `daily_nutrition_logs` | Yes | Full CRUD (own) | OK - properly scoped. |
| `user_favorite_foods` | Yes | Full CRUD (own) | OK - properly scoped. |
| `meal_templates` | Yes | Full CRUD (own) | OK - properly scoped. |
| `day_types` | Yes | Full CRUD (via diet_plan ownership join) | OK - properly scoped via parent. |
| `weekly_schedule` | Yes | Full CRUD (via diet_plan ownership join) | OK - properly scoped via parent. |

### Summary
- **16/16** public tables have RLS enabled
- **13/16** have adequate policies
- **3/16** have policy issues (notifications CRITICAL, profiles WARN, community_foods WARN, friendships WARN)
- No `challenges` table exists in the database, but the Dart code references it - queries will simply fail silently

---

## Action Plan

| Priority | Finding | Effort | Recommendation |
|----------|---------|--------|----------------|
| P0 | VULN-001: Anon key in Git | Low | Remove from BACKEND_PLAN.md, scrub Git history |
| P0 | VULN-002: Notifications INSERT bypass | Low | Replace policy with service_role restriction |
| P0 | VULN-003: Fake 2FA | Medium | Remove UI or implement real Supabase MFA |
| P1 | VULN-004: Hardcoded OAuth client IDs | Low | Move to .env |
| P1 | VULN-005: Default credentials in login | Low | Empty default state |
| P1 | VULN-006: Weak student password creation | Medium | Use invite flow or Edge Function |
| P1 | VULN-007: Mutable search path | Low | ALTER FUNCTION SET search_path |
| P1 | VULN-008: Leaked password protection off | Low | Enable in Supabase dashboard |
| P2 | VULN-009: No DELETE on community_foods | Low | Add DELETE policy |
| P2 | VULN-010: No INSERT on profiles | Low | Add INSERT policy or rely on trigger |
| P2 | VULN-011: No rate limiting on foods | Medium | Add Edge Function or rate limit |
| P2 | VULN-012: Token in localStorage | Low | Remove token from persist |
| P2 | VULN-013: ILIKE wildcard injection | Low | Sanitize search input |
| P2 | VULN-014: Missing .env in coach-web gitignore | Low | Add .env to gitignore |
| P2 | VULN-015: Fake password change | Low | Call supabase.auth.updateUser |
| P3 | VULN-016: Debug logging | Low | Replace print with debugPrint |
| P3 | VULN-017: No cert pinning | Medium | Implement if high-security needed |
| P3 | VULN-018: No secure storage | Medium | Use flutter_secure_storage |
| P3 | VULN-019: Hardcoded test URL | Low | Use env variable |
| P3 | VULN-020: Friendship update too broad | Low | Restrict UPDATE policy |

---

## Security Checklist

- [x] All public tables have RLS enabled (16/16)
- [ ] All RLS policies are properly scoped (3 tables have issues)
- [x] Supabase credentials loaded from .env files (not hardcoded in app code)
- [ ] No secrets in version control (anon key in BACKEND_PLAN.md)
- [x] Auth required on all protected routes (AppShell checks isAuthenticated)
- [ ] 2FA properly implemented (currently fake/mock)
- [x] No dangerouslySetInnerHTML / innerHTML usage (no XSS via direct HTML)
- [ ] Leaked password protection enabled
- [ ] Certificate pinning implemented
- [ ] Secure storage for tokens on mobile
- [x] .env files in root .gitignore
- [ ] .env files in all sub-project .gitignores
- [ ] Rate limiting on user-generated content
- [x] Email validation on signup
- [x] Password minimum length enforced (6 chars Flutter, 8 chars coach web)
- [ ] Password change actually implemented
- [ ] Default credentials removed from login form
- [x] OAuth client IDs use environment variables (partially - only Supabase URL/key, not Google IDs)
- [x] No SQL injection vectors (PostgREST parameterizes queries)
- [x] No excessive mobile permissions (only HealthKit on iOS, minimal Android)
- [ ] Debug logging removed from production code
- [x] Proper auth state management (onAuthStateChange listener)

---

## Additional Notes

1. **No Edge Functions deployed**: The project has no Edge Functions, meaning all business logic runs client-side. This increases attack surface since clients have direct database access via the anon key + RLS.

2. **`challenges` table referenced but does not exist**: The `supabase_service.dart` file references a `challenges` table (lines 1248-1398) but this table does not exist in the database. Queries will fail silently due to the try/catch. This is a functionality bug, not a security issue.

3. **No CORS configuration visible**: Since Supabase handles CORS configuration via its dashboard, this was not directly auditable. Verify that CORS is restricted to your specific domains.

4. **No Content Security Policy (CSP)**: The coach web portal (Vite/React) does not appear to have CSP headers configured. Consider adding them via Vite config or a meta tag.

5. **Race condition in use_count increment**: `incrementCommunityFoodUseCount` and `updateFavoriteFoodUsage` use a read-then-write pattern that is susceptible to race conditions. Consider using a Postgres function with `UPDATE ... SET use_count = use_count + 1`.
