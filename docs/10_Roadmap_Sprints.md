# 10 · Roadmap & Sprint Plan

## Phase 0 – Discovery (1 wk)
Resolve open decisions (PRD §8) · SLP advisor engaged · wireframes (27 screens) · brand tokens.

## Phase 1 – Foundation (2 wks)
Flutter project, flavors, CI · theme + responsive kit · router + guards · Firebase + Supabase projects · schema + RLS · splash + onboarding.

## Phase 2 – Auth & Profiles (2 wks)
Email/password · OTP Edge Functions + SMTP · Google sign-in · reset password · role select + 4 profile setups · child profiles · consent screens.

## Phase 3 – Core MVP (4 wks)
Learn library · Parent screening + results · activity engine (3 domains first: vocabulary, comprehension, narrative) · progress dashboard · reminders.

## Phase 4 – Collaboration (3 wks)
Invite/link/scope · Teacher observations + strategies · Specialist caseload/goals · PDF share/export.

## Phase 5 – Adult & Tools (2 wks)
Adult journal + comm card · visual schedule builder · instruction simplifier · offline packs.

## Phase 6 – Hardening & Release (3 wks)
Accessibility audit · device matrix tests · security review · privacy policy/terms · store listings (Play + App Store) · beta (TestFlight / Play internal).

## MVP Cut (if time-limited)
Auth + roles + Parent flow (screen → practise → progress) + Learn library. Teacher/Specialist/Adult light versions next.

## Risks
| Risk | Mitigation |
|---|---|
| Clinical content accuracy | SLP review, citations, versioning |
| Supabase free-tier pausing/limits | keep-alive job, monitor usage, upgrade path |
| iOS build needs Mac | Codemagic/GitHub macOS runners |
| OTP email deliverability | SPF/DKIM on sender domain, SMTP/Resend |
| Child data regulation | data minimisation, parental consent, deletion |
| Speech recognition on atypical speech | don't auto-grade; caregiver-rated outcomes in v1 |

---
# v2 UPDATE – Screening & AI Track (runs alongside app phases)
| Track phase | Work | Gate |
|---|---|---|
| S1 (with Phase 3) | Rule-based Level-1 questionnaires, risk + profile report, referral flow | SLP sign-off on items & wording |
| S2 (Phase 4) | Level-2 child tasks; Specialist **confirmed-outcome** entry; research-consent flow | Ethics approval |
| S3 (post-MVP) | Collect consented, de-identified data **with controls**; build baseline ML (logistic/GBM) offline | Min. labelled dataset + subgroup coverage |
| S4 | Shadow-mode in app; compare to specialist outcomes | Sensitivity/specificity targets met, no subgroup gaps |
| S5 | Release as "decision support" with model card; ongoing monitoring | Legal/regulatory clearance |
**Partnerships:** hospital/university SLP department for labels, validation and ethics.
