# React/Coach Web Code Quality Audit - FitGame2
Date: 2026-02-06

## Executive Summary
- **Files Reviewed**: ~45 (8 stores, 13 pages, 9 modals, 5 UI components, 5 lib files, 18 tests, configs)
- **Critical Issues**: 3
- **High Priority Issues**: 6
- **Medium Priority Issues**: 8
- **Low Priority / Suggestions**: 7
- **Code Health Score: 6.5/10**

The coach-web portal demonstrates solid foundational choices (React 19, Zustand, Supabase, Tailwind v4, Vite 7) and a clean project structure. The TypeScript configuration is strict. The test suite, while present, is well-structured for what it covers. However, several critical issues undermine reliability: excessive `any` usage in stores (45 occurrences), the `goalConfig` constant is duplicated in 5 files despite an existing centralized version, there are no error boundaries, no lazy loading, zero `useMemo`/`useCallback` usage, TanStack React Query is installed but never used, and the events store still runs on mock data. The login page ships with hardcoded credentials. Pages are very large (student-profile: 1047 lines, nutrition-create: 1317 lines) and could benefit from decomposition.

---

## Architecture Assessment

### Tech Stack (Good Choices)
| Category | Technology | Version | Assessment |
|----------|-----------|---------|------------|
| Framework | React | 19.2.0 | Current, good |
| Build | Vite | 7.2.4 | Latest, fast |
| Routing | React Router | 7.13.0 | v7, good |
| State | Zustand | 5.0.10 | Lightweight, appropriate |
| Data Fetching | TanStack React Query | 5.90.20 | **Installed but NEVER used** |
| Styling | Tailwind CSS | 4.1.18 | v4, modern |
| Auth/DB | Supabase | 2.93.3 | Good |
| Testing | Vitest + RTL | 3.2.3 | Good pairing |

### Structure (Good)
The project follows a clear `features/pages/components/store` separation. Naming conventions are consistent (kebab-case files, PascalCase components). Path aliases (`@/`) are properly configured in both `tsconfig.app.json` and `vite.config.ts`.

### Data Flow Pattern
```
Pages -> Zustand Stores -> Supabase
                        <- Supabase (realtime for messages)
```

All data fetching happens inside Zustand stores. `AppShell` acts as the auth guard and data initializer, loading all stores on mount via `Promise.all`. This is a reasonable pattern for a small-to-mid-size app.

---

## Critical Issues (Must Fix)

### [QR-001] Hardcoded Login Credentials in Production Code
- **File**: `/Users/mike/projects/FitGame2/coach-web/src/pages/auth/login-page.tsx:22-23`
- **Description**: The login form initializes with hardcoded demo credentials:
  ```tsx
  const [email, setEmail] = useState('coach@fitgame.app')
  const [password, setPassword] = useState('password')
  ```
- **Impact**: Security risk. Even if this is a demo, these values will ship in the production bundle and can be seen in React DevTools. Users may unknowingly submit these credentials.
- **Fix**: Remove default values:
  ```tsx
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  ```

### [QR-002] Excessive `any` Type Usage in Stores (45 occurrences)
- **Files**:
  - `/Users/mike/projects/FitGame2/coach-web/src/store/programs-store.ts:134` - `dbToProgram(row: any)`
  - `/Users/mike/projects/FitGame2/coach-web/src/store/programs-store.ts:203,231` - `catch (error: any)`, `dbUpdates: any`
  - `/Users/mike/projects/FitGame2/coach-web/src/store/nutrition-store.ts:112` - `dbToDietPlan(row: any)`
  - `/Users/mike/projects/FitGame2/coach-web/src/store/nutrition-store.ts:187,215` - same pattern
  - `/Users/mike/projects/FitGame2/coach-web/src/store/students-store.ts:51` - `dbToStudent(profile: any, assignments: any[], workoutSessions: any[])`
  - `/Users/mike/projects/FitGame2/coach-web/src/store/stats-store.ts:169` - `exercises as any[]`
  - `/Users/mike/projects/FitGame2/coach-web/src/store/messages-store.ts:25,104,234` - multiple `any` in message handling
  - `/Users/mike/projects/FitGame2/coach-web/src/pages/students/student-profile-page.tsx:52,343,348,349` - `selectedSession: any`, `ex: any`, `s: any`
