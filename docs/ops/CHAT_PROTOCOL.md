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

B. **Direct request (EXECUTE):** Any other substantive natural-language user request takes priority over the menu mechanism. Perform it in the relevant workstream using its existing plan and safety constraints. Do not ask the user to type СТАРТ first. Do not show a menu before working.

C. **Number selection (EXECUTE):** A standalone number 1–5 selects the correspondingly numbered item from the **latest menu in this exact chat**; retrieve fresh state and perform that work now. Numbers from older chats or old menus do not carry over. If this chat has no unambiguous outstanding menu, request СТАРТ / a substantive task instead of guessing.

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
