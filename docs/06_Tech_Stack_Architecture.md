# 06 · Tech Stack & Architecture

## 1. Choice
**Flutter (Dart) built in Android Studio** → one codebase for Android + iOS, responsive layouts, rich animation.
> Note: Android Studio builds/runs Android directly. **iOS builds require a Mac with Xcode** (for signing, simulator, App Store). Plan for a Mac/CI (e.g., Codemagic free tier / GitHub Actions macOS) before iOS release.

## 2. Stack
| Layer | Tool |
|---|---|
| UI | Flutter 3.x, Material 3, `flutter_screenutil`/`LayoutBuilder` + breakpoints |
| State | Riverpod |
| Navigation | go_router (role guards, deep links) |
| Auth | firebase_auth, google_sign_in |
| Backend DB | Supabase (Postgres + RLS + Storage + Edge Functions) via `supabase_flutter` |
| Local/offline | Drift (SQLite) or Hive + sync queue |
| Animation | Lottie / Rive, implicit animations, Hero |
| Audio/Speech | `just_audio`, `record`; TTS via `flutter_tts`; STT optional (`speech_to_text`) |
| Notifications | firebase_messaging + `flutter_local_notifications` (reminders) |
| Charts | `fl_chart` |
| PDF export | `pdf` + `printing` |
| i18n | `flutter_localizations` + ARB |
| Crash/analytics | Firebase Crashlytics (privacy-minimal analytics, no child PII) |

## 3. Architecture (feature-first Clean Architecture)
```
lib/
 ├─ main.dart
 ├─ app/            (router, theme, di, env)
 ├─ core/           (errors, utils, widgets, responsive, network, storage)
 ├─ data/           (supabase_client, repositories, dto, local_db)
 ├─ domain/         (entities, repository interfaces, usecases)
 └─ features/
     ├─ splash/ onboarding/ auth/ role_setup/
     ├─ parent/ teacher/ adult/ specialist/
     ├─ learn/ screen/ practise/ track/ collaborate/ tools/
     └─ settings/ privacy/
assets/ (lottie, images, audio, fonts, content_json)
```

## 4. Responsive Strategy (all screen sizes)
| Width | Class | Layout |
|---|---|---|
| < 600 dp | Compact | single column, bottom nav |
| 600–839 | Medium | NavigationRail, 2-col grids |
| ≥ 840 | Expanded | master-detail, max content width 1000 dp |
- Use `MediaQuery.sizeOf`, `LayoutBuilder`, `SafeArea`, text scaling up to 200%.
- Test: small phone (360×640), large phone, foldable, 7" and 10" tablet, iPhone SE → iPad.

## 5. Free-Tier Guardrails (verify current limits)
- Firebase Spark: Auth free (phone SMS not free; we don't use it), FCM free.
- Supabase Free: limited DB size, storage, edge-function invocations, **projects pause after inactivity** → add keep-alive/cron, plan upgrade path.
- Store audio minimally; compress; prefer on-device processing; auto-delete voice clips.

## 6. Environments
`dev` / `staging` / `prod` Supabase + Firebase projects; secrets via `--dart-define-from-file` (never commit keys).

## 7. Content Delivery
Educational/activity content shipped as **versioned JSON in assets** + remote update via Supabase `content_items` table (offline-first, cached).