- **Description**: 45 total `any` occurrences across 12 production and test files. The `dbToX` transformation functions all accept `any`, discarding type safety at the database boundary -- the most critical place to validate types.
- **Impact**: Defeats TypeScript's purpose. Runtime errors from malformed Supabase responses will not be caught at compile time. The `exercises as any[]` cast in stats-store means any schema change in the `exercises` JSONB column will silently produce wrong data.
- **Fix**: Define Supabase row types (or use `supabase gen types typescript`) and replace `any` with proper interfaces:
  ```ts
  interface ProgramRow {
    id: string
    name: string
    description: string | null
    goal: string
    duration_weeks: number
    deload_frequency: number | null
    days: WorkoutDay[] | null
    created_at: string
    updated_at: string
    created_by: string
  }

  function dbToProgram(row: ProgramRow): Program { ... }
  ```
  For `catch` blocks, use `catch (error: unknown)` and narrow with `error instanceof Error`.

### [QR-003] TanStack React Query Installed but Never Used
- **File**: `/Users/mike/projects/FitGame2/coach-web/package.json:16` and `/Users/mike/projects/FitGame2/coach-web/src/App.tsx:19`
- **Description**: `@tanstack/react-query` is listed as a dependency (adding ~12KB gzipped), `QueryClientProvider` wraps the app in `App.tsx`, but **zero** `useQuery`, `useMutation`, or `useInfiniteQuery` hooks are used anywhere in the codebase. All data fetching is done imperatively in Zustand stores.
- **Impact**: Unnecessary bundle size. The `QueryClient` is instantiated but never serves a purpose. This also means the app misses out on React Query's caching, deduplication, background refresh, and error/loading state management.
- **Fix**: Either:
  1. Remove the dependency and `QueryClientProvider` wrapper (simpler), or
  2. Migrate store fetching logic to React Query hooks (better long-term but bigger effort)

---

## High Priority Issues

### [QR-004] No Error Boundaries
- **Files**: All page components
- **Description**: No `ErrorBoundary` component exists anywhere in the codebase. If any page component throws during rendering (e.g., accessing a property on `null`), the entire app crashes to a blank white screen.
- **Impact**: Terrible user experience on any runtime error. The user loses all context and must reload the app.
- **Fix**: Create an `ErrorBoundary` component and wrap at least:
  1. The `<Outlet />` in `AppShell` (catches page-level errors)
  2. Individual complex pages like `StudentProfilePage`

### [QR-005] `goalConfig` Duplicated in 5 Files Despite Centralized Version
- **Files**:
  - `/Users/mike/projects/FitGame2/coach-web/src/constants/goals.ts` (centralized version)
  - `/Users/mike/projects/FitGame2/coach-web/src/pages/students/students-list-page.tsx:25` (local copy)
  - `/Users/mike/projects/FitGame2/coach-web/src/pages/programs/programs-list-page.tsx:26` (local copy)
  - `/Users/mike/projects/FitGame2/coach-web/src/pages/nutrition/nutrition-list-page.tsx:26` (local copy)
  - `/Users/mike/projects/FitGame2/coach-web/src/components/modals/assign-program-modal.tsx:16` (local copy)
  - `/Users/mike/projects/FitGame2/coach-web/src/components/modals/assign-diet-modal.tsx:16` (local copy)
- **Description**: A centralized `goalConfig` exists in `constants/goals.ts` and is used by `student-profile-page`, `program-detail-page`, `nutrition-detail-page`, and the create pages. But 5 other files define their own local `goalConfig` with slightly different shapes (missing `desc`, `icon` fields, different `label` values like "Masse" vs "Prise de masse").
- **Impact**: Inconsistent labels across the UI. A label change requires updating 6 files. High risk of drift.
- **Fix**: Delete all local `goalConfig` definitions and import from `@/constants/goals`.

### [QR-006] Events Store Uses Only Mock Data (No Supabase)
- **File**: `/Users/mike/projects/FitGame2/coach-web/src/store/events-store.ts`
- **Description**: The entire events store operates on hardcoded `mockEvents` with IDs like `'student-1'`, `'student-2'`. It has no Supabase integration, no `fetchEvents` method, and no persistence. Calendar events created by the user are lost on page reload.
- **Impact**: The Calendar feature is non-functional in production. Data does not persist and references non-existent student IDs.
- **Fix**: Implement Supabase integration following the same pattern as `programs-store` and `nutrition-store`.

### [QR-007] Hardcoded Badge Count in Sidebar
- **File**: `/Users/mike/projects/FitGame2/coach-web/src/components/layout/sidebar.tsx:22`
- **Description**: The Messages nav item has a hardcoded `badge: 3`:
  ```tsx
  { path: '/messages', icon: MessageSquare, label: 'Messages', badge: 3 },
  ```
  The store has a `getTotalUnread()` method that computes the real count, but the sidebar does not use it.
