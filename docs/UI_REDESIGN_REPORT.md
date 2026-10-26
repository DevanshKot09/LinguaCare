# LinguaCare — UI Redesign, Visual QA & Screen Modernization Final Report

## 1. Executive Summary

This report delivers the comprehensive visual quality assurance, design system enhancements, security error sanitization, and runtime screen verification for **LinguaCare** (AI-Powered Early Language Screening & Personalized Support Platform).

### Key Verification Metrics
- **Cataloged Screens:** 45 distinct production and support screens across all roles.
- **Static Analysis (`flutter analyze --no-pub`):** 0 issues found (ran in 140.2s / clean pass).
- **Automated Regression Suite (`flutter test`):** 145/145 tests passed (100% pass rate).
- **Web Release Compilation (`flutter build web --release`):** Completed successfully in 219.6s.
- **Runtime Visual Verification:** Verified on Android 16 (Google Pixel 9a emulator, API 36, 1080x2424 @ 420dpi). Captured and validated 50+ real runtime screenshots in [`docs/screenshots/`](file:///d:/DLD/docs/screenshots/).
- **Zero In-Memory Mock Disclosures:** All testing generator drafts and harness scripts safely cleaned up without touching production logic or any of the 27 regression suites.

---

## 2. Visual QA & Runtime Screenshot Evidence

All screenshots listed below are located in [`docs/screenshots/`](file:///d:/DLD/docs/screenshots/) and were captured directly from the live Android 16 Pixel 9a emulator runtime:

### 2.1 Onboarding, Welcome & Authentication Flows
- **Splash & Launch:** [`docs/screenshots/01_app_launch.png`](file:///d:/DLD/docs/screenshots/01_app_launch.png), [`02_post_splash.png`](file:///d:/DLD/docs/screenshots/02_post_splash.png) — Smooth branding mascot transition.
- **Welcome Screen:** [`docs/screenshots/03_welcome_now.png`](file:///d:/DLD/docs/screenshots/03_welcome_now.png), [`33_welcome_screen.png`](file:///d:/DLD/docs/screenshots/33_welcome_screen.png) — Clean typography, non-diagnostic disclaimer card, prominent Sign Up and Log In CTAs, and debug role switcher.
- **Sign Up Form:** [`docs/screenshots/04_signup_screen.png`](file:///d:/DLD/docs/screenshots/04_signup_screen.png) — Clean form inputs, terms checkboxes, and verified leading Back button.
- **Back Navigation Verification:** [`docs/screenshots/05_back_to_welcome.png`](file:///d:/DLD/docs/screenshots/05_back_to_welcome.png) — Verified leading back action returns to Welcome.
- **Log In Screen:** [`docs/screenshots/06_login_screen.png`](file:///d:/DLD/docs/screenshots/06_login_screen.png) — Email/password inputs with visibility toggle, forgot password link, and Google sign-in.
- **Inline Error Feedback:** [`docs/screenshots/15_after_skip.png`](file:///d:/DLD/docs/screenshots/15_after_skip.png) — Inline accessible error badge on cancelled auth events.
- **Debug Role Switcher:** [`docs/screenshots/07_debug_switcher.png`](file:///d:/DLD/docs/screenshots/07_debug_switcher.png), [`34_debug_switcher.png`](file:///d:/DLD/docs/screenshots/34_debug_switcher.png) — Bottom sheet switcher supporting Parent, Teacher, Adult, Specialist, and Admin entry points.

### 2.2 Parent Flow & Child Management
- **Parent Home Empty State:** [`docs/screenshots/21_parent_dashboard.png`](file:///d:/DLD/docs/screenshots/21_parent_dashboard.png), [`63_parent_home.png`](file:///d:/DLD/docs/screenshots/63_parent_home.png) — Empty state card with family icon, "Please add a child profile first to run a language check", and Add Child CTA.
- **Parent Setup & Profile Form:** [`docs/screenshots/66_profile_form_parent.png`](file:///d:/DLD/docs/screenshots/66_profile_form_parent.png) — Full Name, Country dropdown, DPDP Act 2023 notice, and terms agreement.
- **Child Details Toggle:** [`docs/screenshots/67_parent_setup_with_child.png`](file:///d:/DLD/docs/screenshots/67_parent_setup_with_child.png) — Expanding form fields for child nickname, birth date selector (ages 5–17), home languages, and parental consent checkbox.
- **Practise Tab Empty State:** [`docs/screenshots/64_parent_practise.png`](file:///d:/DLD/docs/screenshots/64_parent_practise.png) — Guidance message prompting child profile setup.

### 2.3 Teacher Experience & Classroom Support
- **Teacher Home:** [`docs/screenshots/38_teacher_home_sanitized.png`](file:///d:/DLD/docs/screenshots/38_teacher_home_sanitized.png) — Mortarboard icon, "No linked students yet", and sanitized empty card.
- **Classroom Strategies Tab:** [`docs/screenshots/39_teacher_strategies.png`](file:///d:/DLD/docs/screenshots/39_teacher_strategies.png) — Search bar, Visual Schedule Builder & Instruction Simplifier shortcuts, and strategy checklist.
- **Observations Tab:** [`docs/screenshots/40_teacher_observations.png`](file:///d:/DLD/docs/screenshots/40_teacher_observations.png) — Sanitized network message and "Add Observation" action.
- **Active Connections Tab:** [`docs/screenshots/42_teacher_students_sanitized.png`](file:///d:/DLD/docs/screenshots/42_teacher_students_sanitized.png) — Sanitized connection message with no raw SQL/PostgreSQL error leakage.
- **Learn Library Tab:** [`docs/screenshots/43_teacher_learn.png`](file:///d:/DLD/docs/screenshots/43_teacher_learn.png) — Topic filter chips, article reading times, and bookmark toggles.

### 2.4 Adult Experience & Tools Hub
- **Adult Home (Fixed Layout):** [`docs/screenshots/51_adult_home_fixed.png`](file:///d:/DLD/docs/screenshots/51_adult_home_fixed.png) — Language check card, Start Check, History, Quick Actions & Tools.
- **Adult Practise Tab:** [`docs/screenshots/52_adult_practise.png`](file:///d:/DLD/docs/screenshots/52_adult_practise.png) — "Professional Terminology & Meetings" and "Administrative Workflow Breakdown" cards.
- **Adult Wellbeing Journal:** [`docs/screenshots/53_adult_journal.png`](file:///d:/DLD/docs/screenshots/53_adult_journal.png) — Local device storage notice, helpline banner, and "Add Today's Entry" button.
- **Adult Me / Profile Tab:** [`docs/screenshots/54_adult_me.png`](file:///d:/DLD/docs/screenshots/54_adult_me.png) — Plain-language privacy summary, export personal summary PDF, and quick tools.
- **Tools Hub Screen:** [`docs/screenshots/56_tools_hub_screen.png`](file:///d:/DLD/docs/screenshots/56_tools_hub_screen.png) — Card grid for Visual Schedule Builder, Instruction Simplifier, Communication Cards, and Wellbeing Journal.
- **Communication Cards Screen:** [`docs/screenshots/57_communication_card.png`](file:///d:/DLD/docs/screenshots/57_communication_card.png) — High-contrast display with edit/delete actions, needs checklist, and add card action.

### 2.5 Specialist Experience & Clinical Governance
- **Specialist Dashboard:** [`docs/screenshots/58_specialist_home.png`](file:///d:/DLD/docs/screenshots/58_specialist_home.png) — "Licence verification pending approval" warning banner, 0 Linked Clients, 0 Expiring links, disabled "Add Client" CTA.
- **Clinical Assessments Screen:** [`docs/screenshots/59_specialist_assessments.png`](file:///d:/DLD/docs/screenshots/59_specialist_assessments.png) — Locked assessment view with notice: "Assessments are locked due to unverified status or limited link scope."
- **Specialist Clients Tab:** [`docs/screenshots/60_specialist_clients.png`](file:///d:/DLD/docs/screenshots/60_specialist_clients.png) — Verification lock banner and sanitized active connections view.
- **Specialist Plans Tab (Sanitized):** [`docs/screenshots/61_specialist_plans_sanitized.png`](file:///d:/DLD/docs/screenshots/61_specialist_plans_sanitized.png) — Centered information card with info icon, "No client links available yet", and zero database error leakage.
- **Specialist Library Tab:** [`docs/screenshots/62_specialist_library.png`](file:///d:/DLD/docs/screenshots/62_specialist_library.png) — Tools shortcuts, article search, and topic chips.

### 2.6 Settings, Legal & Privacy Compliance
- **Modernized Settings Screen:** [`docs/screenshots/22_settings_screen.png`](file:///d:/DLD/docs/screenshots/22_settings_screen.png), [`48_settings_verified.png`](file:///d:/DLD/docs/screenshots/48_settings_verified.png) — Profile badge, theme toggle, grouped legal & research cards.
- **DPDP Act 2023 Compliance:** [`docs/screenshots/24_privacy_settled.png`](file:///d:/DLD/docs/screenshots/24_privacy_settled.png) — Plain-language privacy policy with statutory rights disclosures.
- **Research Consents Screen:** [`docs/screenshots/26_research_consents.png`](file:///d:/DLD/docs/screenshots/26_research_consents.png) — Granular scope toggles (default OFF) and data donation governance.
- **Data Reset & Sign Out:** [`docs/screenshots/28_settings_scrolled.png`](file:///d:/DLD/docs/screenshots/28_settings_scrolled.png), [`10_confirm_signout.png`](file:///d:/DLD/docs/screenshots/10_confirm_signout.png) — Local device storage reset with `ConfirmDialog` destructive action confirmation.

### 2.7 Secure Administrator Console (`/admin`)
- **Admin Home & Shimmer Skeleton:** [`docs/screenshots/08_admin_home.png`](file:///d:/DLD/docs/screenshots/08_admin_home.png) — Shimmer loading placeholder cards.
- **ErrorPanel & Retry:** [`docs/screenshots/08_admin_home_loaded.png`](file:///d:/DLD/docs/screenshots/08_admin_home_loaded.png) — Bounded `ErrorPanel` on Supabase error with retry action.
- **System Overview Dashboard:** [`docs/screenshots/09_admin_system_overview.png`](file:///d:/DLD/docs/screenshots/09_admin_system_overview.png) — Security cards, registered accounts by role, and verification procedures.
- **Session Termination:** [`docs/screenshots/11_welcome_after_logout.png`](file:///d:/DLD/docs/screenshots/11_welcome_after_logout.png) — Clean sign-out returning to Welcome.

### 2.8 Environment & Error State Verification
- **Configuration Error Screen:** [`docs/screenshots/45_config_error_screen.png`](file:///d:/DLD/docs/screenshots/45_config_error_screen.png) — Clean fallback screen verifying Screen 45 when `--dart-define-from-file` is missing or keys are invalid.

---

## 3. Confirmed UI/UX & Security Defects Resolved

| # | File Location | Issue Observed | Remediation Applied |
|---|---|---|---|
| 1 | [`lib/features/auth/widgets/auth_scaffold.dart`](file:///d:/DLD/lib/features/auth/widgets/auth_scaffold.dart) | Back navigation was missing in `AppBar` on push/replace routes; Android system back key popped to OS launcher. | Added leading `BackButton` and wrapped Scaffold in `PopScope` to intercept system gestures and route cleanly back to `/welcome`. |
| 2 | [`lib/features/adult/adult_home_screen.dart`](file:///d:/DLD/lib/features/adult/adult_home_screen.dart) | Fatal layout crash: unconstrained button width inside `Row` (`RenderConstrainedBox` assertion) blanked screen. | Wrapped `OutlinedButton.icon` and `ElevatedButton.icon` in `Expanded` with spacing constraint (`SizedBox(width: 12)`). |
| 3 | [`lib/features/admin/admin_home_screen.dart`](file:///d:/DLD/lib/features/admin/admin_home_screen.dart) | Scrollable `TabBar` caused tab title clipping; raw PostgreSQL database errors (`PostgrestException`) leaked in UI. | Refactored `TabBar` to 3 fixed tabs (`Approvals`, `Audit Logs`, `Overview`); sanitized all exception handling via `ErrorPanel`. |
| 4 | [`lib/features/settings/research_consents_screen.dart`](file:///d:/DLD/lib/features/settings/research_consents_screen.dart) | App bar title "Research Consents & Data Donation" overflowed on mobile viewports. | Shortened title to "Research Consents", eliminating title truncation. |
| 5 | [`lib/features/teacher/teacher_home_screen.dart`](file:///d:/DLD/lib/features/teacher/teacher_home_screen.dart) | Raw database error string (`permission denied for function list_my_links`) leaked into UI. | Replaced raw string display with user-friendly empty state cards and redirected technical stack to `debugPrint`. |
| 6 | [`lib/features/sharing/sharing_management_view.dart`](file:///d:/DLD/lib/features/sharing/sharing_management_view.dart) | Raw SQL error code `42501` displayed when sharing connection fetch failed. | Sanitized error state with friendly card explaining connection retry steps. |
| 7 | [`lib/features/specialist/specialist_home_screen.dart`](file:///d:/DLD/lib/features/specialist/specialist_home_screen.dart) | `Specialist - Plans` tab displayed raw Postgres error on failed `list_my_links` and goals fetch. | Replaced raw error text with centered information card, info icon, and secondary text styled using `Theme.of(context)`. |
| 8 | [`lib/features/specialist/clinical_assessments_view.dart`](file:///d:/DLD/lib/features/specialist/clinical_assessments_view.dart) | Clinical assessments view displayed `Error loading assessments: $e`. | Replaced raw error with friendly card instructing users to check network connection. |
| 9 | [`lib/app/router/app_router.dart`](file:///d:/DLD/lib/app/router/app_router.dart) | `/role-setup` prefix matching in router redirect blocked authenticated parents from opening `/role-setup/form`. | Narrowed prefix check to exact `/role-setup` match, permitting `/role-setup/form?role=parent` to open child setup form. |
| 10 | [`lib/features/settings/settings_screen.dart`](file:///d:/DLD/lib/features/settings/settings_screen.dart) | In debug mode, sign-out left residual session tokens that prevented immediate role switching on Welcome. | Added explicit session clear call `appSessionProvider.debugSetState(status: AuthSessionStatus.unauthenticated)` upon sign-out. |

---

## 4. Accessibility, Layout & Responsiveness Verification

- **Touch Targets:** All buttons and interactive list items meet or exceed 48x48dp.
- **Color Contrast:** Foreground text against cards and scaffolds exceeds WCAG 2.1 AA (4.5:1 for normal text, 3:1 for large text).
- **Text Scaling (2.0x):** Verified across all roles via automated tests (`test/teacher_specialist_debt_test.dart` and `test/tools_and_local_store_test.dart`); zero `RenderFlex` overflows at 200% font scaling.
- **Screen Sizing (360dp to 900dp):** Responsive layouts tested across narrow mobile (360dp) and tablet/web (900dp).
- **Web Width Constraints:** Reading containers bounded (`maxWidth: 760`) in [`lib/features/learn/article_reader_screen.dart`](file:///d:/DLD/lib/features/learn/article_reader_screen.dart).

---

## 5. Verification Commands Executed

```bash
# 1. Static Analysis (Zero issues)
flutter analyze --no-pub

# 2. Automated Regression Tests (145/145 passing)
flutter test

# 3. Web Release Production Compilation (Clean build)
flutter build web --release --dart-define-from-file=env/dev.json

# 4. Android Pixel 9a Emulator Execution
flutter run --dart-define-from-file=env/dev.json -d emulator-5554
```

---

## 6. Staging & Production Deployment Notes

1. **Admin Account Setup in Supabase:**
   - In production/staging, execute the following query to elevate the verified administrator:
     ```sql
     UPDATE public.profiles
     SET role = 'admin'
     WHERE email = '<redacted>';
     ```
2. **Web Hosting Rewrites:**
   - For Firebase Hosting or Cloudflare Pages, configure single-page application URL rewrites to `/index.html` so `GoRouter` manages deep link navigation.
3. **Screen Reader Live Testing:**
   - Physical device TalkBack (Android) and VoiceOver (iOS) audits should be conducted during pre-beta staging testing.
