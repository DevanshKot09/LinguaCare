# SLP Review Pack: Screening Instruments & Activity Engine

> **Confidential / Clinical Review Document**  
> **Project:** LinguaCare (DLD Support App)  
> **Version:** Phase 3C v1.0.0 (Draft Status)

---

## 1. Clinical Disclaimer & Purpose
The screening instruments and practice activities implemented in Phase 3B/3C are preliminary screening and evidence-informed practice tools designed to support communication growth.  
**Crucial Rule:** The app **never diagnoses**. All result wordings use non-stigmatising phrasing. All items, activities, and thresholds are held in version-controlled JSON assets marked with status `"draft"`.

---

## 2. Activity Engine Inventory (`assets/activities/v1/`)
| Activity ID | Title | Domain | Age Band | Audience | Steps / Goal Summary | SLP Status (Approve / Change / Reason) |
|---|---|---|---|---|---|---|
| `vocab_colors_5_11` | Colour & Object Matching | vocabulary | 5_11 | parent | Match word to icon | [ ] Approve <br>[ ] Change <br>Reason: |
| `follow_shapes_5_11` | Shape & Colour Journey | understanding | 5_11 | parent | Follow 1-2 step instructions | [ ] Approve <br>[ ] Change <br>Reason: |
| `story_pets_5_11` | Morning Routine Story | narrative | 5_11 | parent | Reorder 3 picture cards | [ ] Approve <br>[ ] Change <br>Reason: |
| `sentence_food_5_11` | Hungry Little Sentence | grammar | 5_11 | parent | Assemble simple word chips | [ ] Approve <br>[ ] Change <br>Reason: |
| `scenario_friends_5_11` | Joining a Game | conversation | 5_11 | parent | Everyday play scenario choices | [ ] Approve <br>[ ] Change <br>Reason: |
| `vocab_tech_11_18` | Digital Terminology | vocabulary | 11_18 | parent | Teen study term definitions | [ ] Approve <br>[ ] Change <br>Reason: |
| `follow_plan_11_18` | Multi-Step Study Plan | understanding | 11_18 | parent | Chronological task organization | [ ] Approve <br>[ ] Change <br>Reason: |
| `story_event_11_18` | Science Project Narrative | narrative | 11_18 | parent | Project milestone sequencing | [ ] Approve <br>[ ] Change <br>Reason: |
| `sentence_complex_11_18` | Connecting Ideas | grammar | 11_18 | parent | Complex sentence conjunctions | [ ] Approve <br>[ ] Change <br>Reason: |
| `scenario_group_11_18` | Group Project Disagreement | conversation | 11_18 | parent | Collaborative compromise choices | [ ] Approve <br>[ ] Change <br>Reason: |
| `vocab_work_adult` | Professional Terminology | vocabulary | adult | adult | Workplace vocabulary matching | [ ] Approve <br>[ ] Change <br>Reason: |
| `follow_instructions_adult` | Administrative Workflow | understanding | adult | adult | Sequential professional workflow | [ ] Approve <br>[ ] Change <br>Reason: |
| `story_recount_adult` | Project Milestone Recount | narrative | adult | adult | Professional lifecycle recount | [ ] Approve <br>[ ] Change <br>Reason: |
| `sentence_professional_adult` | Formal Communication | grammar | adult | adult | Formal professional phrasing | [ ] Approve <br>[ ] Change <br>Reason: |
| `scenario_workplace_adult` | Clarifying Instructions | conversation | adult | adult | Professional clarification choices | [ ] Approve <br>[ ] Change <br>Reason: |

---

## 3. Daily Plan Rule & Wrap-Up Wording
- **Daily Plan Rule:** Suggests 2–3 activities prioritizing domains marked `"some_signs"` or `"more_signs"` in the latest screening (if any), otherwise a balanced rotation; skips activities done in the last 2 days; capped at $\le 15$ minutes total.
- **Wrap-Up Success Wording:** 1–5 qualitative words ("Needs lots of support", "Getting there", "Good practice", "Very smooth", "Mastered independently").
- **Progress Wording:** Plain-language trend summary shown only when $\ge 3$ sessions are compared; no norms, no ranking, no clinical diagnosis.
