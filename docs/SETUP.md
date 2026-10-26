# LinguaCare Setup & Configuration Guide

## 1. Required Configuration Items

| Item Name | Where It Lives | Example Placeholder Format | Who Sets It | Purpose |
|---|---|---|---|---|
| `SUPABASE_URL` | `env/dev.json` | `https://abcdefghijklmnopqrstuvwx.supabase.co` | Developer | Supabase project endpoint |
| `SUPABASE_ANON_KEY` | `env/dev.json` | `sb_publishable_...` or JWT | Developer | Supabase public anonymous API key |
| `FIREBASE_PROJECT_ID` | Supabase Secrets | `linguacare-dev` | Developer / Admin | Firebase project identifier |
| `FIREBASE_SERVICE_ACCOUNT` | Supabase Secrets | `{"type": "service_account", ...}` | Developer / Admin | Firebase admin SDK JSON credentials |
| `SMTP_HOST` | Supabase Secrets | `smtp.gmail.com` | Developer / Admin | Email server host |
| `SMTP_PORT` | Supabase Secrets | `465` | Developer / Admin | Secure SMTP port (must be 465) |
| `SMTP_USER` | Supabase Secrets | `<redacted>` | Developer / Admin | SMTP authentication username |
| `SMTP_PASSWORD` | Supabase Secrets | `abcdefghijklmnop` | Developer / Admin | SMTP password / App Password |
| `SMTP_FROM_NAME` | Supabase Secrets | `LinguaCare` | Developer / Admin | Sender display name |
| `SMTP_FROM_EMAIL` | Supabase Secrets | `<redacted>` | Developer / Admin | Sender email address |
| `OTP_PEPPER` | Supabase Secrets | `secure-random-pepper` | Developer / Admin | Cryptographic salt for OTP hashes |

---

## 2. Google Sign-In Manual Configuration Steps
To ensure Google Sign-In works correctly in Android debug and release builds:
1. **Generate Signing Report:**
   Run the following command in the terminal to obtain the SHA-1 and SHA-256 fingerprints:
   ```bash
   cd android && ./gradlew signingReport
   ```
2. **Add SHA-1 & SHA-256 to Firebase Console:**
   Go to your Firebase Console project settings, select the Android app (`com.linguacare.app.linguacare`), and add both debug and release SHA-1 and SHA-256 fingerprints.
3. **Enable Google Sign-In Provider:**
   In Firebase Console -> Authentication -> Sign-in method, enable the **Google** provider and provide a project support email.
4. **Re-download google-services.json:**
   Download the updated `google-services.json` file from Firebase Console and place it into `android/app/google-services.json`.
5. **Clean Build:**
   Run `flutter clean` and `flutter pub get` before rebuilding the app.

---

## 3. Database Migration Push Order & Troubleshooting
1. **Check Migration History:**
   ```bash
   npx supabase migration list
   ```
2. **Push Migrations to Remote Supabase:**
   ```bash
   npx supabase db push
   ```
3. **What to do if a migration fails:**
   If `npx supabase db push` fails, paste **ONLY** the error block into the diagnostic report, verify the failing migration file, apply necessary idempotent adjustments, and retry.

---

## 4. SMTP Troubleshooting Steps
1. **Port 465 Only:** Ports `25` and `587` are blocked on the Edge Function platform. Ensure `SMTP_PORT` is set strictly to `465` with SSL/TLS (`secure: true`).
2. **App Passwords:** If using Gmail, ensure 2-Factor Authentication is enabled and generate a 16-character **App Password** with **no spaces**. Never use your personal account password.
3. **Dedicated Sender:** Use a dedicated transactional email account to prevent rate-limiting or blocking.
4. **Logs Inspection:** Check Edge Function execution logs in the Supabase dashboard (`Functions -> send-otp -> Logs`) if email delivery fails.

---

## 5. Correct Release Build & Run Commands
Always provide the environment configuration file via `--dart-define-from-file` for release execution and builds:

- **Run Release on Device/Emulator:**
  ```bash
  flutter run --release -d <device> --dart-define-from-file=env/dev.json
  ```
- **Build Release APK:**
  ```bash
  flutter build apk --release --dart-define-from-file=env/dev.json
  ```
> [!IMPORTANT]
> **TODO (Release Keystore):** The release buildType currently signs with the debug key for convenience during evaluation (`signingConfig = signingConfigs.getByName("debug")`). A real production release keystore (signing config) must be configured in `android/app/build.gradle.kts` prior to any Google Play Store or app distribution upload. Never commit keystore files or passwords to version control.

If `SUPABASE_URL` or `SUPABASE_ANON_KEY` are missing or invalid, the app automatically presents the `ConfigErrorScreen` with clear diagnostics.

---

## 6. Android Auto Backup Trade-Off (`android:allowBackup="false"`)
To comply with strict data privacy principles (DPDP Act 2023) and protect sensitive local user data (such as adult journal entries, visual schedules, communication cards, and local notes stored in SharedPreferences), `android:allowBackup` is explicitly set to `false` in `AndroidManifest.xml`.
- **Trade-Off:** Local-only tool and journal data are excluded from Google Cloud Auto Backup. If a user uninstalls the app or switches devices without exporting or cloud syncing, local-only data stored in SharedPreferences will not be automatically restored.