- **Impact**: Users always see "3" unread messages regardless of actual state. Misleading UI.
- **Fix**: Make the sidebar consume `useMessagesStore().getTotalUnread()` and pass it dynamically.

### [QR-008] No Lazy Loading for Routes
- **Files**: `/Users/mike/projects/FitGame2/coach-web/src/App.tsx`
- **Description**: All 13 pages are eagerly imported at the top of `App.tsx`. No `React.lazy()` or dynamic `import()` is used anywhere.
- **Impact**: The entire app bundle is downloaded upfront, including large pages like `NutritionCreatePage` (1317 lines) and `ProgramCreatePage` (1019 lines) that many users may never visit.
- **Fix**: Use `React.lazy` for non-critical routes:
  ```tsx
  const NutritionCreatePage = lazy(() => import('@/pages/nutrition/nutrition-create-page'))
  ```

### [QR-009] `Forgot Password` Modal Simulates API Call
- **File**: `/Users/mike/projects/FitGame2/coach-web/src/components/modals/forgot-password-modal.tsx:22`
- **Description**: The forgot password flow uses `setTimeout` instead of calling `supabase.auth.resetPasswordForEmail()`:
  ```tsx
  // Simulate API call
  await new Promise(resolve => setTimeout(resolve, 1000))
  // Always succeed for demo
  ```
- **Impact**: Password reset does not work at all. Users who forget their password are stuck.
- **Fix**: Replace with actual Supabase call:
  ```tsx
  const { error } = await supabase.auth.resetPasswordForEmail(email)
  if (error) { setError(error.message); return }
  ```

---

## Medium Priority Issues

### [QR-010] Massive Page Components (1000+ lines)
- **Files**:
  - `/Users/mike/projects/FitGame2/coach-web/src/pages/nutrition/nutrition-create-page.tsx` - **1317 lines**
  - `/Users/mike/projects/FitGame2/coach-web/src/pages/students/student-profile-page.tsx` - **1047 lines**
  - `/Users/mike/projects/FitGame2/coach-web/src/pages/programs/program-create-page.tsx` - **1019 lines**
- **Description**: These files contain all tab content, inline forms, mock data arrays, helper functions, and sub-components in a single file. `StudentProfilePage` has 5 tab panels, a delete confirmation dialog, 4 modals, and mock health data all inline.
- **Impact**: Hard to navigate, test, and maintain. Changes to one tab risk breaking another. Very hard to code review.
- **Fix**: Extract tab content into separate components (e.g., `StudentOverviewTab`, `StudentWorkoutsTab`), move mock data to a separate file or fetch from API, extract confirmation dialogs into a shared component.

### [QR-011] Zero `useMemo`/`useCallback` Usage
- **Files**: All page and component files
- **Description**: Not a single `useMemo`, `useCallback`, or `React.memo` is used in the entire codebase. Expensive computations like filtering/sorting students, calculating stats, and creating derived arrays are recalculated on every render.
- **Impact**: In `DashboardPage`, `alertStudents`, `recentActivity`, and `topPerformers` are recomputed on every render cycle. For a handful of students this is fine, but it will degrade with scale.
- **Fix**: Memoize expensive derived data:
  ```tsx
  const alertStudents = useMemo(() =>
    students.filter(s => s.stats.complianceRate < 70 || s.stats.thisWeekWorkouts < 2),
    [students]
  )
  ```

### [QR-012] Delete Confirmation Dialog Duplicated 4 Times
- **Files**:
  - `/Users/mike/projects/FitGame2/coach-web/src/pages/students/student-profile-page.tsx:995-1044`
  - `/Users/mike/projects/FitGame2/coach-web/src/pages/programs/programs-list-page.tsx:420-469`
  - `/Users/mike/projects/FitGame2/coach-web/src/pages/programs/program-detail-page.tsx:445-497`
  - `/Users/mike/projects/FitGame2/coach-web/src/pages/nutrition/nutrition-list-page.tsx:419-468`
- **Description**: The same delete confirmation modal pattern (backdrop + card + Trash icon + title + description + Cancel/Delete buttons) is copy-pasted in 4 files with near-identical markup.
- **Impact**: UI inconsistency risk, maintenance burden.
- **Fix**: Create a shared `ConfirmDeleteModal` component.

