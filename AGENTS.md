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
- For implementation, work on an isolated branch with Draft PR by default, fix proven defects, run proportionate tests and record exact SHA and next work in the existing workstream checkpoint.
- No new server, extra subscription, billable model, paid Supabase or provider calls without explicit approval. One ChatGPT session may sequentially plan, develop, review and test; those are phases, not independent background agents.

## Transition / activation

These documents are a proposed future chat workflow. Until the architect stops the current chats and activates the new ChatGPT Project instructions, existing active work continues unchanged. Documentation-only staging is not a product release.

See docs/ops/PROJECT_INSTRUCTIONS.md for the ready-to-paste ChatGPT Project instructions; adding a file to GitHub alone does not configure a ChatGPT chat.
