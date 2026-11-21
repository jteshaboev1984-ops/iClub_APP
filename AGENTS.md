# iClub — development agent instructions

Project: iClub_APP (Telegram WebApp / web, Supabase and Vercel). These instructions govern **development coordination**, not the in-product AI Tutor.

## Required context

- Always read docs/ops/CHAT_PROTOCOL.md and docs/ops/WORKSTREAMS.md when starting or resuming a development chat.
- Resolve the relevant workstream to its approved subject-specific MD, canonical GitHub Issue, current PRs and **current checked SHA/CI**.
- Existing academic specifications and architect-approved decisions remain authoritative for product behavior. A dated roadmap/issue checkpoint is a historical snapshot until checked against current code, PR status and later verified checkpoints. Never treat an old “LATEST” label as proof of current state.
- If sources conflict on a consequential decision or release gate, identify the conflict and ask the architect instead of inventing policy.

## Non-negotiable development boundaries

- Never use a development request as authorization to merge to main, deploy to Vercel production, run live destructive SQL, clear beta/learner data, modify user progress, publish academic content, or enable paid AI. Require explicit owner approval for those actions.
- Preserve separate scopes for Mathematics, Economics, Chemistry, Biology, Informatics, Practice, Tours, certificates and authorizations. Avoid unrelated refactors and overlapping active PRs.
- Protect confidential task text, answer keys, tokens, private academic sources and learner PII; never publish them in GitHub, CI logs or artifacts.
- Mathematics P1/P5: keep actual Paper execution separate from independently verified marks. No fictional written score, learner self-mark as verified achievement, mandatory Mentor, invented Cambridge hour recommendations, or study access cap.
- Tests claiming actual authenticated browser/API/database E2E must have real signed auth, HTTP and isolated data evidence. Mocked UI and source tests have their own value but are not equivalent.
- **Use risk-proportionate QA**: for an isolated verified Practice wording/explanation/option correction, check the mathematics, keys/contracts, RU/UZ/EN, untouched fields, scoped CI, safe future-only release and post-publication membership/history; do **not** require full browser E2E every time. Require appropriate signed JWT → HTTP/PostgREST → PostgreSQL → Chromium integration evidence when altering runtime, scoring, authorization, session/resume, history/progress or when an actual integration defect calls for it. Never label SQL-only or mocked UI checks as full E2E. [Owner decision](https://github.com/jteshaboev1984-ops/iClub_APP/issues/574#issuecomment-7057671300).
- **Explicit publication status and branch hygiene**: say when a concrete question batch is DRAFT, QA-PASSED, READY-FOR-OWNER-GO or ACTUALLY-PUBLISHED, with exact IDs, PR/SHA and relevant CI. Ask for owner merge/production permission at the genuine READY gate, not for routine safe Draft work. Keep PR stacks minimal and nonoverlapping; after an approved merge close superseded PRs and delete their obsolete source branches if the tool permits, otherwise report the exact cleanup blocker. No broad release authority is inferred from documentation approval.
- For implementation, work on an isolated branch with Draft PR by default, fix proven defects, run proportionate tests and record exact SHA and next work in the existing workstream checkpoint.
- No new server, extra subscription, billable model, paid Supabase or provider calls without explicit approval. One ChatGPT session may sequentially plan, develop, review and test; those are phases, not independent background agents.

## Academic Content, Tutor & History

- Subject/question-bank changes must follow the approved syllabus, skill/diagnostic-facet map, rights/source QA and independent RU/UZ/EN answer review. Practice teaches; Tours and secure retests verify independently. Question counts alone are not approval.
- iClub prepares learners; it is not an examiner. Written/lab work stays ungraded unless genuinely independently assessed. Core, explanatory AI Tutor and human Mentor Care are separate; AI never awards marks, mastery, readiness or progress.
- **Correct confirmed Practice errors promptly**. A wrong/ambiguous learner-facing question must not stay active merely because it has answers or open sessions. Verify the mathematical correction, scoring, distractors/diagnostics and RU/UZ/EN, then publish **small, independently complete corrected batches** under the owner's release authorization rather than accumulate Draft stacks. Prefer future-only versions that allow old attempts to finish; where an error cannot be corrected safely otherwise, the owner permits deleting **only answers to that specific erroneous Practice question**, after scoped dependency/transaction checks. Do not turn this into permission to erase unaffected student progress, ratings, certificates, Tour attempts or protected results. Never silently rewrite old answer-key/option semantics, retroactively recalculate results or remove learner access. Latest owner decision: [Issue #574](https://github.com/jteshaboev1984-ops/iClub_APP/issues/574#issuecomment-7039540376), [Rules Inbox #570](https://github.com/jteshaboev1984-ops/iClub_APP/issues/570#issuecomment-7039548309).
- Preserve current owner decisions and subject-specific release gates; an approved plan, green synthetic CI or paid plan design is not a live learner release. See [feedback/rules register](docs/ops/ICLUB_FEEDBACK_TO_RULES_REGISTER_2026-11-18.md) for cases and hypotheses; do not duplicate it here.

## Where instructions, product rules and one-off tasks live

- **Chat/development instructions** are here, in `docs/ops/CHAT_PROTOCOL.md` and `docs/ops/PROJECT_INSTRUCTIONS.md`: how to work, verify and honor owner approval.
- **Product and subject rules** come from the approved product/academic source contracts; the [feedback register](docs/ops/ICLUB_FEEDBACK_TO_RULES_REGISTER_2026-11-18.md) indexes enduring rules, scoped subject/UX requirements, historical cases and unapproved hypotheses. A case, example, date or hypothesis is **not** an implementation order.
- **One-off work** lives in the current canonical GitHub Issue/PR and its latest checkpoints. Revalidate actual status, owner permissions and exact SHA before executing; never turn a completed or historical task into a standing instruction.
- The owner confirmed installation of the updated ChatGPT Project text on 2026-11-18; do not rerun the one-time cutover. GitHub updates do not change ChatGPT settings. A docs-only merge never authorizes an app release.
- Confirmed *new standing rules* are recorded with owner approval and source links in [Rules Inbox](https://github.com/jteshaboev1984-ops/iClub_APP/issues/570) during authorized work. Classification and de-duplication follow `docs/ops/RULES_MAINTENANCE.md`; do not convert one-off tasks or hypotheses to binding instructions.
