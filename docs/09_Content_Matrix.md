# 09 · Content Matrix (how Q101–1000 become app content)

The 900 templated questions = **12 goals × 15 modifiers × 5 question forms**. Build content once per cell *type*, then compose.

## 1. Goals (12) → App area
| # | Goal | Module | Activity domain |
|---|---|---|---|
| 1 | Identify language needs early | Screen | screening |
| 2 | Improve understanding of spoken language | Practise | comprehension |
| 3 | Build useful vocabulary | Practise | vocabulary |
| 4 | Practise grammar in meaningful sentences | Practise | grammar |
| 5 | Strengthen narrative skills | Practise | narrative |
| 6 | Increase confidence communicating | Practise/Support | confidence |
| 7 | Support comprehension of instructions | Practise | instructions |
| 8 | Improve conversational participation | Practise | conversation |
| 9 | Measure progress fairly | Track | progress |
| 10 | Make practice accessible and motivating | Design system | engagement |
| 11 | Support generalisation of therapy skills | Collaborate | carry-over |
| 12 | Reduce communication barriers | Support tools | barriers |

## 2. Modifiers (15) → Cross-cutting design requirements
| Modifier | Becomes |
|---|---|
| evidence-informed strategies | citations + SLP review on all content |
| visual supports | every activity has picture/visual cue option |
| short daily activities | 5–10 min activity format |
| caregiver participation | parent tip + "how to join in" panel |
| teacher collaboration | share-with-teacher + school carry-over card |
| structured language activities | step-by-step activity templates |
| accessible digital tools | accessibility settings, TTS, captions |
| culturally responsive materials | localisable content, diverse imagery, home-language support |
| without increasing stress | no timers/scores pressure; "pause" always visible |
| preserving age-appropriate expectations | content tagged by age band |
| clear progress measures | success-level + support-level logging |
| respecting individual preferences | interests-based activity picker |
| low-cost resources | printable/at-home no-equipment activities |
| privacy safeguards | consent, minimal data, deletion |
| without replacing professional care | notice + "find a specialist" CTA |

## 3. Question Forms (5) → Content templates
1. **How can X be supported…** → *Guide* article.
2. **What practical steps…** → *Step checklist* card.
3. **Which barriers… and how reduced** → *Barrier → Fix* table card.
4. **How should support be adapted…** → *Adaptation by age band/context* card.
5. **How can caregivers/educators/clinicians help…** → *Role-split tips* (Parent / Teacher / Specialist tabs).

## 4. Content Schema (per item)
```json
{
  "id": "goal03-visual-steps",
  "goal": "vocabulary",
  "modifier": "visual_supports",
  "form": "practical_steps",
  "audience": ["parent","teacher","specialist"],
  "age_band": "5_11",
  "title": "Build words with picture cards",
  "steps": ["..."],
  "barriers": [{"barrier":"...","fix":"..."}],
  "sources": ["..."],
  "reviewed_by": "SLP name",
  "version": 1
}
```
> Target v1: **12 goals × ~6 priority modifiers × role tabs ≈ 70–100 reviewed items**, not 900. Generate drafts with AI, **have an SLP review every item**.

## 5. Q1–100 → Static Learn Library (≈ 40 articles)
Group by blocks A–J in `02_DLD_Domain_Knowledge.md`; add Myth-vs-Fact set from Block D; add Assessment explainer from Block C; Teacher "classroom accommodations" pack from Block F.
