# Research Data Policy - LinguaCare

## Overview
LinguaCare supports academic and clinical research on Developmental Language Disorder (DLD) while adhering to strict privacy, ethics, and regulatory standards (including DPDP Act 2023 and GDPR principles).

## Key Principles & Protections
1. **Opt-In Only**: Research consent defaults to **OFF**. Declining or withdrawing consent never limits any app features or services.
2. **No Automatic Exports**: Data is never exported automatically. Exports require formal ethics approval, legal review, and explicit administrative authorization.
3. **Pseudonymization**: Identifiers (UID, name, nickname, date of birth, email, notes, free text, home languages, interests, concerns) are strictly excluded. Records are pseudonymized using SHA-256 with a secure server-side salt (`research_settings.salt`).
4. **Withdrawal Honored**: Withdrawing consent appends a `granted = false` record. The export view `research_export_v1` evaluates only the latest consent row per participant, instantly excluding withdrawn participants from future exports.
5. **Scope Limitations**: Scopes are strictly limited to `questionnaire`, `tasks`, and `clinical_label`. **Audio recordings are excluded in v1**.
6. **Adolescent Assent**: For participants in the 11–18 age band, verified child assent (`child_assent = true`) is mandatory.
