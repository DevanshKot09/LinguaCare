# Known Issues & Deferred Items (LinguaCare DLD Support App)

## Resolved in Phase 6 (March 2026)
1. **[RESOLVED] DB High**: Non-author observation UPDATE policy hole fixed in migration `20260301000022_fix_observation_update_policy.sql`.
2. **[RESOLVED] DB Medium**: UPDATE on `screening_sessions` / `activity_sessions` re-locked to owners/parents.
3. **[RESOLVED] DB Security**: Added explicit `search_path` on SECURITY DEFINER functions (`accept_invite`, `get_shared_summary`).
5. **[RESOLVED] Release**: SharedPreferences ProGuard keep rules added to `android/app/proguard-rules.pro` to prevent R8 obfuscation crashes.
7. **[RESOLVED] Analyzer**: Cleaned all analyzer infos and deprecations (`flutter analyze` reports 0 issues).
8. **[RESOLVED] Fonts**: Lexend font offline loading guaranteed via `GoogleFonts.config.allowRuntimeFetching = false;`.
9. **[RESOLVED] Observations**: Added `updateObservation` method to `ObservationRepository` for UI-to-repository edit sync.

## Unresolved / Deferred Items
4. **Auth**: OTP "invalid or expired" needs a fresh test after verify-otp deploy; Google sign-in needs SHA fingerprints and a web OAuth client in `google-services.json`.
6. **Performance**: Slow debug cold start on Redmi 6A; release performance verified.
10. **Content**: Screening items, activities, and articles are drafts pending clinical review and are hidden in release builds.
11. **Later Phases**: PDF export (needs `pdf` package), specialist confirmed outcome and research consent (need new database tables), reminders (needs a notifications package), Hindi localisation.
