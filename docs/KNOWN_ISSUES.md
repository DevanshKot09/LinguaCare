# Known Issues & Deferred Items (LinguaCare DLD Support App)

## Resolved (Proven by Real Script Execution & Test Harness Runs - March 2026)
1. **[RESOLVED] DB High**: Non-author observation UPDATE policy hole proven fixed by real execution of `rls_checks_obs_goals.sql` (all 22 tests passed).
2. **[RESOLVED] DB Medium**: UPDATE on `screening_sessions` / `activity_sessions` revoked and locked down; proven by `rls_checks.sql` (31 tests passed).
3. **[RESOLVED] DB Security**: SECURITY DEFINER functions secured with explicit `search_path = public`, anon execution revoked from all tables/sequences/functions, default privileges hardened; proven by database linter and advisor checks.
4. **[RESOLVED] Test Harness**: All 3 test suites (`rls_checks.sql`, `rls_checks_links.sql`, `rls_checks_obs_goals.sql`) pass 100% with manifest validation (`check_test_manifest.dart` passing).

## Remaining Risks & Unresolved Items
1. **Consents Mutability**: Authenticated users can UPDATE and DELETE consent rows (proven by tests "Consents update valid", "Consents delete allowed for owner"). Consent records should ideally be append-only for strict legal audit trails.
2. **Specialist Details Post-Verification Mutability**: The profile owner can change licence fields after verification without revoking re-verification status automatically.
3. **Concurrent Invitation Brute-Forcing / Rate Limiting Race Conditions**: While `invite_attempts` tracks and locks UIDs after 6 failed attempts, concurrent requests across database worker threads could potentially bypass attempt counts if not isolated via strict advisory locks or row locking.
4. **Edge Cases in JWT Claims Parsing**: If Supabase Auth JWT claims format changes or `auth.jwt()->>'sub'` returns empty strings or malformed UUIDs under unusual OAuth/refresh token flows, trigger derivation fallbacks could experience unhandled exceptions.
5. **Large Payload Pagination in RPCs**: `get_shared_summary` caps screening sessions at 100, activities at 500, and observations at 100. Extremely dense longitudinal data for chronic care users over multi-year spans could hit memory or payload size thresholds.
6. **Offline Sync Replay Conflicts**: Client-side offline queue replay of observations/goals or activity sessions could result in out-of-order timestamps or constraint violations if server clocks and client device clocks drift significantly.
7. **Auth / OTP Verification Double-Submit**: Prevented on client via single-flight guard in Flutter widget tests; server-side idempotency in Edge Functions requires continuous monitoring against network retries.
