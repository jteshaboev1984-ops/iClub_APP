# iClub — Chat work protocol v1

Status: STAGED FOR CUTOVER. This document controls developer chat workflow once the architect activates it. It does NOT automate execution or change a live application.

## 1. Two entry modes

A. **Discovery menu (READ ONLY):** If the entire user message, after trimming whitespace (case-insensitive), is one of the exact commands below, read fresh project sources and return a short numbered menu. DO NOT code, edit Issues or create PRs on the menu turn.

- СТАРТ or СТАРТ ICLUB → project-wide choices (architecture, current workstreams, QA).
- СТАРТ MATH → Mathematics P1/P5.
- СТАРТ ECON → Economics.
- СТАРТ CHEM → Chemistry.
- СТАРТ BIO → Biology (only if there are grounded active tasks).
- СТАРТ INFO → Informatics (only if there are grounded active tasks).
- СТАРТ ICLUB QA → independent audit, security and release readiness.

B. **Direct request (RESPOND / EXECUTE AS ASKED):** Any other substantive natural-language request takes priority over the menu mechanism. Interpret its requested action: discussion/question → explain without coding or editing; audit-only → inspect without code changes; implementation/fix → actually implement in the relevant workstream. Do not ask the user to type СТАРТ first, and do not force a menu before a clear request.

C. **Number selection (EXECUTE):** A standalone number 1–5 selects the corresponding choice only from the **latest UNCONSUMED menu in this exact chat**. A menu becomes consumed on selection and is cancelled by a new START or a substantive free-text request. Numbers from prior menus, completed selections and other chats do not carry over. Revalidate the chosen task before writing; if it has since been completed or is now blocked/owned by another active PR, do not silently switch to another task or overwrite the work: briefly explain and offer a freshly verified menu. If no pending unambiguous menu exists, ask for START or a substantive request.

## 2. Before generating choices or executing work

1. Identify the repository and direction from command or natural language; consult WORKSTREAMS.md for source pointers.
2. Read AGENTS.md, relevant approved specs/roadmap, current canonical issue including **latest comments**, PR status/HEAD/base and relevant SHA-specific CI. Check current main and release gates when applicable.
3. Reconcile contradictory historical “CURRENT/NEXT” text against latest verified actions. Do not simply sort by issue-body heading. Report uncertainty when live verification is unavailable.
4. Check dependencies, branch ownership, already completed stages, other ongoing PRs and potential overlapping files. Do not take over or rewrite another active chat's branch without a selected task and verified coordination.
5. Prioritize actual unfinished actionable work, real blockers and unresolved verified defects. Do not run repetitive full audits or academic rewrites solely to populate a menu.

## 3. Menu contract

Return up to 3–5 **real** distinct numbered options (fewer if fewer are verifiable). Each item must include: concrete outcome, reason/priority, relevant Issue/PR link or MD pointer, blocking dependency and whether owner approval is required. Never invent work to fill five slots; do not advertise production changes as automatically authorized. Clarify that the user can reply with a number OR enter an arbitrary request. No mandatory form or extra confirmation for safe ordinary work.

## 4. Execution contract

- After number selection or direct request, perform a substantive package, not a string of trivial micro-steps. Fix actual defects as you find them within scope.
- Use a new isolated Draft PR unless the user explicitly chose an existing workstream branch and edit rights/overlap are verified. Distinguish a reviewed commit from untested HEAD.
- Run only the test coverage relevant to the changed files; use existing zero-cost GitHub Actions and isolated PostgreSQL/Chromium when needed. Do not claim E2E based on mock data.
- Save the result in the **already canonical workstream Issue/MD**, recording what changed, exact SHA, source-specific CI evidence, remaining blockers and next actionable task. Update WORKSTREAMS.md only when navigation or scope changes; do not turn it into an easily stale runtime-status board.
- Keep independent review in an audit chat for major changes; a second ChatGPT pass is NOT an independent human academic or literary signoff.
- Production/main changes, paid provider usage, academic publication and destructive operations remain explicit owner GO gates.

## 5. Boundaries between chats and cutover

- ChatGPT chats are NOT synchronized processes. GitHub is the durable shared work log, not message history. One project chat is used for one workstream; audits default to read-only assessment and send findings back to the responsible workstream.
- A new chat has no reliable prior menu state; START must regenerate choices from live GitHub.
- Current chats may keep working until the architect declares cutover. This staged protocol must not halt, redirect or overwrite their work. At cutover, re-read live main/issues/PRs; do not rely on staged SHA snapshots.
- If GitHub, browser, Supabase or other required tools are unavailable, state what cannot be verified. Do not fabricate completion or CI status.

## 6. Multi-step operational safeguards and activation checklist

- **Authority is layered:** architect-approved product/safety policy controls allowed behavior; actual branch/main/database/deployment evidence controls what exists; latest verified Issue checkpoint and exact-HEAD CI controls task status. A WORKSTREAMS pointer is not approval, a date is not a lock, and a PR title is not a test result.
- **No implicit release approval:** choosing menu number "2" authorizes work on that described task, **not** merging, publication, changing feature flags, live production SQL, learner progress changes or a paid action. Explicit owner GO for the specific gated action remains required.
- **Avoid two-writer collisions:** before writing, re-read the affected PR/branch HEAD and changed files; use a separate feature branch for genuinely non-overlapping work. GitHub Issues are coordination records, **not atomic locks**. Never force-push or overwrite another active workstream's files; if a conflict appears, isolate the package or report it for the architect's decision.
- **Stale menu or missing tools:** if GitHub changes between START and selection, revalidate. If the chosen item is complete or incompatible, show refreshed options instead of guessing. If the connector is down, describe the missing evidence and limit work to safe available scope.
- **Cheap checks:** prefer targeted tests and reuse unchanged exact-SHA evidence; do not infer that any Actions, model or cloud execution is always free. Never create paid resources or trigger billable runs without consent.

### Cutover sequence (NOT automatic)

1. Until the architect says to transition, existing chats continue. Do not change their instructions/branches/PRs.
2. After the architect stops making new old-chat requests, check that no in-flight work is still changing relevant branches; re-fetch current main, latest checkpoints, this docs PR and any colliding files. Resolve a changed main with a normal documented PR update (no forced rewrite).
3. Confirm the docs-only PR remains scoped to coordination files and review its diff/available CI. Merge this **documentation PR only after explicit owner authorization**, then verify AGENTS.md and docs/ops/* can be read from actual main.
4. The architect replaces the **iClub ChatGPT Project instructions** with the approved text in docs/ops/PROJECT_INSTRUCTIONS.md. Editing GitHub cannot perform that UI action. Do not change settings while existing old chats are still active.
5. In a new iClub project chat smoke-test: (a) START MATH returns real read-only numbered options, (b) a number executes only its still-valid work without an unauthorized release, (c) a direct discussion question does not modify code, (d) a concrete direct task executes, (e) a fresh chat START recovers GitHub state without relying on an old chat's menu.
6. If any smoke test fails, keep existing code/releases untouched, repair instructions via a docs-only PR, and retry. The new model is not certified until the architect observes a successful chat-level test.
