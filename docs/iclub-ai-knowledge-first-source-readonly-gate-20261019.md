# Knowledge-first read-only source integration (QA only)

Date: 2026-10-19. Owner-approved order: **published iClub help → authenticated deterministic progress → approved subject-specific educational card → paid model only if absolutely needed**.

## Existing DB evidence (read-only metadata, not learner data)

- `public.get_exam_prep_ai_tutor_card_service_v1(P1|P5, exact skill, locale)` returns only approved runtime-allowed curriculum cards. The DB has 45 P1 + 36 P5 approved per language (243 total).
- 243/243 approved active tutor cards have a corresponding approved runtime-allowed rights-cleared source card in `private.exam_prep_ai_source_cards`.
- A tutor card stores a **32-hex** content hash; its source card stores a distinct source hash. Do not mistake the digest formats or auto-rewrite hashes.
- `public.get_practice_ai_source_cards_service_v1` returns approved rights-cleared Practice source cards; 119 per language (357 total). Source hashes are 64-hex.
- Service RPCs are `service_role`-only. They are **not** user authorization: an additional per-user current-view/ownership/attempt-finalization guard remains mandatory. None was made accessible to anonymous clients.
- The current owner-approved signed Home next-action policy is a QA candidate with `releaseAllowed:false`. Absence of a current publisher or entitlement evidence cannot be replaced with guessed personal next steps.

## Implemented integration boundary

`qa/ai-v21-knowledge-first-readonly-gate.cjs` is a pure server-side, dependency-injected resolver proof. It **is not wired** into the production app or the current unaccepted Vercel Preview. Four scoped routes: exact public app help; signed, reviewed Home priority; approved Mathematics P1/P5 skill card metadata; approved exact, finalized and owner-confirmed Practice error card metadata. It requires trusted Supabase Auth, owner-scoped current-screen handle, independent protected-assessment guard, subject entitlement, content/right/publication review and a final re-read after asynchronous work. It never accepts client-supplied owner IDs as authority.

The result is deliberately **metadata-only and QA-only** (`releaseAllowed:false`, `learnerVisibleText:null`). No card body, private result, attempt answer, provider key, provider call, billing request or record mutation can reach a learner through this QA resolver. Approved scope cannot be inferred from simple `approval_status`; future live wiring requires its own server-side read-only RPC/publication contract and current rights gates. The legacy Mathematics Exam Prep Tutor is preserved.

## Required next gates, before production integration

1. Architect accepts existing visual Preview and current wording, or requests corrections.
2. Publish editorial/rights-controlled public help and read-only authenticated server-owned Home evidence/release. An active-card count is not a substitute.
3. Build exact context-bound RPC wrappers with identity binding, version and revoked-source checks. Protect Practice and Tours blackout at both UI and backend.
4. Only then perform read-only integration of ready per-user source content in a controlled beta. No test registration, migration, student data edits or AI spending is authorized by this QA candidate.

No new Vercel deployment, no changes to `main`/`app.js`/`exam-prep/`, no Supabase schema/data writes.

## Grounding correction after inspecting actual live card schemas

The approved Practice source type is **`answer_explanation`**, not `error_explanation`; only **111 of 357** approved Practice cards have an exact `question_id` (33 Chemistry + 4 Economics per locale). The other 243 answer cards are generic and 3 are result context cards; these are **not** authorized to explain an individual's exact finalized error. Cards are not currently available for other Practice subjects. Both Mathematics and Practice `source_card_key` values contain colons and uppercase/hyphenated identifiers, e.g. `p1:P1-CIR-01:theory:en:v2`; strict safe code accepts these actual keys rather than a false lowercase-only regex. The Mathematics Tutor's approved `content_hash` uses 32 hex digits whereas Practice uses 64. The gate was corrected before any user-facing integration, with realistic source-key/type regressions.
