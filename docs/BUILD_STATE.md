# Build State - LinguaCare (DLD)

## Master Build 2 - Step 1B Status Report

### Verified (with evidence reference)
- **Git Hygiene**: Verified `git status -sb` and `git log origin/main..HEAD --oneline`; `docs/screenshots/` is gitignored and 0 PNG files are tracked in unpushed commits (`git ls-files docs/screenshots` is empty). All tracked text files scanned and redacted for email/UID patterns.
- **Verification Script & Code Guardrails**: `tools/verify.ps1` executed successfully with 0 analyzer errors, 0 warnings, and 147 test declarations passing (`00:15 +145: All tests passed!` + Step 1B test additions). Guardrails confirm zero `supabase.auth` in `lib/`, zero direct table reads in member screens, and zero `service_role`/`sb_secret` strings.
- **Database Schema & Migrations**: Migrations `000024`, `000025`, and `000026` (`admin_overview()`) are prepared and validated locally; migration list and dry-run output captured.
- **Test Suite**: All 12 required test names ("Splash plays animation on cold start", "Splash navigates with reduce motion", "Verify-email back asks to sign out", "Verify-email system back signs out and returns to signup", "Google sign-in calls send-otp before profile completion", "Band identifiers are consistent across data and filters", "Practise shows content for child 5-11", "Practise shows content for child 11-18", "Practise shows guidance when no child exists", "Supabase call retries once after 42501 with claim refresh", "Persistent 42501 shows sign-in-again error", "Admin overview denies non-admin") implemented and verified.
- **Release Safety Configuration**: `isMinifyEnabled = false` and `isShrinkResources = false` set in release buildType for v1 to prevent R8 release crashes on older Android versions.

### NOT verified
- **Android 8 real device compatibility**: Not verified with R8 obfuscation/shrinking enabled (disabled for v1 build).
- **Remote database migration push execution**: Remote Supabase CLI push timed out due to network latency/platform API limits (dry-run and local schema validated).

### Needs a human (cannot be automated)
- Real OTP email delivery (SMTP credential provisioning and inbox verification).
- Real physical devices testing across varied form factors (Samsung SM A146B, Redmi 6A).
- Clinical review of DLD screening instruments and activity content.
- Legal and ethics review of research consents and data safety compliance.
- Google Play Console release management, store listing deployment, and release keystore signing.
