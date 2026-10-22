# 03 · Roles, Permissions & Feature Matrix

## 1. Roles
1. **Specialist** – speech-language therapist/pathologist.
2. **Adult (18+)** – self-user with DLD (or exploring).
3. **Parent** – manages one or more **child profiles**, each tagged **5–11** or **11–18**.
4. **Teacher** – manages **students** (linked via parent consent).

> Role is chosen at sign-up, stored in `profiles.role`, enforced by Supabase RLS (never trust the client).

## 2. Feature Matrix
| Feature | Specialist | Adult | Parent | Teacher |
|---|:-:|:-:|:-:|:-:|
| Learn library | ✔ | ✔ | ✔ | ✔ |
| Screening checklist | review only | self-reflection | ✔ (child) | ✔ (observation) |
| Practice activities | assign/preview | ✔ | ✔ (child plays) | preview |
| Progress dashboard | caseload | own | own children | linked students |
| Goal setting | ✔ (author) | ✔ (personal) | suggest | suggest |
| Observation log | ✔ | journal | journal | ✔ |
| Communication-needs card | review | ✔ create | ✔ create for child | view |
| Visual schedule builder | ✔ | ✔ | ✔ | ✔ |
| Instruction simplifier | ✔ | – | ✔ | ✔ |
| Invite / link people | ✔ | ✔ | ✔ | request link |
| Export/share summary (PDF) | ✔ | ✔ | ✔ | ✔ (limited) |
| Verification required | ✔ (licence) | – | – | ✔ (school email, optional) |

## 3. Child-band behaviour (Parent role)
| Band | UI tone | Activity style | Child-facing UI |
|---|---|---|---|
| 5–11 | playful, illustrated, large targets, voice prompts | games, picture-word, story-sequencing | Yes, parent-gated "Kid Mode" |
| 11–18 | calm, minimal, teen-appropriate, user-controlled | scenarios, conversation practice, vocabulary in context | Optional "Teen Mode" with own privacy controls |

## 4. Consent & Linking Rules
- A teacher/specialist only sees a child's data **after parent approves an invite** (scoped: progress only / progress + notes).
- Teens 11–18: show a teen-friendly assent screen; parent can still manage.
- Parent can revoke access any time → instant RLS effect.
- Specialist notes marked `private` are never visible to others.

---
# v2 UPDATE – Detailed Role Responsibilities

## Parent
**Does:** creates child profiles · fills screening questionnaire · plays Level-2 tasks with child · runs daily activities · logs progress/observations · reads the Language Profile Report · invites teacher/specialist and **controls what they see** · gives/withdraws research consent · books/finds a specialist · exports reports.
**Cannot:** see other families' data · change clinical labels.

## Teacher
**Does:** fills teacher screening version for linked students · adds classroom observations · uses accommodation & strategy library (visual schedules, simplified instructions, pre-taught vocabulary) · tracks classroom participation · shares notes with parent/specialist · follows specialist-set goals.
**Cannot:** access a child without parent approval · see private specialist notes · diagnose or label.

## Specialist (SLP / speech-language therapist)
**Does:** receives referrals/reports · runs/records the **formal assessment** · enters the **confirmed outcome** (the gold label) · sets personalised goals · assigns activities · reviews home/school data · gives feedback to parents/teachers · manages caseload · reviews AI suggestions (decision support) · may contribute reviewed content.
**Needs:** verification (licence) before clinical features unlock.
**Cannot:** see unlinked children · export identifiable data outside permitted scope.

## Adult (18+)
**Does:** self-screening questionnaire (adult version) · practice exercises (conversation, idioms, narrative, vocabulary) · journal of tricky situations · builds "My communication card" · shares summary with a specialist (optional) · research consent (optional).
**Cannot:** access other users' data.

## Admin / Clinical Reviewer (INTERNAL – not shown at sign-up)
**Does:** verifies specialists · approves content after SLP review · manages ethics/consent versions · oversees de-identified research export · handles data-deletion requests · monitors model performance.
**Access:** no routine access to identifiable child data; every access is audit-logged.

## Updated Permission Additions
| Capability | Specialist | Adult | Parent | Teacher | Admin |
|---|:-:|:-:|:-:|:-:|:-:|
| Enter confirmed clinical outcome | ✔ | – | – | – | – |
| View AI risk suggestion | ✔ | – | – | – | ✔ |
| Give research consent | – | ✔ | ✔ (child) | – | – |
| Approve content / verify specialist | – | – | – | – | ✔ |
| Run de-identified research export | – | – | – | – | ✔ (with ethics approval) |
