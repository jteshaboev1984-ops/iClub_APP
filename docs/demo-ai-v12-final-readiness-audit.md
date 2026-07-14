# iClub APP — Demo AI v1.2 — final readiness audit

Date: 2026-07-11
Specification: `iClub_APP_ТЗ_разработка_демо_AI_тарифов_v1.2`
Branch: `demo-ai-v12`
Route: `/diagnostic-demo.html`
Code candidate SHA: `69470dc9ae67f36f16e51e2a5b66e1457b03109a`
Rollback SHA: `8f3bbf8e5f6a4d8d6c1c1970ca5c784ca8b350ca`
Main base SHA checked: `1f6fd5d4b9f00dcd9ce82378f92ed336d19d3e14`

## Audit method

The implementation was rechecked against:

- Gate 0–8 requirements;
- the functional test matrix;
- the security and cost test matrix;
- the visual QA matrix;
- Definition of Done 20.1–20.6;
- Appendix D end-to-end route;
- Appendix E P0 / P1 / P2 priorities;
- Appendix B approved user-facing copy.

## Isolation and rollback — P0

Status: implemented.

- Work remains on `demo-ai-v12`.
- Vercel preview deployment for the code candidate succeeded.
- The branch comparison is based on main SHA `1f6fd5d4b9f00dcd9ce82378f92ed336d19d3e14`.
- The branch adds isolated demo, API, tests, workflow and documentation files.
- The only existing demo entry file changed is `diagnostic-demo.html`.
- Production Supabase scripts are not loaded by the demo.
- The AI endpoint reports `production_database_access=false`.
- Reset deletes keys only when they start with `iclub_demo_v12.`.
- Rollback is available at `8f3bbf8e5f6a4d8d6c1c1970ca5c784ca8b350ca`.

## One learner and plan comparison — P0/P1

Status: implemented.

- Free, Plus and Pro use the same synthetic profile: `demo-sardor` / Sardor Karimov.
- The deterministic Pro engine now returns exactly the same profile ID as the diagnostic dataset.
- Practice, Tour 4 history, chat and Pro trajectory share the same demo namespace.
- Plan switching does not reload the page.
- Custom chat and Pro trajectory screens are restored after language changes.
- Free, Plus and Pro differ by available functions, not by replacing the learner or attempts.

## Seven-question diagnosis and deterministic Pro — P0/P1

Status: implemented and covered by regression tests.

- Seven MCQ questions.
- Difficulty distribution: 2 easy / 3 medium / 2 hard.
- AI help is unavailable before answer submission.
- Demo answer selects but does not submit.
- Score and evidence use the actual selected answers.
- Pro analysis does not use an LLM.
- Changing question 5 to correct changes repeated-error evidence into a positive signal.
- A 7/7 attempt removes fixed repeated-error output.
- An unfinished attempt keeps historical analysis but has no current evidence.
- Practice 4 at 10/10 does not automatically close Tour 4 errors.
- Targeted questions are selected from unresolved skills and exclude active-tour questions.

Regression file: `tests/demo-ai-gate4-engine.test.js`.

## Plus AI and hybrid route — P1

Status: implemented; live-provider readiness is checked at runtime.

- 30+ verified Economics cards in RU / UZ / EN.
- Verified aliases return immediately without a model call or quota charge.
- Unknown grounded questions can use the server endpoint.
- Server retrieval occurs before generation.
- Repeated generated questions use cache without a second model call.
- Cache keys do not contain the plan.
- Fallback is labelled as a saved verified answer.
- No-source does not call the model.
- Technical state records mode, source IDs, latency, cache hit, model call and quota.
- The readiness panel calls `/api/diagnostic-ai` and marks Live AI ready only when `generated_enabled=true`.
- If the provider or key is unavailable, the panel shows a failed Live AI readiness item instead of presenting fallback as generation.

## Endpoint safety and cost controls — P0/P1

Status: implemented.

- Same-origin JSON endpoint.
- Signed short-lived demo sessions.
- Maximum question length: 500 characters.
- Per-IP throttling.
- One active generated request per session.
- Session quota and daily budget guard.
- Bounded output and timeout.
- Emergency flag: `DEMO_AI_GENERATED_ENABLED`.
- No file upload, browsing or URL fetching.
- Strict structured output and source-reference validation.
- Client-supplied plan claims are ignored.
- Model output and learner text are rendered through DOM text nodes / `textContent`.
- Requests to expose system/developer instructions are rejected before model invocation.
- `store=false` is used for provider requests.

## Active Tour 5 protection — P0/P1

Status: implemented on both client and server.

- Separate synthetic Tour 5 dataset.
- No correct answer key in the browser payload.
- Exact RU / UZ / EN stems are blocked.
- Stem without options is blocked.
- Numeric fingerprints and paraphrases are blocked.
- Answer confirmation and option elimination are blocked.
- Prompt-injection and direct-context bypass attempts are blocked.
- General theory remains available in `theory_only` mode.
- Blocked requests do not call the model or reduce quota.

Server self-test route: `/api/diagnostic-ai-selftest`.

## Visual, localization and copy — P2

Status: technically implemented; final manual visual pass remains part of rehearsal.

- Compact shell is capped at 430 px and centered on desktop.
- Dedicated rules exist for 390 px and 360 px.
- Fixed composer and safe-area offsets are included.
- New AI answers are brought into the readable viewport.
- Core practice, knowledge cards and active-tour data contain RU / UZ / EN.
- Visible final copy is aligned with Appendix B, including:
  - `AI-репетитор доступен в Plus.`
  - `Задайте вопрос по экономике.`
  - `Следующий шаг с учётом вашего прогресса.`
  - honest no-source, fallback, active-tour and Pro evidence texts.
- Engineering terms such as cache and fallback were removed from primary presentation controls.
- The hidden technical panel still shows factual engineering states.

## Automated checks added

- JavaScript syntax checks for all final demo and API modules.
- Dynamic Pro engine regression tests.
- Active Tour 5 guard tests.
- Full static specification-contract tests.
- Gate 8 approved-copy and 19-step stage-route tests.
- Deployed server self-test and endpoint health checks inside the readiness panel.

Workflow: `.github/workflows/demo-ai-v12-checks.yml`.

## Manual Gate 8 items still open

The demo must not be labelled fully finished until these real human actions are completed:

1. Complete ten full end-to-end rehearsals.
2. Record one reserve presentation video.
3. Confirm that the readiness panel shows Live AI as ready in the actual Vercel environment.
4. Freeze the final deployment SHA after those checks.

A 19-step checklist from Appendix D is now built into `Scenario → Presentation readiness`. A run is counted only after all 19 steps are marked. The counter cannot be increased by the old one-click action. Rehearsal progress and reserve-video status use a separate `iclub_demo_v12.stage` key and survive plan, language and screen transitions. Reset still removes them because the key remains inside the demo namespace.

## Current release decision

- P0 implementation: complete.
- P1 implementation: complete, subject to the runtime Live AI health item being green.
- P2 technical polish: complete.
- P2 manual stage acceptance: pending ten rehearsals and reserve video.

Therefore the branch is a **final candidate**, not yet a frozen final release.
