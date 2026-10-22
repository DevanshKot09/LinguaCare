# Supabase SQL Test Suites

**DEV ONLY — NEVER RUN IN PRODUCTION**

These scripts test RLS policies, RPC security, and table constraints across all schema modules.

## How to Run in Supabase SQL Editor

1. Open your **Supabase Dashboard** for the **DEV Project**.
2. Navigate to the **SQL Editor** tab in the sidebar.
3. Create a new query or open an editor tab.
4. Copy and paste the entire contents of one test script (e.g., `rls_checks.sql`) into the SQL Editor. **Select nothing**.
5. Click **Run** (or press Ctrl+Enter / Cmd+Enter).

## Expected Outcome & Harness Design
- Each script is wrapped in a single atomic `DO $$ ... $$` block.
- Upon completion, the script raises an expected exception containing the full test log, fixture verification counts, and summary (`TEST RESULTS: X passed, Y failed`).
- **Everything is automatically rolled back** when the exception is raised, so no test fixtures or dummy data persist in your database.
- Positive controls prove that policies are functioning correctly and not blindly blocking access.
- A **CANARY (must show FAIL)** test is included in every suite to verify that failures are correctly logged (if it ever shows PASS, the harness is broken).

## Test Manifest Rule (Mandatory)
- Every test script must declare an explicit array of `v_required_tests` at the start of the execution block.
- At the completion of tests, the harness verifies that every required test name appears in the execution log (`v_log`).
- Any missing test is automatically flagged as `FAIL: MISSING TEST <name>` and counted towards failure.
- The harness prints `MANIFEST: <n> expected, <n> logged, <n> missing` and `TOTAL real tests logged (excluding canary): N`.
- Tests may not be deleted without explicit approval; if a test cannot run, it must log `FAIL` with the blocking reason.

## Execution Order & Verification Results (Latest Execution)
Run the following test scripts in order:

1. `rls_checks.sql` — Verifies core RLS policies for profiles, children, screening sessions, activity sessions, content items, and OTP codes. **Result: 31 passed, 0 failed.**
2. `rls_checks_links.sql` — Verifies sharing invitation creation, preview, acceptance, role restrictions, and specialist verification logic. **Result: 18 passed, 0 failed.**
3. `rls_checks_obs_goals.sql` — Verifies observations and goals table constraints (PNN/email/phone detection, tag/length limits, domains, settings) and RLS access rules. **Result: 22 passed, 0 failed.**

## Specific Remaining Risks and Untested Areas
1. **Concurrent Invitation Brute-Forcing / Rate Limiting race conditions**: While `invite_attempts` tracks and locks UIDs after 6 failed attempts, concurrent requests across database worker threads could potentially bypass attempt counts if not isolated via strict advisory locks or row locking.
2. **Edge cases in JWT claims parsing**: If Supabase Auth JWT claims format changes or `auth.jwt()->>'sub'` returns empty strings or malformed UUIDs under unusual OAuth/refresh token flows, trigger derivation fallbacks could experience unhandled exceptions.
3. **Large Payload Pagination in RPCs**: `get_shared_summary` caps screening sessions at 100, activities at 500, and observations at 100. Extremely dense longitudinal data for chronic care users over multi-year spans could hit memory or payload size thresholds.
4. **Offline Sync Replay Conflicts**: Client-side offline queue replay of observations/goals or activity sessions could result in out-of-order timestamps or constraint violations if server clocks and client device clocks drift significantly.
5. **Client-side RenderFlex Overflow on Compact Screens**: Flutter test suite identified potential text-scale overflow edge cases (`VerifyEmailScreen` at textScale 2.0 on compact 320x480 viewports).

## Where to Find Results & How to Report
- After running a script, check the **Error / Result message box** at the bottom of the SQL Editor where the `TEST RESULTS` exception message is displayed.
- Copy and send back **ONLY** the lines starting with `PASS:` or `FAIL:` and the `SUMMARY` block.
- **DO NOT** send any secret tokens, env variables, or credentials.
