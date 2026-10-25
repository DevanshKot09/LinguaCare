# LinguaCare (DLD) - Release Checklist & Deployment Guide

## 1. Android Application ID & Namespace
- **Application ID / Namespace:** `com.linguacare.app.linguacare`
- Configured in `android/app/build.gradle.kts` (`applicationId` and `namespace`) and `android/app/src/main/AndroidManifest.xml`.

## 2. Release Keystore Generation & Configuration
1. **Generate Release Keystore:**
   ```bash
   keytool -genkey -v -keystore release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias linguacare-release
   ```
2. **Create `key.properties`:**
   ```properties
   storePassword=<password>
   keyPassword=<password>
   keyAlias=linguacare-release
   storeFile=release-key.jks
   ```
3. **Configure `android/app/build.gradle.kts`:**
   Reference `key.properties` in the `release` signing config instead of debug keys.
   > [!IMPORTANT]
   > Never commit `release-key.jks` or `key.properties` to version control.

## 3. Firebase Release SHA-1 & SHA-256 Fingerprints
1. Extract release keystore SHA-1 and SHA-256:
   ```bash
   keytool -list -v -keystore release-key.jks -alias linguacare-release
   ```
2. Register fingerprints in Firebase Console -> Project Settings -> Android App (`com.linguacare.app.linguacare`).
3. Re-download `google-services.json` and place in `android/app/google-services.json`.

## 4. Google Play Data Safety Draft Answers
- **Data Collection:**
  - *Personal Info:* Name, Email (for account management and authentication).
  - *Health & Fitness:* Screening answers, observation notes, and practice metrics (stored securely with strict RLS policies).
- **Data Sharing:** No data shared with third parties for advertising or monetisation. De-identified research data shared only with explicit opt-in user consent (`Research Consents v1.0`).
- **Encryption:** All data encrypted in transit (HTTPS/TLS) and at rest (Supabase Postgres encryption).
- **Account Deletion:** Users can request permanent account deletion and local data wipe directly within the app settings.

## 5. Privacy Policy Hosting
- **URL:** `https://linguacare.app/privacy` (Hosted via GitHub Pages / custom domain).
- Fully compliant with DPDP Act 2023, COPPA, and GDPR data privacy standards.

## 6. Store Listing Text
- **App Name:** LinguaCare: DLD Support & Screening
- **Short Description:** Supportive screening, daily practice, and collaboration tools for Developmental Language Disorder.
- **Long Description:** Empowering parents, teachers, adults (18+), and speech-language pathologists with evidence-informed screening, daily practice activities, visual schedules, communication cards, and collaborative progress tracking. (Non-diagnostic, strengths-first approach).

## 7. Pre-Submission Review Checklist
- [x] All unit, widget, and accessibility tests pass successfully (`flutter test` 100% pass).
- [x] Flutter analyzer reports 0 errors and 0 warnings (`flutter analyzer`).
- [x] Supabase RLS policies and database migration tests verified (`rls_checks.sql` and Phase C tests pass).
- [x] ProGuard rules configured and release minification verified (`isMinifyEnabled = true`, `isShrinkResources = true`).
- [x] Android accessibility guidelines met (`androidTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline`) at 360dp and text scale 2.0.

## 8. Test Accounts Cleanup
- Clean up and delete temporary sandbox auth tokens, test emails, and test child records from Supabase and Firebase before submitting to Google Play Store.

## 9. QA Matrix (4 Roles tested on Samsung SM A146B and Redmi 6A)
| Device | OS / Screen | Parent Role | Teacher Role | Adult Role (18+) | Specialist Role (SLP) | Status |
|---|---|---|---|---|---|---|
| **Samsung SM A146B (Galaxy A14 5G)** | Android 14, 6.6" | Pass (Screening, Activity, Sharing) | Pass (Observations, Strategies) | Pass (Journal, Comm Cards) | Pass (Caseload, Assessments) | **PASSED** |
| **Redmi 6A** | Android 9, 5.45" (Compact 360x720) | Pass (Adaptive layout) | Pass (Navigation rail) | Pass (Text scale 2.0) | Pass (Secure RLS data access) | **PASSED** |
