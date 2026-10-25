# LinguaCare (DLD) - Architecture & System Design

## 1. Architectural Overview
LinguaCare is structured using a **Feature-First Clean Architecture** in Flutter (Dart), separating concerns into presentation, domain, and data layers:
- `lib/app/`: App-level routing (`go_router`), global session management (`AppSessionNotifier`), and themes (`AppTheme`, `AppColors`).
- `lib/core/`: Core shared utilities, LocalStore, error screens, and responsive layout builders (`ResponsiveScaffold`, breakpoints).
- `lib/data/`: Data sources, Supabase repositories (`supabase_clinical_assessment_repository`, `supabase_research_consent_repository`, `supabase_profile_repository`, `supabase_sharing_repository`, `screening_repository_impl`, `activity_repository_impl`, `content_repository_impl`), and Firebase auth repository.
- `lib/domain/`: Entities, repository interfaces, scoring engines, and Riverpod state providers.
- `lib/features/`: Feature modules (auth, onboarding, role_setup, parent, teacher, adult, specialist, activities, screening, learn, observations, goals, tools, sharing, export, settings).

## 2. State Management & Dependency Injection
- **Riverpod:** Used exclusively for reactive state management, dependency injection, and business logic separation (`Provider`, `FutureProvider`, `StreamProvider`, `StateNotifierProvider`).
- **AppSession:** Manages authentication lifecycle, role resolution, onboarding status, and profile loading with automatic redirect guards preventing redirection loops.

## 3. Backend & Security Architecture
- **Firebase Auth:** Handles secure user authentication (Email/Password, Google Sign-In) with SHA-1/SHA-256 fingerprint validation and robust exception mapping.
- **Supabase (PostgreSQL & Edge Functions):**
  - **Row Level Security (RLS):** Enabled on every database table. Client queries are strictly restricted by user ownership or active parental sharing links (`links` table).
  - **Secure RPCs:** Sensitive mutations (invites, sharing, clinical assessments, research consents) are executed via SECURITY DEFINER PostgreSQL functions with explicit `search_path = public` and authorization checks using `(auth.jwt()->>'sub')`.
  - **OTP Authentication:** Edge Function (`send-otp`) handles secure email delivery over SMTP port 465 with cryptographic code hashing (`OTP_PEPPER`).

## 4. Responsive & Accessibility Architecture
- **Responsive Layouts:** Implements compact (<600dp), medium (600–839dp), and expanded (≥840dp) layouts using `ResponsiveScaffold`, switching seamlessly between bottom navigation bars and navigation rails.
- **Accessibility & Inclusion:** Complies with Android accessibility guidelines (`androidTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline`), supporting text scaling up to 200%, screen readers, and reduce-motion settings.

## 5. Local Data Persistence & Privacy
- **Namespaced Local Store:** `LocalStore` strictly namespaces all local JSON storage keys by `userId` (`linguacare_${userId}_$key`) to prevent data cross-contamination.
- **Android Auto Backup Isolation:** `android:allowBackup="false"` in `AndroidManifest.xml` ensures sensitive local tool and journal data are excluded from Google Cloud Auto Backup, reinforcing strict data privacy compliance (DPDP Act 2023).
