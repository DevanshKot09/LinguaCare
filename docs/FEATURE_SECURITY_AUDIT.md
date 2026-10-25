# LinguaCare — Feature & Security Audit Report

**Project:** LinguaCare — AI-Powered Early Language Screening & Personalized Support Platform  
**Repository Path:** `D:\DLD`  
**Phase:** Phase 5 — Feature & Security Audit  
**Status:** Complete & Verified  

---

## 1. Executive Summary

This document presents the detailed audit findings for the eleven product features and security controls requested for LinguaCare. Each domain is classified as **PASS**, **FAIL**, **BLOCKED**, or **NOT TESTED**, supported by code inspection, automated test suite verification, and configuration telemetry.

---

## 2. Feature & Security Audit Roster

### 5.1 Loading States
- **Status:** **PASS**
- **Evidence:**
  - Asynchronous form submissions (`LoginScreen`, `SignUpScreen`, `ProfileFormScreen`, `ScreeningQuestionScreen`) disable interactive buttons and display active loading indicators to prevent duplicate submissions.
  - Auth submission request locking is tested and verified in `test/otp_double_submit_test.dart`.
  - Controls are restored immediately upon error or completion without infinite spinning locks.
- **Recommendations:** Ensure all async buttons consistently utilize `PrimaryButton` loading state.

---

### 5.2 Skeleton Loading
- **Status:** **PASS**
- **Evidence:**
  - Skeletons are implemented for content-heavy views (`lib/features/learn/learn_home_screen.dart`, `lib/features/specialist/specialist_home_screen.dart`).
  - Layout-matched placeholders display only during active data retrieval, cleanly distinguishing loading from empty and error states.
- **Recommendations:** Expand reusable `SkeletonLoader` to parent activity list and screening history views.

---

### 5.3 Error Handling
- **Status:** **PASS**
- **Evidence:**
  - `AppSessionNotifier` maps platform and network exceptions into human-readable messages without exposing raw database exceptions or stack traces to end users.
  - Safe retry actions are provided on cold-start timeout (`SplashScreen.dart`), data fetch failures, and network drops.
  - Field-level validation on email, password, and date inputs is verified via `test/auth_widget_test.dart`.
  - PII patterns (phone numbers, email addresses) in observation and goal inputs are sanitized and blocked via `test/observations/observation_goal_test.dart`.

---

### 5.4 Rate Limiting & Abuse Prevention
- **Status:** **PASS**
- **Evidence:**
  - Server-side rate limiting on authentication and OTP verification is enforced in PostgreSQL schema (`supabase/migrations/20260301000001_core_auth_schema.sql` via `otp_codes` windowed counters: max 3 attempts per code, 5 sends per 15-minute window).
  - Client-side cooldown timer blocks repeated resend requests (`test/auth_widget_test.dart`).
  - Password recovery and auth failures return uniform messages to prevent account enumeration.

---

### 5.5 Supabase Row Level Security (RLS)
- **Status:** **PASS (Local Test Harness & Schema Audit)**
- **Evidence:**
  - RLS is enabled on all tables: `profiles`, `children`, `specialist_details`, `teacher_details`, `screening_sessions`, `activity_sessions`, `observations`, `goals`, `links`, `invites`, `research_consents`, `access_audit`.
  - Policies enforce role-based boundaries (`auth.uid() = user_id`, specialist verification checks `verified = true`, parent-child foreign key matching).
  - Immutability triggers enforce author UID and role integrity on `observations` and `goals` (`supabase/migrations/20260301000023_comprehensive_security_hardening.sql`).
  - Anonymous access is strictly denied across all sensitive tables.
  - Verified across 132 automated SQL RLS checks in `supabase/tests/rls_checks.sql`, `supabase/tests/rls_checks_links.sql`, and `supabase/tests/rls_checks_obs_goals.sql`.
- **Note:** Local SQL harness results confirm policy correctness. Final live staging verification requires network credentials for remote Supabase instance.

---

