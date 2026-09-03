# P0-01 Static Preview Acceptance

Status: **ACCEPTED**

Reference implementation branch: `iclub-v3-implementation`
Reference commit: `d2565b7a5b630837c10e0c1a683c014109393108`
Reference preview deployment: `dpl_738ZzUeKxA6QLHNvCdANpKwvcNtJ`

## Acceptance evidence

- `exam-prep-preview.html` returns HTTP 200 from the reference preview deployment.
- Preview CSP contains `connect-src 'none'`; no production Supabase/network writes are possible from this page.
- Preview loads only namespaced `exam-prep/*` assets and does not load the production app/Supabase client.
- `exam-prep-config.js` enforces `previewOnly=true`, `liveApiEnabled=false`, `featureDefault='off'`.
- Mathematics remains `subjectId=5`; components are P1/P5 only.
- Canonical preview denominator is P1=45, P5=36.
- Allowed languages are exactly RU/UZ/EN.
- Preview uses a dedicated `iclub_exam_prep_preview_*` localStorage namespace; legacy storage keys are not used.
- Fixtures contain exactly 15 learner scenarios covering beginner, prerequisite gaps, strong-P1, strong-P5, half-syllabus, timing/accuracy asymmetry, format gap, mixed-transfer gap, exam-mode candidate, late joiner, interruption/recovery, AI unavailable, offline/retry and mentor-override cases.
- Every learner profile must contain separate P1 and P5 state; contracts reject profiles without both components.
- Mobile viewport is declared and Exam Prep styles are namespaced.

## Boundary

This acceptance covers **P0-01 static/synthetic preview only**. It does not authorize real learner access, Supabase writes, host integration, or production Exam Prep enablement.
