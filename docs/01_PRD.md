# 01 · Product Requirements Document (PRD)

**Working name:** LinguaCare (placeholder) · **Platforms:** Android + iOS · **Build tool:** Android Studio (Flutter)

## 1. Vision
A supportive, non-diagnostic companion app for people affected by **Developmental Language Disorder (DLD)**: it helps Parents, Teachers, Adults (18+) and Speech-Language Specialists screen for concerns, practise language skills, share progress, and collaborate.

## 2. Problem
- DLD is common but under-recognised; children who compensate well are missed.
- Parents, teachers and therapists work in silos; home/school carry-over of therapy is weak.
- Families in underserved areas lack access to assessment and affordable support.

## 3. Goals
1. Early awareness, **screening, risk flagging and language-area profiling** (see `13`) with clinician-confirmed outcomes.
2. **Learn from consented, specialist-confirmed cases** to improve screening accuracy (see `14`).
3. Daily, short, evidence-informed language activities.
4. Objective progress tracking shared with authorised people.
5. Role-specific tools for Specialist, Adult, Parent, Teacher.
6. Free-tier infrastructure, works on all screen sizes, partly offline.

## 4. Non-goals
- **No autonomous medical diagnosis.** The app screens, profiles language areas and refers; only a qualified clinician confirms DLD (see `13`). It does not replace professional care.
- No ads, no selling of data.
- No real-time video therapy in v1.

## 5. Roles (summary — details in `03_Roles_Permissions.md`)
| Role | Who | Core value |
|---|---|---|
| Specialist | SLP / speech-language therapist | Manage caseload, set goals, review progress |
| Adult (18+) | Adult with DLD / self-user | Self-practice, communication-needs card |
| Parent | Child 5–11 or 11–18 (two child bands) | Screening checklist, home activities, sharing |
| Teacher | Classroom/SEN teacher | Observation logs, accommodations, strategies |

## 6. Core Feature Modules
1. **Learn** – DLD education library (what it is, signs, causes/myths, school strategies).
2. **Screen** – 3-level pipeline: questionnaire → in-app child tasks → specialist confirmation. Output: risk level + domain profile + "also check" flags (not a diagnosis). See `13`.
3. **Practise** – activity engine: vocabulary, grammar, narrative, understanding instructions, conversation, confidence.
4. **Track** – progress dashboard, communication journal, goal tracker.
5. **Collaborate** – invite/link Parent–Teacher–Specialist, shared summaries, notes.
6. **Support Tools** – visual schedules, communication-needs card, instruction simplifier, reminders.
7. **Community & Access** – low-cost resources, multilingual/culturally responsive content, offline packs.
8. **Settings & Privacy** – consent, data export/delete, accessibility options.

## 7. Success Metrics
- Onboarding completion ≥ 70%; Day-7 retention ≥ 25%.
- ≥ 3 activity sessions/week per active child profile.
- ≥ 40% of parents link a teacher or specialist within 30 days.
- Crash-free sessions ≥ 99.5%.

## 8. Open Decisions (need your answer)
1. Your source questions contain a large **preschool (<5) block** (Q101–1000), but Parent bands are 5–11 and 11–18. Add a **3–5 band**, or re-frame as "early signs" content only?
2. Languages at launch (English only vs English + Hindi/Urdu)?
3. Will a licensed SLP review all clinical content before release? (strongly recommended)
4. Specialist verification: manual approval or licence-number check?

## 9. v2 Changes (this update)
- Added screening/differential pipeline (`13`) and AI/ML plan (`14`).
- Added internal **Admin/Clinical Reviewer** role (not public sign-up) in `03`.
- Added research-consent, clinical-label and ML tables in `07` addendum.
- Added ML data governance in `11`; roadmap phases updated in `10`.
