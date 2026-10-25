# LinguaCare — Screen Inventory & Navigation Architecture

**Project:** LinguaCare — AI-Powered Early Language Screening & Personalized Support Platform  
**Repository Path:** `D:\DLD`  
**Phase:** Phase 1 — Repository Discovery and Screen Inventory  
**Status:** Complete & Verified  

---

## 1. Executive Summary

This inventory catalogues every screen, route, widget view, and navigation entry point discovered within the LinguaCare repository. The platform serves four primary user roles: **Parent**, **Teacher**, **Specialist**, and **Adult**, in addition to unauthenticated visitors and onboarding/auth flows.

---

## 2. Complete Screen Inventory

| # | Screen Name | Source File Path | Route / Path | Widget / Class Name | User Role(s) | Entry Point | Main Purpose | Supporting Provider / Controller | States Handled | Reachability | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | **Splash Screen** | `lib/features/splash/splash_screen.dart` | `/splash` | `SplashScreen` | All / Public | Cold start / root entry | Initialized session, checks auth & shared prefs, transitions to onboarding or home | `appSessionProvider`, `AppSessionNotifier` | Loading, Error, Success | Reachable | Complete |
| 2 | **Onboarding Screen** | `lib/features/onboarding/onboarding_screen.dart` | `/onboarding` | `OnboardingScreen` | Unauthenticated / First Launch | First launch redirect / Welcome flow | Introduction to DLD screening, multi-role support, and platform overview | `AppSessionNotifier` | Success, PageView paging | Reachable | Complete |
| 3 | **Welcome Screen** | `lib/features/auth/welcome_screen.dart` | `/welcome` | `WelcomeScreen` | Unauthenticated | Root auth routing / Logout destination | Landing page with Log In, Sign Up, and debug role switcher actions | `AppSessionNotifier` | Success | Reachable | Complete |
| 4 | **Login Screen** | `lib/features/auth/login_screen.dart` | `/login` | `LoginScreen` | Unauthenticated | Welcome screen ("Log In" button) | Email/password authentication, validation, error display | `AuthRepository`, `AppSessionNotifier` | Loading, Error, Success, Validation | Reachable | Complete |
| 5 | **Sign Up Screen** | `lib/features/auth/sign_up_screen.dart` | `/sign-up` | `SignUpScreen` | Unauthenticated | Welcome screen ("Sign Up" button) | Account registration with role selection (Parent, Teacher, Specialist, Adult) and consent checkboxes | `AuthRepository`, `AppSessionNotifier` | Loading, Error, Success, Validation | Reachable | Complete |
| 6 | **Verify Email Screen** | `lib/features/auth/verify_email_screen.dart` | `/verify-email` | `VerifyEmailScreen` | Unauthenticated / Unverified | Auth redirect when email not verified | Email verification status polling, resend OTP/link, auto-poll | `AuthRepository` | Loading, Polling, Success, Error | Reachable | Complete |
| 7 | **Forgot Password Screen** | `lib/features/auth/forgot_password_screen.dart` | `/forgot-password` | `ForgotPasswordScreen` | Unauthenticated | Login screen ("Forgot Password?") | Password reset email trigger | `AuthRepository` | Loading, Success, Error | Reachable | Complete |
| 8 | **Role Setup Screen** | `lib/features/role_setup/role_setup_screen.dart` | `/role-setup` | `RoleSetupScreen` | Authenticated (Needs Profile) | Post-signup / profile-missing redirect | Role selection and profile bootstrap configuration | `ProfileRepository` | Loading, Success, Error | Reachable | Complete |
| 9 | **Profile Form Screen** | `lib/features/role_setup/profile_form_screen.dart` | `/role-setup/form` | `ProfileFormScreen` | Authenticated (Needs Profile) | Role setup screen | Detailed role-specific profile configuration (children, institution, credentials) | `ProfileRepository` | Loading, Validation, Success, Error | Reachable | Complete |
| 10 | **Parent Home Screen** | `lib/features/parent/parent_home_screen.dart` | `/parent` | `ParentHomeScreen` | Parent | Post-authentication redirect / session init | Main parent dashboard with 5 tabs (Home, Practise, Learn, Tools, Profile) | `ActivityProvider`, `ScreeningProvider`, `ProfileRepository` | Loading, Empty, Error, Success | Reachable | Complete |
| 11 | **Teacher Home Screen** | `lib/features/teacher/teacher_home_screen.dart` | `/teacher` | `TeacherHomeScreen` | Teacher | Post-authentication redirect | Teacher dashboard with student roster, classroom supports, observation logs | `ProfileRepository`, `Observation` providers | Loading, Empty, Error, Success | Reachable | Complete |
| 12 | **Adult Home Screen** | `lib/features/adult/adult_home_screen.dart` | `/adult` | `AdultHomeScreen` | Adult | Post-authentication redirect | Adult self-management dashboard, personal journal, workplace scripts | `ActivityProvider`, `LocalStore` | Loading, Empty, Error, Success | Reachable | Complete |
| 13 | **Specialist Home Screen** | `lib/features/specialist/specialist_home_screen.dart` | `/specialist` | `SpecialistHomeScreen` | Specialist | Post-authentication redirect | Specialist caseload dashboard, verification status banner, quick actions | `ClinicalAssessmentRepository`, `ProfileRepository` | Loading, Unverified Banner, Error, Success | Reachable | Complete |
| 14 | **Specialist Assessments Screen** | `lib/features/specialist/specialist_assessments_screen.dart` | `/specialist/assessments` | `SpecialistAssessmentsScreen` | Specialist | Specialist Dashboard ("Clinical Assessments" button) | Full-screen wrapper for clinical assessment battery (CELF-5, CCC-2, SRS-2) | `ClinicalAssessmentRepository` | Loading, Locked, Active Form, Success | Reachable | Complete |
| 15 | **Screening Intro Screen** | `lib/features/screening/screening_intro_screen.dart` | `/screening/intro` | `ScreeningIntroScreen` | Parent, Teacher, Adult | Dashboard CTA / Screening launcher | Explains screening tool scope, age bands, and estimated time | `ScreeningRepository` | Loading, Success | Reachable | Complete |
| 16 | **Screening Question Screen** | `lib/features/screening/screening_question_screen.dart` | `/screening/questions` | `ScreeningQuestionScreen` | Parent, Teacher, Adult | Screening intro ("Start Screening") | Interactive questionnaire with scoring engine and validation | `ScoringEngine`, `ScreeningRepository` | Loading, Question Navigation, Validation, Success | Reachable | Complete |
| 17 | **Screening Report Screen** | `lib/features/screening/screening_report_screen.dart` | `/screening/report` | `ScreeningReportScreen` | Parent, Teacher, Adult, Specialist | Screening completion | Detailed screening results, risk level breakdown, clinical recommendations, PDF export | `ExportService`, `SummaryBuilder` | Loading, Success, Export | Reachable | Complete |
| 18 | **Screening History Screen** | `lib/features/screening/screening_history_screen.dart` | `/screening/history` | `ScreeningHistoryScreen` | Parent, Teacher, Specialist | Dashboard history tab | Historical screening logs and progress tracking | `ScreeningRepository` | Loading, Empty, Success | Reachable | Complete |
| 19 | **Activities Home Screen** | `lib/features/activities/activities_home_screen.dart` | Embedded / Tab view | `ActivitiesHomeScreen` | Parent, Teacher, Adult | Parent/Teacher/Adult Practise tab | Daily language practice plans and categorized exercises | `ActivityProvider`, `DailyPlanGenerator` | Loading, Empty, Success | Reachable | Complete |
| 20 | **Activity Detail Screen** | `lib/features/activities/activity_detail_screen.dart` | Embedded view | `ActivityDetailScreen` | Parent, Teacher, Adult | Activity card tap | Detailed overview, instructions, and target goals for selected activity | `ActivityProvider` | Loading, Success | Reachable | Complete |
| 21 | **Activity Player Screen** | `lib/features/activities/activity_player_screen.dart` | Embedded view | `ActivityPlayerScreen` | Parent, Teacher, Adult | Activity detail ("Start Activity") | Interactive child/adult practice exercise player with audio cues | `ActivityProvider`, `AudioPlayer` | Loading, Interactive Steps, Success | Reachable | Complete |
| 22 | **Activity Wrap-Up Screen** | `lib/features/activities/activity_wrap_up_screen.dart` | Embedded view | `ActivityWrapUpScreen` | Parent, Teacher, Adult | Activity completion | Session summary, rating, and progress aggregation | `ProgressAggregator` | Success, Rating Form | Reachable | Complete |
| 23 | **Progress Dashboard Screen** | `lib/features/activities/progress_dashboard_screen.dart` | Embedded view | `ProgressDashboardScreen` | Parent, Teacher, Specialist | Dashboard progress tab | Visual analytics of practice consistency, goal progress, and score trends | `ProgressAggregator` | Loading, Empty, Success | Reachable | Complete |
| 24 | **Learn Home Screen** | `lib/features/learn/learn_home_screen.dart` | Embedded / Tab view | `LearnHomeScreen` | Parent, Teacher, Adult, Specialist | Learn tab on dashboards | Educational article library, DLD vs temporal delay guides, myths vs facts | `ContentRepository` | Loading, Empty, Success | Reachable | Complete |
| 25 | **Article Reader Screen** | `lib/features/learn/article_reader_screen.dart` | Embedded view | `ArticleReaderScreen` | All roles | Learn article card tap | Full-screen Markdown article viewer with medical disclaimers | `ContentRepository` | Loading, Success, Disclaimer | Reachable | Complete |
| 26 | **Tools Hub Screen** | `lib/features/tools/tools_hub_screen.dart` | `/tools` | `ToolsHubScreen` | All roles | Dashboard tools card / Learn banner | Hub for assistive tools (Visual Schedule, Simplifier, Cards, Journal) | `LocalStore` | Success | Reachable | Complete |
| 27 | **Visual Schedule Screen** | `lib/features/tools/visual_schedule_screen.dart` | Embedded view | `VisualScheduleScreen` | Parent, Teacher, Adult | Tools Hub ("Visual Schedule") | Interactive morning/evening routine planner with reorderable items | `LocalStore` | Loading, Empty (Reset), Success | Reachable | Complete |
| 28 | **Instruction Simplifier Screen** | `lib/features/tools/instruction_simplifier_screen.dart` | Embedded view | `InstructionSimplifierScreen` | Parent, Teacher, Adult | Tools Hub ("Instruction Simplifier") | NLP-informed instruction parser breaking complex sentences into steps | Simplifier Engine | Empty, Processing, Success | Reachable | Complete |
| 29 | **Communication Card Screen** | `lib/features/tools/communication_card_screen.dart` | Embedded view | `CommunicationCardScreen` | Parent, Teacher, Adult | Tools Hub ("Communication Cards") | AAC-style visual and text communication cue cards with TTS | `LocalStore` | Grid View, Fullscreen Dialog | Reachable | Complete |
| 30 | **Adult Journal Screen** | `lib/features/tools/adult_journal_screen.dart` | Embedded view | `AdultJournalScreen` | Adult | Adult Dashboard ("Journal") | Daily cognitive load and workplace communication log | `LocalStore` | Empty, Entry Form, Success | Reachable | Complete |
| 31 | **Export Summary Screen** | `lib/features/export/export_summary_screen.dart` | `/export` | `ExportSummaryScreen` | Parent, Teacher, Specialist | Report screen ("Export PDF/Summary") | Summary compilation and PDF generation for clinical sharing | `ExportService`, `PdfRenderer` | Loading, Success, Share/Download | Reachable | Complete |
| 32 | **Sharing Management View** | `lib/features/sharing/sharing_management_view.dart` | Embedded view | `SharingManagementView` | Parent, Teacher, Specialist | Dashboard sharing tab | Access control, active invites, and audit logs | `SharingRepository` | Loading, Empty, Success | Reachable | Complete |
| 33 | **Accept Invite Screen** | `lib/features/sharing/accept_invite_screen.dart` | Embedded view | `AcceptInviteScreen` | Parent, Teacher, Specialist | Deep link / invite code entry | Accepting collaboration invites from specialists/teachers | `SharingRepository` | Loading, Validation, Success, Error | Reachable | Complete |
| 34 | **Settings Screen** | `lib/features/settings/settings_screen.dart` | `/settings` | `SettingsScreen` | All authenticated roles | Dashboard profile/settings icon | App preferences, dark mode, animations toggle, research consents, sign out | `AppSessionNotifier`, `SharedPreferences` | Success | Reachable | Complete |
| 35 | **Privacy Policy Screen** | `lib/features/settings/privacy_policy_screen.dart` | `/privacy-policy` | `PrivacyPolicyScreen` | All (Public) | Sign Up screen / Settings | DPDP Act 2023 compliant privacy policy and data handling details | Static Content | Success | Reachable | Complete |
| 36 | **Terms of Service Screen** | `lib/features/settings/terms_of_service_screen.dart` | `/terms-of-service` | `TermsOfServiceScreen` | All (Public) | Sign Up screen / Settings | Platform terms of use and liability limitations | Static Content | Success | Reachable | Complete |
| 37 | **Research Consents Screen** | `lib/features/settings/research_consents_screen.dart` | Embedded view | `ResearchConsentsScreen` | Parent, Teacher, Specialist, Adult | Settings screen ("Research Consents") | Informed consent management, data anonymization choices, withdrawal log | `ResearchConsentRepository` | Loading, Toggle State, Success | Reachable | Complete |
| 38 | **FAQ Screen** | `lib/features/settings/faq_screen.dart` | Embedded view | `FAQScreen` | All authenticated roles | Settings screen ("FAQ & Support") | Frequently asked questions about DLD and app features | Static Content | Success | Reachable | Complete |
| 39 | **About Screen** | `lib/features/settings/about_screen.dart` | Embedded view | `AboutScreen` | All authenticated roles | Settings screen ("About LinguaCare") | Version information, credits, and open-source licenses | Static Content | Success | Reachable | Complete |
| 40 | **Config Error Screen** | `lib/core/errors/config_error_screen.dart` | N/A (Root fallback) | `ConfigErrorScreen` | Public / System | App startup (`main.dart`) when keys missing | Displays fatal configuration error when Supabase URL/Anon Key missing | System bootstrap | Error State | Reachable | Complete |

