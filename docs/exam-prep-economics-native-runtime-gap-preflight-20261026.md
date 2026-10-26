# Economics native Exam Prep runtime gap — read-only handoff (26 October 2026)

**Status:** P1=36 and P3=36 academically approved private MCQ sources, but Economics remains draft/off. Do not activate, deploy or modify existing Math components here.

Actual `main` source inspected:
- `exam-prep/exam-prep-host.js`: 27,521 chars, currently explicitly defines `MATHEMATICS_KEY='mathematics'`; controls host state/navigation and non-Math coming-soon behavior.
- `exam-prep/exam-prep-live.js`: 129,958 chars, Math-specific progress/components P1/P5, session UI/controller. This is an existing production-capable Math experience, not Economics.
- `exam-prep/exam-prep-api.js`: 21,761 chars, derives capability with fallback `math_as_p1_p5`, uses Math-specific RPC names and workflow.
- `docs/exam-prep-multisubject-shell-contract-v1.json` currently states `DESIGN_AND_SERVER_DTO_ONLY_NOT_A_LIVE_ECONOMICS_RUNTIME`. The intended shared host stays visually identical; Economics is `native`, Mathematics `legacy_adapter`.
- `docs/exam-prep-multisubject-visual-functional-parity-v1.md` explicitly prohibits removing non-Math host lock before runtime and E2E. Do **not** build a separate Economics app or change Math logic blindly.
- `public.get_my_exam_prep_program_shell_v1(text,text)` is currently dormant for Economics while `program.status='draft'` or `launch_enabled=false`; this is appropriate.

Technical gap to address WITHOUT altering the above contract:
1. Specify a native `economics_9708` server-authorized diagnostic/learning flow, using P1/P3 approved *metadata* from existing private allowlist; never expose `public.questions.correct_answer` or unrestricted answer texts to client or place sensitive keys in the public repo.
2. Use existing host styling, navigation semantics, locale handling RU/UZ/EN, progress UX, and keep legacy Math `legacy_adapter` unaffected by feature-gated branch. Resolve exactly how auth, session ownership, question content delivery, server-side scoring, stop/resume, review, feedback and retest are protected. Do not mark Theory visits as mastery.
3. Wire published and consent/access guards as a fail-closed native branch only after explicit technical contract, tests, rollback and architect GO. Until then keep `MATHEMATICS_KEY` guard as is.
4. Written Paper2/Paper4 cannot be treated as MCQ; require separate source-to-skill-to-mark-scheme and marking-policy approval. Do not invent automatically graded essays.
5. For beta, verify that new code does not break previous Math P1/P5, Tours, Practice, lesson course progress, localStorage, profiles or Supabase evidence.

**No code or database changes for this runtime inspection.** Next action: design exact minimal fail-closed native controller/API contract with neighboring before/after code snippets only when actual patch is requested/ready; do not propose a broad UI rewrite.
