# LinguaCare (DLD App) - Project Context & Architecture

## 1. Project Vision & Goals
- **Vision:** A supportive, non-diagnostic mobile app (Android + iOS) for Developmental Language Disorder (DLD), empowering Parents, Teachers, Adults (18+), and Specialists to screen, practice, track, and collaborate.
- **Core Goals:** Early awareness and risk profiling, evidence-informed daily activities, objective progress tracking, role-based collaboration, and learning from consented specialist-confirmed cases.
- **Hard Guardrails:** **Never diagnoses** (screens, profiles, and refers); uses strengths-first, non-stigmatising language; strictly protects child data (minimal collection, parental consent, RLS on every table); free-tier optimized.

## 2. Roles & Permissions
1. **Parent:** Manages child profiles (bands 5–11 and 11–18); runs screenings and daily activities; shares data with teachers/specialists under parent control.
2. **Teacher:** Manages linked students; records observations; accesses strategies and accommodations.
3. **Adult (18+):** Self-screening, practice exercises, journal, and communication-needs card.
4. **Specialist (SLP):** Manages caseload; sets goals; enters gold-standard **clinical confirmed outcomes**; requires licence verification.
5. **Admin / Clinical Reviewer (Internal):** Verified specialists, approves content, oversees de-identified research exports (audit-logged).

## 3. Tech Stack & Architecture
- **Framework:** Flutter (Dart) using Android Studio.
- **State Management:** Riverpod.
- **Navigation:** `go_router` (role-based guards, deep linking, pushed flows).
- **Auth & Backend:** Firebase Auth (Email/Password, Google with pre-initialized instance and precise exception mapping) + Supabase (Postgres + RLS + Storage + Edge Functions with idempotent OTP verification).
- **Architecture:** Feature-first clean architecture (`lib/app`, `core`, `data`, `domain`, `features`).
- **Responsive & Accessibility:** Adapts to compact (<600dp), medium (600–839dp), and expanded (≥840dp) screens; Lexend typography; supports text scaling up to 200%, screen readers, and reduce-motion.

## 4. Database Schema & RLS
- Core tables: `email_verifications`, `profiles`, `specialist_details`, `teacher_details`, `children`, `otp_codes`, `consents`, `access_audit`, `links`, `invites`, `invite_attempts`, `content_items`, `activities`, `activity_sessions`, `screening_results`, `observations`, `goals`, `adult_journal`, `comm_cards`.
- Clinical & ML tables: `clinical_assessments`, `screening_sessions_v2`, `research_consents`, `ml_records`, `model_versions`, `access_audit`.
- **Security:** RLS enabled on all tables; service-role-only access for `otp_codes` and `email_verifications`; parent/adult-controlled sharing via `invites` and `links` using SECURITY DEFINER RPCs with `(auth.jwt()->>'sub')`.

## 5. Screening & AI Pipeline
- **Level 1:** Age-banded questionnaires (Parent/Teacher/Adult) yielding risk level (`low`, `some_signs`, `high`), domain profile, and "also check" flags.
- **Level 2:** In-app age-banded child tasks (vocabulary, grammar, narrative, comprehension, conversation).
- **Level 3:** Specialist assessment and **confirmed outcome** (`typical`, `dld`, etc.) stored in `clinical_assessments`.
- **AI/ML:** Two-key consent (app use vs research/training); pseudonymised research store; decision-support model trained on specialist-confirmed cases with human-in-the-loop validation.

## 6. Verification Status Table

| Component / Layer | Verified by Automated Tests | Verified on Real Database | Verified on Real Device | NOT Verified |
|---|---|---|---|---|
| **App Startup & SharedPreferences** | Yes (`app_session_error_test.dart`) | N/A | Pending physical device QA | Background persistence across process death |
| **Goals & Observations payloads** | Yes (`observation_goal_test.dart`) | Yes (Supabase RLS & tables) | Pending physical device QA | Offline queue sync conflict resolution |
| **Shared Summary Scope Rendering** | Yes (`sharing_test.dart`) | Yes (`get_shared_summary` RPC) | Pending physical device QA | Multi-device concurrent revocation race condition |
| **Activity Wrap-Up Semantics & Rating** | Yes (`activity_widget_test.dart`) | Yes (`activity_sessions` table) | Pending physical device QA | Battery drain profiling during long sessions |
| **Database Security & RLS Policies** | Yes (`phase6_rls_checks.sql`) | Yes (Supabase RLS migrations) | N/A | Edge case concurrency in multi-tenant inserts |
| **Release Build Safety & R8 Minify** | Yes (ProGuard rules verified) | N/A | Pending physical device release APK | Play Store upload pipeline integration |