---

## 3. Route-to-Screen Mapping

```
/splash -> SplashScreen
/onboarding -> OnboardingScreen
/welcome -> WelcomeScreen
/login -> LoginScreen
/sign-up -> SignUpScreen
/verify-email -> VerifyEmailScreen
/forgot-password -> ForgotPasswordScreen
/role-setup -> RoleSetupScreen
/role-setup/form -> ProfileFormScreen (role query param)
/settings -> SettingsScreen
/privacy-policy -> PrivacyPolicyScreen
/terms-of-service -> TermsOfServiceScreen
/tools -> ToolsHubScreen
/parent -> ParentHomeScreen
/teacher -> TeacherHomeScreen
/adult -> AdultHomeScreen
/specialist -> SpecialistHomeScreen
/specialist/assessments -> SpecialistAssessmentsScreen (childId, subjectUid)
/screening/intro -> ScreeningIntroScreen (instrumentId, childId)
/screening/questions -> ScreeningQuestionScreen (instrumentId, childId)
/screening/report -> ScreeningReportScreen (instrumentId, childId)
/screening/history -> ScreeningHistoryScreen (childId, subjectUid)
/export -> ExportSummaryScreen
```

---

## 4. Summary of Screens Grouped by Role

### Public / Unauthenticated
- `SplashScreen` (`/splash`)
- `OnboardingScreen` (`/onboarding`)
- `WelcomeScreen` (`/welcome`)
- `LoginScreen` (`/login`)
- `SignUpScreen` (`/sign-up`)
- `VerifyEmailScreen` (`/verify-email`)
- `ForgotPasswordScreen` (`/forgot-password`)
- `PrivacyPolicyScreen` (`/privacy-policy`)
- `TermsOfServiceScreen` (`/terms-of-service`)
- `ConfigErrorScreen` (System fallback)

