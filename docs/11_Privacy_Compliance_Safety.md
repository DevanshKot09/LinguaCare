# 11 · Privacy, Compliance & Clinical Safety

> Not legal advice — have a lawyer review before launch.

## 1. Data Classification
| Data | Sensitivity | Rule |
|---|---|---|
| Child name/DOB/concerns | High (child health-adjacent) | minimal, nickname allowed, encrypted at rest |
| Screening answers, observations | High | RLS-scoped, parent-controlled sharing |
| Voice clips | High | **opt-in only**, short retention, prefer on-device |
| Email/auth | Medium | Firebase-managed |
| Usage analytics | Low | anonymous, no child PII |

## 2. Principles
Data minimisation · purpose limitation · parental consent for children · teen assent (11–18) · no ads/no data sales · export & delete on request · transparent policy in plain language.

## 3. Regulatory Checklist (verify applicability by target market)
- India: **DPDP Act 2023** (verifiable parental consent for children's data).
- US: COPPA (under 13), possibly HIPAA if serving covered entities. EU/UK: GDPR / UK Children's Code.
- App stores: Apple Kids/Privacy labels, Google Play Families & Data safety form.

## 4. Technical Controls (Hardened in Phase 4A/4B)
TLS everywhere · RLS on all tables · secrets in server only · audit log for access to child data (`access_audit` de-duplicated) · invite code hashing (SHA-256 + salt) · zero direct client table access for members to children, screening, activities, observations, or goals (enforced via SECURITY DEFINER RPCs re-checking active links on every call) · private observation protection · phone/email pattern validation on observation notes · session timeout/app-lock · scheduled purge of expired OTP/voice data · backups.

## 5. Clinical Safety
- Disclaimer on onboarding, screening, results, and Settings.
- No diagnosis language; use *"signs that may be worth discussing with a professional"*.
- Escalation copy for urgent concerns (regression, hearing issues, safety) → "see a professional".
- Content governance: author → SLP reviewer → approve → publish; show "Reviewed by / date".
- Avoid stigmatising or blaming language (caregivers, environment).

## 6. Research/Ethics (if analytics or studies added later)
Separate opt-in, plain-language consent + child assent, diverse recruitment, fair cross-language comparison, no re-identification.

---
# v2 UPDATE – ML Data Governance
- **Two-key consent:** (1) app use, (2) separate research/AI-training consent (scopes: questionnaire / tasks / audio / clinical label). Declining never limits app features.
- Child assent screens (teen-friendly language for 11–18; simple picture assent for 5–11).
- Research data held in a **separate store**, pseudonymised, age in months instead of DOB, region instead of address.
- Audio: opt-in only, encrypted, feature extraction then delete raw clips on a fixed schedule.
- Ethics committee approval + legal review (DPDP Act 2023; COPPA/GDPR if applicable) **before** any export for training.
- Withdrawal honoured: excluded from future training; delete from active datasets where feasible; document limits (already-trained models).
- **Regulatory check:** features that output diagnostic claims may count as medical-device software. Keep language as "screening/decision support" until legally cleared.
- Publish a plain-language "How we use your data" page and model cards.
- Incident response plan and breach notification process.

## 7. Local Data Privacy & Cloud Backup Decision (Phase 6A)
- **Local Store Namespacing:** `LocalStore` strictly namespaces keys by signed-in user id (`linguacare_${userId}_$key`), ensuring no data cross-contamination between users.
- **Zero Email Storage in Local Store:** Local tool data (schedules, journal entries, communication cards) never stores user emails or UIDs.
- **Account Deletion:** Account deletion explicitly calls `clearAllForUser()`, wiping all local device data for that user.
- **Android Auto Backup Disabled (`android:allowBackup="false"`):** To ensure complete user privacy and DPDP Act compliance, local app data is excluded from Google Cloud Auto Backup. Trade-off: if a user uninstalls or switches devices without exporting, local-only tool data stored in SharedPreferences is not automatically restored.

