# 12 · Android Studio Setup & Project Bootstrap

## 1. Install
1. Android Studio (latest stable) + **Flutter** and **Dart** plugins.
2. Flutter SDK (stable); run `flutter doctor` until green.
3. Android SDK, emulator images (phone + tablet + foldable). 
4. For iOS: Mac + Xcode + CocoaPods (required for iOS builds/signing).

## 2. Create Project
```bash
flutter create --org com.yourorg --project-name lingua_care lingua_care
cd lingua_care
```

## 3. Packages (pubspec.yaml)
```yaml
dependencies:
  flutter_riverpod: ^2.x
  go_router: ^14.x
  firebase_core: ^3.x
  firebase_auth: ^5.x
  firebase_messaging: ^15.x
  firebase_crashlytics: ^4.x
  google_sign_in: ^6.x
  supabase_flutter: ^2.x
  drift: ^2.x
  sqlite3_flutter_libs: ^0.5.x
  lottie: ^3.x
  rive: ^0.13.x
  fl_chart: ^0.69.x
  flutter_local_notifications: ^17.x
  just_audio: ^0.9.x
  flutter_tts: ^4.x
  pdf: ^3.x
  printing: ^5.x
  intl: any
  flutter_secure_storage: ^9.x
  connectivity_plus: ^6.x
```
> Versions are placeholders — run `flutter pub add <pkg>` to get current ones.

## 4. Firebase Setup
1. Create Firebase project → add Android (package name + **SHA-1/SHA-256**) and iOS apps.
2. Enable Auth providers: Email/Password, Google.
3. `dart pub global activate flutterfire_cli` → `flutterfire configure`.
4. Customise email templates (password reset); set sender/domain.
5. Create service account (for Edge Function to set `emailVerified`); store in Supabase secrets.

## 5. Supabase Setup
1. New project → run SQL from `07_Database_Schema.md`.
2. Enable **Third-Party Auth → Firebase** (project ID).
3. Create Edge Functions: `send-otp`, `verify-otp`, `delete-account`.
4. Add secrets: `SMTP_HOST/PORT/USER/PASS`, `FIREBASE_SERVICE_ACCOUNT`, `OTP_PEPPER`.
5. Enable RLS and policies; seed `content_items`, `activities`.

## 6. Config
`env/dev.json`, `env/prod.json` (gitignored):
```json
{ "SUPABASE_URL": "...", "SUPABASE_ANON_KEY": "..." }
```
Run: `flutter run --dart-define-from-file=env/dev.json`

## 7. Android Specifics
`minSdk 23+`, target latest · Android 12+ splash API · `android:windowSoftInputMode=adjustResize` · enable R8/ProGuard · notification permission (Android 13+).

## 8. iOS Specifics
Deployment target 13+ · Google Sign-In URL scheme · push capability + APNs key in Firebase · Privacy manifest · `Info.plist` mic usage description (if voice).

## 9. Definition of Done (per feature)
Responsive on 3 breakpoints · light/dark · TalkBack/VoiceOver labels · text scale 200% OK · offline behaviour defined · RLS tested · unit + widget tests · no PII in logs.

## 10. First Build Order
1. Theme + responsive scaffold → 2. Splash/onboarding → 3. Auth screens (UI) → 4. Firebase auth wired → 5. OTP functions → 6. Role setup → 7. Parent home + child profile → 8. Screening → 9. Activity player → 10. Progress.
