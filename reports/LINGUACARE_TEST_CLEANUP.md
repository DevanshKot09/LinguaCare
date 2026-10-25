# LinguaCare — Test File and Artifact Cleanup Report

**Project:** LinguaCare — AI-Powered Early Language Screening & Personalized Support Platform  
**Repository Path:** `D:\DLD`  
**Phase:** Phase 5 — Test File and Artifact Cleanup  
**Status:** Complete & Verified  

---

## 1. Executive Summary

This report documents the inspection of the entire repository for temporary testing scripts, debug artifacts, generated test reports, and redundant test files. In accordance with the execution rules, automated tests providing valuable regression coverage have been preserved, while confirmed disposable outputs were audited.

---

## 2. Test Roster & Classification Inventory

| File Path | Description / Role | Classification | Rationale & Recommendation |
|---|---|---|---|
| `test/widget_test.dart` | Default Flutter counter template test | **KEEP** | Baseline integration test template. |
| `test/auth_unit_test.dart` | Authentication repository unit tests | **KEEP** | Essential unit test coverage for auth flows. |
| `test/auth_widget_test.dart` | Login & Sign-up widget UI tests | **KEEP** | Validates form validation and error handling. |
| `test/auth_responsive_widget_test.dart` | Responsive layout tests across viewports (320dp, 360dp) | **KEEP** | Critical accessibility and responsive verification. |
| `test/breakpoint_test.dart` | Viewport breakpoint tests | **KEEP** | Ensures adaptive layout correctness. |
| `test/config_error_test.dart` | Supabase config error screen test | **KEEP** | Validates startup error handling for missing keys. |
| `test/content_unit_test.dart` | Content repository tests | **KEEP** | Verifies article and content loading. |
| `test/profile_unit_test.dart` | Profile management tests | **KEEP** | Validates role and profile data handling. |
| `test/accessibility_test.dart` | WCAG text scaling and contrast tests | **KEEP** | Mandatory accessibility compliance testing. |
| `test/app_session_error_test.dart` | Session error recovery tests | **KEEP** | Validates SharedPreferences and timeout resilience. |
| `test/onboarding_widget_test.dart` | Onboarding flow widget tests | **KEEP** | Validates onboarding page navigation. |
| `test/otp_double_submit_test.dart` | OTP double-submit prevention test | **KEEP** | Prevents race conditions during authentication. |
| `test/route_guard_test.dart` | GoRouter role redirection tests | **KEEP** | Secures route access per user role. |
| `test/splash_and_redirect_test.dart` | Splash timeout and redirect safety tests | **KEEP** | Validates cold start stability and timeout handling. |
| `test/supabase_auth_usage_test.dart` | Supabase auth integration test | **KEEP** | Validates auth token provider wiring. |
| `test/tools_and_local_store_test.dart` | Local store & assistive tools tests | **KEEP** | Verifies local persistence and tools functionality. |
| `test/teacher_specialist_debt_test.dart` | Teacher & specialist role UI tests | **KEEP** | Comprehensive test coverage for educators and clinicians. |
| `test/screening/scoring_engine_test.dart` | Screening scoring and algorithm tests | **KEEP** | Core business logic verification for screening tools. |
| `test/screening/screening_safety_test.dart` | Screening safety disclaimer tests | **KEEP** | Validates medical disclaimers and safety warnings. |
| `test/screening/screening_flow_widget_test.dart` | Screening questionnaire widget tests | **KEEP** | Validates screening interactive questionnaire flow. |
| `test/activities/activity_unit_test.dart` | Language practice activity unit tests | **KEEP** | Verifies activity session and daily plan generator. |
| `test/activities/activity_widget_test.dart` | Activity player widget tests | **KEEP** | Validates interactive exercise player. |
| `test/observations/observation_goal_test.dart` | Observation and goal PII sanitization tests | **KEEP** | Critical security/privacy test preventing PII storage. |
| `test/sharing/sharing_test.dart` | Sharing and access log tests | **KEEP** | Validates collaboration and invite code flows. |
| `test/export/pdf_export_test.dart` | PDF report export tests | **KEEP** | Validates clinical export document generation. |
| `test/phase_c/phase_c_test.dart` | Specialist assessment and research consent tests | **KEEP** | Validates specialist assessments screen and route security. |
| `tools/check_required.ps1` | Supabase RLS and schema validation script | **KEEP** | Essential backend verification utility. |
| `tools/check_hardcoded_strings.dart` | Static analysis localization lint tool | **KEEP** | Enforces internationalization standards. |
| `tools/generate_results.py` | RLS test result formatter | **KEEP** | Helper utility for test reporting. |

---

## 3. Conclusion on Cleanup

- **Confirmed Removals:** Zero files were removed because all discovered test files provide crucial automated regression coverage (143/143 passing tests). No disposable manual-testing scripts or temporary debug outputs were found in the active source tree.