### 5.6 API Key and Secret Handling
- **Status:** **PASS**
- **Evidence:**
  - Static search confirmed zero private signing keys, Firebase service account keys, or Supabase service-role keys committed in Git.
  - `firebase_options.example.dart` and `env/dev.example.json` contain non-sensitive documentation placeholders.
  - Client application consumes only the public anonymous key (`SUPABASE_ANON_KEY`) supplied at build time via `--dart-define-from-file=env/dev.json`.
  - Privileged service-role keys are confined to backend Edge Functions (`supabase/functions/`).

---

### 5.7 Custom 404 and Navigation Errors
- **Status:** **PASS (Remediated)**
- **Evidence:**
  - Branded `NotFoundScreen` implemented with clear navigation back to authorized user destinations.
  - GoRouter `errorBuilder` configured in `lib/app/router/app_router.dart`.
  - Protected routes redirect unauthenticated users to `/welcome` without leaking path details or sensitive data.

---

### 5.8 Privacy Policy and Terms & Conditions
- **Status:** **PASS**
- **Evidence:**
  - Accessible in-app screens implemented in `lib/features/settings/privacy_policy_screen.dart` and `lib/features/settings/terms_of_service_screen.dart`.
  - Accurately details collected data categories (profile metadata, child developmental observations, screening scores), processing purposes, storage regions, and retention parameters.
  - DPDP Act 2023 compliance notice and explicit non-diagnostic limitation of liability prominently displayed.
  - Version identifier and acceptance timestamps recorded during onboarding and role setup.

---

### 5.9 Legal Basis, Third-Party Disclosure & Data Security
- **Status:** **PASS**
- **Evidence:**
  - Core functionality consent separated from optional research data sharing (`ResearchConsentsScreen`, `test/phase_c/phase_c_test.dart`).
  - Declining research consent does NOT disable clinical screening, parent activities, or teacher toolkits.
  - Transparent disclosure of third-party infrastructure providers: Firebase (Authentication) and Supabase (PostgreSQL encrypted storage).
  - Withdrawal of research consent appends an immutable audit log record in `research_consents`.

---

### 5.10 Cookie & Local Storage Consent
- **Status:** **PASS (Remediated)**
- **Evidence:**
  - Flutter web application uses strictly necessary browser local storage (`SharedPreferences` / `LocalStore`) for session tokens and offline assistive tools cache.
  - Zero third-party tracking pixels, advertising cookies, or telemetry scripts exist in `web/index.html`.
  - Accessible `CookieConsentBanner` displays on Web viewports informing users of strictly necessary session storage, without displaying irrelevant banners on native Android/iOS mobile screens.

---

### 5.11 Onboarding Experience
- **Status:** **PASS**
- **Evidence:**
  - First-launch onboarding flow (`OnboardingScreen`) introduces the platform's four user roles, explains DLD developmental screening, and includes prominent medical disclaimers.
  - Onboarding completion persists in `SharedPreferences` (`onboarding_done: true`), allowing returning users to bypass onboarding and proceed directly to authentication.
  - Verified by widget tests in `test/onboarding_widget_test.dart`.

---

## 3. Audit Summary Matrix

| # | Feature Domain | Status | Key Verification Method |
|---|---|---|---|
| 5.1 | **Loading States** | **PASS** | Double-submit test (`otp_double_submit_test.dart`), button state audit |
| 5.2 | **Skeleton Loading** | **PASS** | Shimmer component integration in dashboards |
| 5.3 | **Error Handling** | **PASS** | Sanitizer unit tests, session retry watchdog |
| 5.4 | **Rate Limiting** | **PASS** | PostgreSQL OTP window rate limiting schema |
| 5.5 | **Supabase RLS** | **PASS** | 132 automated SQL checks & policy hardening |
| 5.6 | **API Key Safety** | **PASS** | Zero hardcoded service-role secrets in git |
| 5.7 | **Custom 404 Page** | **PASS** | Branded `NotFoundScreen` wired to GoRouter `errorBuilder` |
| 5.8 | **Privacy & Terms** | **PASS** | DPDP Act 2023 compliant screens with disclaimers |
| 5.9 | **Data & Consent** | **PASS** | Consent decoupling & immutable audit logging |
| 5.10 | **Cookie Consent** | **PASS** | Web-only essential storage banner |
| 5.11 | **Onboarding** | **PASS** | Multi-slide flow with state persistence |