### Role-Setup / Profile Bootstrap
- `RoleSetupScreen` (`/role-setup`)
- `ProfileFormScreen` (`/role-setup/form`)

### Parent Role
- `ParentHomeScreen` (`/parent`)
- Activities, Practise, Learn, Tools Hub, Sharing, Settings, Screening, Export

### Teacher Role
- `TeacherHomeScreen` (`/teacher`)
- Student Roster, Observation Logs, Classroom Supports, Tools Hub, Settings, Screening

### Adult Role
- `AdultHomeScreen` (`/adult`)
- Adult Journal, Workplace Scripts, Communication Cards, Tools Hub, Settings, Screening

### Specialist Role
- `SpecialistHomeScreen` (`/specialist`)
- Caseload Management, Clinical Assessments (`/specialist/assessments`), Screening History, Sharing, Settings

---

## 5. Orphan, Duplicate, and Error Routing Analysis
- **Orphan Screens:** None. Every implemented screen is registered in `app_router.dart` or embedded as a tab/view within a parent role dashboard.
- **Duplicate Screens:** None. Component reuse is leveraged via shared widgets (`AuthScaffold`, `PrimaryButton`, `AppTextField`, `ResponsiveScaffold`).
- **Route Errors & Guards:** `AppRouter` implements robust session-based redirection ensuring unauthenticated users cannot access role home screens, unverified emails are intercepted at `/verify-email`, and role mismatches are automatically corrected.
