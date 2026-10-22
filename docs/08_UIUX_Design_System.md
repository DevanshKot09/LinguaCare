# 08 · UI/UX Design System & Motion

## 1. Principles
Calm · strengths-first · low cognitive load · big touch targets · plain language · consistent · never childish for teens/adults.

## 2. Colour (starter tokens — adjust to brand)
| Token | Light | Dark | Use |
|---|---|---|---|
| primary | #3B6EF5 | #8FB0FF | actions |
| secondary | #19A7A0 | #5ED6CF | progress/success |
| accent | #FFB547 | #FFD08A | highlights |
| surface | #FFFFFF | #12151C | cards |
| background | #F6F8FC | #0C0F15 | page |
| error | #D64545 | #FF8A8A | errors |
Role accents: Parent teal · Teacher amber · Adult indigo · Specialist deep blue.
Contrast ≥ 4.5:1 (WCAG AA). Never rely on colour alone.

## 3. Typography
Primary: **Lexend** (designed for reading ease) or Atkinson Hyperlegible. Scale: 12/14/16/20/24/32. Line-height 1.4–1.6. Support OS text scaling to 200%. In-app "Reading comfort" setting (font, spacing, dyslexia-friendly toggle).

## 4. Spacing, Shape
8-pt grid · radius 16 (cards), 24 (sheets), 999 (pills) · min touch target 48×48 dp · elevation subtle.

## 5. Core Components
App bar · bottom nav/rail · role card · child profile chip · activity card · progress ring · streak (gentle, optional) · checklist step · tip callout · myth-vs-fact card · empty state · skeleton loader · toast/snackbar · confirm dialog · consent sheet.

## 6. Motion Spec
| Moment | Animation | Duration/Curve |
|---|---|---|
| Splash logo | draw-in + fade tagline | 1200 ms, easeOutCubic |
| Onboarding page | parallax + text fade-up | 350 ms |
| Screen transition | shared-axis (Material) | 300 ms |
| Button press | scale 0.97 | 100 ms |
| Activity success | Lottie confetti-lite / star pop (short, optional) | ≤ 1.2 s |
| Progress ring | animated sweep | 600 ms easeInOut |
| Loading | skeleton shimmer | loop |
Rules: no flashing >3 Hz; honour **reduce motion**; animations can be disabled in Settings; kid mode rewards stay short and non-addictive (no streak guilt).

## 7. Accessibility Checklist
Screen-reader labels (TalkBack/VoiceOver) · focus order · captions for audio · visual + audio instructions together · one instruction per screen for 5–11 · switch/voice control friendly · colour-blind safe charts · plain-language copy (grade ≤ 6 for child/teen/adult text).

## 8. Content Voice
Warm, respectful, non-blaming. Say "Children with DLD often…", not "suffers from". Always end screening with the non-diagnostic notice.

## 9. Key Screens to Wireframe (priority)
1. Splash · 2–5 Onboarding · 6 Welcome/Auth · 7 OTP · 8 Reset password
9. Role select · 10 Parent setup + add child · 11 Teacher setup · 12 Specialist setup · 13 Adult setup
14–17 Role homes · 18 Screening flow + result · 19 Activity player · 20 Progress dashboard
21 Observation log · 22 Goals · 23 Invite/link · 24 Communication card · 25 Visual schedule · 26 Learn article · 27 Settings/Privacy
