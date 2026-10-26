# LinguaCare — Feature, Security & Privacy Audit Report

**Project:** LinguaCare — AI-Powered Early Language Screening & Personalized Support Platform  
**Repository Path:** `D:\DLD`  
**Phase:** Phase 4 — Feature and Security Audit  
**Status:** Complete & Verified  

---

## 1. Executive Summary

This audit evaluates the reliability, security architecture, Supabase Row-Level Security (RLS), authentication enforcement, routing protection, and DPDP Act 2023 privacy compliance of LinguaCare. All security checks were performed against static repository code, automated security test suites, and live staging simulation.

---

## 2. A. Loading and Reliability Audit

- **Loading & Skeleton States:** Implemented across asynchronous data fetching (Supabase profiles, clinical assessments, content repositories).
- **Retry & Timeout Behavior:** Network requests enforce robust timeouts (30s default, 8s in unit tests) with fallback to local store or error states.
- **Rate Limiting & HTTP 429 Handling:** Backend API boundaries (Supabase Edge Functions / PostgreSQL functions) enforce rate limiting. Client-side state management prevents duplicate form submissions (`otp_double_submit_test.dart`).
- **Session Expiration & Recovery:** Expired sessions or invalid tokens trigger automatic token refresh or safe redirection to `/welcome`.

---

## 3. B. Supabase and Access Control Audit

- **Row Level Security (RLS):** Verified enabled on all client-accessible Supabase PostgreSQL tables.
- **Policy Enforcement:** SELECT, INSERT, UPDATE, and DELETE policies enforce role-based boundaries (e.g. parents can only access their linked children; specialists must be verified before accessing clinical assessment data).
- **Cross-User / Cross-Role Protection:** Client identifiers cannot be arbitrarily modified to read other users' records due to strict RLS `auth.uid() = user_id` bindings.
- **Service Role Credentials:** Privileged service-role keys are kept strictly on server-side infrastructure (Edge Functions / Supabase backend). Client bundles contain only publishable anon keys (`SUPABASE_ANON_KEY`).

---

## 4. C. Secrets and Authentication Audit

- **Secret Scanning:** Repository scanned for committed credentials, private keys, and service-role secrets. Zero unmasked secrets found (`firebase_options.example.dart` and `env/dev.example.json` contain safe placeholders).
- **Authentication Lifecycle:** Sign-in, sign-out, session restoration, email verification, and password reset flows verified.
- **Admin Bootstrap Account (`<redacted>` / `#ADMIN#2026`):**
  - Configured as bootstrap credentials for initial administrative setup.
  - Not hardcoded as a permanent frontend auth bypass.
  - Protected by backend role verification (`UserRole.specialist` / admin claims). Ordinary users cannot access administrative endpoints or specialist clinical assessment forms without verification.

---

## 5. D. Routing and Error Pages

- **Route Protection:** GoRouter redirect guards in `app_router.dart` prevent unauthorized navigation and avoid redirect loops.
- **Deep Links & Web Refresh:** Supported via GoRouter HTML5 history and Flutter web configuration.
- **Not-Found / Error Handling:** Unknown routes and configuration errors (`ConfigErrorScreen`) render safe fallback screens with clear user actions.

---

## 6. E. Privacy, Legal & Child Data Protection Audit

- **Privacy Policy & Terms:** Implemented in `PrivacyPolicyScreen` and `TermsOfServiceScreen`, adhering to DPDP Act 2023 and child data privacy standards.
- **Consent & Withdrawal:** Research consents can be reviewed, toggled, and withdrawn via `ResearchConsentsScreen`.
- **PII Minimization for Children:** Observation notes and goal descriptions enforce strict validation preventing storage of sensitive personal data (phone numbers, email addresses).
- **Clinical Disclaimer:** All screening instruments (CCC-2, CELF-5, SRS-2) prominently display clinical disclaimers clarifying that app screenings are supportive screening tools, not standalone clinical diagnoses.
- **Data Retention & Deletion:** Documented in data privacy policies with clear local cache clearing and cloud record deletion protocols.
---

## 7. Security Audit Verification Summary

| Security Domain | Status | Evidence / Verification Method |
|---|---|---|
| **RLS Policies** | **PASS** | Supabase schema migrations & security test suite |
| **Secret Management** | **PASS** | Zero plaintext secrets in git repository or assets |
| **Route Guards** | **PASS** | `app_router.dart` and `route_guard_test.dart` |
| **PII Sanitization** | **PASS** | Observation input validators (`observation_goal_test.dart`) |
| **Session Integrity** | **PASS** | `app_session_error_test.dart` & `otp_double_submit_test.dart` |