### [QR-013] Context Menu (Dropdown) Pattern Duplicated Without Shared Component
- **Files**: `programs-list-page.tsx`, `nutrition-list-page.tsx`, `program-detail-page.tsx`, `student-profile-page.tsx`
- **Description**: Each file implements its own dropdown menu with `useState` for open/close, `useEffect` + `useRef` for click-outside detection, and identical markup patterns. None uses a shared `Dropdown` or `Popover` component.
- **Impact**: Inconsistent close behavior (some use `useRef` with `mousedown`, some don't). Repeated boilerplate.
- **Fix**: Create a reusable `DropdownMenu` component.

### [QR-014] `addStudent` Creates Auth Account with Random Password
- **File**: `/Users/mike/projects/FitGame2/coach-web/src/store/students-store.ts:163`
- **Description**: When a coach adds a student, the code calls `supabase.auth.signUp()` with a random password:
  ```tsx
  const tempPassword = Math.random().toString(36).slice(-12)
  ```
  This creates an actual Supabase auth account. The comment says "In production, you'd send an invite email instead" but this is the production code.
- **Impact**: Security concern. The randomly-generated password is discarded and never communicated to the student. The student has no way to log in. If this signs in the coach's session as the new user, it could log the coach out.
- **Fix**: Use `supabase.auth.admin.inviteUserByEmail()` or implement a proper invite flow.

### [QR-015] `useEffect` Cleanup May Unsubscribe Too Early
- **File**: `/Users/mike/projects/FitGame2/coach-web/src/components/layout/app-shell.tsx:49-53`
- **Description**: The cleanup function for realtime unsubscription runs when any dependency in the dep array changes, not just on unmount. The dep array includes 8 stable function references, which Zustand provides as stable -- but if any store is recreated (e.g., in dev with HMR), the cleanup would fire and unsubscribe.
- **Impact**: Potential realtime message subscription drops during development.
- **Fix**: Use a separate `useEffect` for cleanup with an empty dep array, or move subscription logic into the store itself.

### [QR-016] `calculateMealMacros` Has Incorrect Multiplier Assumption
- **File**: `/Users/mike/projects/FitGame2/coach-web/src/store/nutrition-store.ts:97-98`
- **Description**: The multiplier assumes all foods are per 100g:
  ```tsx
  const multiplier = food.quantity / 100
  ```
  But the food catalog has items like `'Whey protein'` with `unit: '30g'`, meaning the calorie/macro values are already per 30g serving. A multiplier of `quantity / 100` would be wrong for these items.
- **Impact**: Incorrect calorie/macro calculations for non-100g-based foods.
- **Fix**: Either normalize all catalog entries to per-100g values, or use unit-aware calculation.

### [QR-017] NaN Potential in `students-list-page.tsx`
- **File**: `/Users/mike/projects/FitGame2/coach-web/src/pages/students/students-list-page.tsx:54-56`
- **Description**:
  ```tsx
  const avgCompliance = Math.round(
    students.reduce((acc, s) => acc + s.stats.complianceRate, 0) / students.length
  )
  ```
  When `students.length === 0`, this divides by zero, producing `NaN`.
- **Impact**: Displays "NaN%" in the stats card when no students exist.
- **Fix**: Add a guard: `students.length > 0 ? Math.round(...) : 0`

---

## Low Priority / Suggestions

### [QR-018] Missing Accessibility Attributes
- **Files**: All pages and modals
- **Description**: Only 9 `aria-*` attributes exist across all `.tsx` files, all in test files. No production component uses `aria-label`, `aria-describedby`, `role="dialog"`, or `aria-modal="true"`. Modals don't trap focus. The sidebar nav doesn't use `role="navigation"` or `aria-current="page"`.
- **Impact**: Screen reader users cannot navigate the app effectively. Keyboard navigation in modals is broken (focus can escape to background content).

### [QR-019] No Loading/Skeleton States on Individual Pages
- **Files**: Page components
- **Description**: `AppShell` shows a full-screen loader while all stores load, but individual page navigations (e.g., going from students list to student profile) have no loading indicators for data that might still be fetching (e.g., workout sessions).
- **Impact**: Pages may flash empty content before data arrives.

### [QR-020] `generateId()` Uses Weak Randomness
- **File**: `/Users/mike/projects/FitGame2/coach-web/src/lib/utils.ts:38-40`
- **Description**:
  ```tsx
  export function generateId(): string {
    return Math.random().toString(36).substring(2, 9)
  }
  ```
  `Math.random()` is not cryptographically secure and produces only 7 characters (~36 bits of entropy). Collision probability increases with usage.
- **Impact**: Potential ID collisions in client-generated IDs for sets, exercises, and days within programs.
- **Fix**: Use `crypto.randomUUID()` (supported in all modern browsers).

### [QR-021] Inline Styles and Magic Numbers
- **Files**: Multiple pages
- **Description**: Animation delays use inline `style={{ animationDelay: '${index * 50}ms' }}` patterns. Magic numbers like `500` (limit for Supabase queries), `85` (hardcoded compliance rate), `5000` (notification timeout) are scattered without constants.
- **Impact**: Hard to maintain, no single source of truth.

### [QR-022] Mock/Hardcoded Data in Production Pages
- **Files**:
  - `/Users/mike/projects/FitGame2/coach-web/src/pages/students/student-profile-page.tsx:84-90` - `weeklyProgress`, `mockHealthData`
  - `/Users/mike/projects/FitGame2/coach-web/src/pages/students/student-profile-page.tsx:551-554` - Hardcoded "3/5 jours", "4h 12min"
  - `/Users/mike/projects/FitGame2/coach-web/src/store/students-store.ts:82` - `complianceRate: 85 // TODO`
- **Impact**: Misleading data displayed to coaches.

### [QR-023] `duplicateProgram` and `duplicateDietPlan` Don't Await Return
- **Files**: `/Users/mike/projects/FitGame2/coach-web/src/pages/programs/programs-list-page.tsx:64-67`
- **Description**: `duplicateProgram()` returns a `Promise<string | null>` but the call site doesn't `await` it:
  ```tsx
  const handleDuplicate = (programId: string) => {
    setOpenMenuId(null)
    const newId = duplicateProgram(programId) // Promise, not string!
    if (newId) {
      navigate(`/programs/${newId}`) // navigates to "[object Promise]"
    }
  }
  ```
- **Impact**: After duplicating, the user is navigated to `/programs/[object Promise]`, which shows the "Not Found" redirect.
- **Fix**: `const newId = await duplicateProgram(programId)` and make `handleDuplicate` async.

### [QR-024] `programToDb` Return Type Not Explicit
- **File**: `/Users/mike/projects/FitGame2/coach-web/src/store/programs-store.ts:150`
- **Description**: The `programToDb` function has no return type annotation. Combined with the `any` parameter issue, the full transformation chain is untyped.

---

## Store Analysis

| Store | Lines | Supabase | Persist | Error Handling | Notes |
|-------|-------|----------|---------|----------------|-------|
| `auth-store` | 243 | Yes | Yes (localStorage) | Good | Proper role checks, auth state change listener |
| `programs-store` | 372 | Yes | No | Partial (catches, logs) | `any` in db transforms, good assignment logic |
| `nutrition-store` | 361 | Yes | No | Partial | Mirror of programs-store pattern |
| `students-store` | 404 | Yes | No | Partial | Creates auth accounts (security concern) |
| `messages-store` | 306 | Yes + Realtime | No | Good | Well-implemented realtime subscription |
| `events-store` | 107 | **NO - Mock only** | No | N/A | Non-functional in production |
| `settings-store` | 52 | No | Yes (localStorage) | N/A | Simple, correct |
| `stats-store` | 382 | Yes | No | Partial | Complex volume calculations, many queries |

**Common store issues:**
1. All db-facing stores use `any` for row types
2. No optimistic updates (except messages-store which does it well)
3. Error states are set but rarely displayed to users (pages don't check `store.error`)
4. Stores call `useAuthStore.getState()` imperatively -- works but creates hidden coupling

---

## Test Coverage Report

### Test Files Found: 18

| Category | Files | Coverage Quality |
|----------|-------|-----------------|
| Store tests | 5 (auth, settings, students, programs, nutrition) | Good mocking pattern, thorough scenarios |
| UI component tests | 4 (button, badge, card, input) | Good: variants, sizes, disabled, a11y, refs |
| Modal tests | 3 (forgot-password, session-detail, add-student) | Present |
| Lib tests | 3 (utils, pdf-export, notifications) | Present |
| Integration tests | 1 (supabase-integration) | Present |
| Test helpers | 1 (test-utils with custom render) | Good: wraps with providers |

### Missing Test Coverage
- **No page-level tests**: None of the 13 pages have tests
- **No routing tests**: Auth guard logic untested
- **No events-store test**: The mock-only store is untested
- **No messages-store test**: The most complex store (realtime) is untested
- **No stats-store test**: Complex calculations untested
- **6 modals untested**: edit-student, assign-program, assign-diet, create-event, edit-event, setup-2fa

### Test Quality Assessment
The existing tests are well-structured:
- Auth store test: 15 test cases covering login, signup, logout, profile update, persistence, edge cases
- UI component tests: Test variants, sizes, disabled state, accessibility, ref forwarding
- Good use of `vi.mock()`, `vi.fn()`, `beforeEach`/`afterEach` cleanup
- Chainable mock pattern for Supabase queries is clever and reusable

---

## Dependency Review

| Package | Status | Notes |
|---------|--------|-------|
| `react` 19.2.0 | OK | Latest stable |
| `react-router-dom` 7.13.0 | OK | v7 |
| `zustand` 5.0.10 | OK | Well-used |
| `@supabase/supabase-js` 2.93.3 | OK | Consider typed client |
| `@tanstack/react-query` 5.90.20 | **UNUSED** | Remove or adopt |
| `tailwind-merge` 3.4.0 | OK | Used via `cn()` |
| `clsx` 2.1.1 | OK | Used via `cn()` |
| `date-fns` 4.1.0 | Minimal use | Only `format` and `addDays` in events-store |
| `lucide-react` 0.563.0 | OK | Large icon set, tree-shakes well |
| `recharts` 3.7.0 | **Likely unused** | Not found in any imports during audit |
| `jspdf` 4.0.0 | OK | Used for PDF export |

---

## Tech Debt Summary

| Category | Count | Top Items |
|----------|-------|-----------|
| Type Safety (`any`) | 45 | Store db transforms, error catches, session mapping |
| Code Duplication | 4 | `goalConfig` (5 copies), delete dialog (4 copies), dropdown menu (4 copies), color mapping logic |
| Mock/TODO Data | 5 | events-store, health data, compliance rate, forgot password, weekly progress |
| Unused Dependencies | 2 | `@tanstack/react-query`, possibly `recharts` |
| Missing Features | 3 | Error boundaries, lazy loading, accessibility |
| Large Components | 3 | nutrition-create (1317), student-profile (1047), program-create (1019) |

---

## Action Plan (Prioritized)

| Priority | Task | Files | Effort |
|----------|------|-------|--------|
| P0 - Critical | Remove hardcoded login credentials | `login-page.tsx` | 5 min |
| P0 - Critical | Fix `duplicateProgram` not awaited (broken navigation) | `programs-list-page.tsx`, `nutrition-list-page.tsx` | 10 min |
| P0 - Critical | Implement forgot password with real Supabase call | `forgot-password-modal.tsx` | 15 min |
| P1 - High | Add Error Boundary to AppShell | New `ErrorBoundary` component + `app-shell.tsx` | 30 min |
| P1 - High | Remove `@tanstack/react-query` or adopt it | `package.json`, `App.tsx` | 15 min (remove) or 2h (adopt) |
| P1 - High | Consolidate `goalConfig` duplications | 5 page/modal files | 30 min |
| P1 - High | Fix hardcoded badge count in sidebar | `sidebar.tsx` | 10 min |
| P1 - High | Fix NaN division by zero in students list | `students-list-page.tsx` | 5 min |
| P2 - Medium | Add Supabase row types, remove `any` in stores | All 5 Supabase-facing stores | 2h |
| P2 - Medium | Implement events store with Supabase | `events-store.ts` | 1.5h |
| P2 - Medium | Extract shared ConfirmDeleteModal | New component + 4 pages | 1h |
| P2 - Medium | Extract shared DropdownMenu component | New component + 4 pages | 1h |
| P2 - Medium | Add lazy loading for routes | `App.tsx` | 30 min |
| P2 - Medium | Split large page components into sub-components | 3 pages | 3h |
| P2 - Medium | Fix `calculateMealMacros` unit assumption | `nutrition-store.ts` | 30 min |
| P3 - Low | Add `useMemo` for expensive derived data | Dashboard, lists | 1h |
| P3 - Low | Add aria attributes and focus trapping to modals | All modals | 2h |
| P3 - Low | Replace `generateId()` with `crypto.randomUUID()` | `utils.ts` | 5 min |
| P3 - Low | Remove mock data from student profile tabs | `student-profile-page.tsx` | 30 min |
| P3 - Low | Add page-level and routing tests | New test files | 4h |
| P3 - Low | Fix `addStudent` to use invite flow instead of signUp | `students-store.ts` | 1h |
| P3 - Low | Verify `recharts` usage, remove if unused | `package.json` | 10 min |
