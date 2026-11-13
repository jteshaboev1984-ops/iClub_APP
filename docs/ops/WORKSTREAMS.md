# iClub — Workstream navigation index

This is a **locator**, NOT a live status board, task queue, or approval. Review current GitHub Issue comments, PRs/HEAD/CI and deployed state on every request. Last index review: 2026-11-09; entries deliberately avoid pinning current HEAD/status.

Repository: https://github.com/jteshaboev1984-ops/iClub_APP
Project chat behavior: docs/ops/CHAT_PROTOCOL.md

| Command / chat | Canonical source pointers | Scope / special constraints |
| --- | --- | --- |
| СТАРТ ICLUB / 00 Architecture | docs/ai-rollout-working-canon.md; issues/119 and 412 (verify temporary tracker relevance) | Product decisions, system design, priorities, approved release plans; direct requests still valid |
| СТАРТ MATH / 01 Mathematics | docs/math-p1p5-v22-main-integration-roadmap-20261109.md; issues/450; search CURRENT related PRs and dependencies (historical #519/#520 only if still applicable) | P1/P5 v2.2 dependency order and D03 execution-versus-marks firewall; preserve published Extra Hard V4.3 and learner attempts; do not replay already applied DB migrations |
| СТАРТ ECON / 02 Economics | docs/exam-prep-economics-working-plan.md; issues/435 and 432; later academic/source checkpoints under docs/exam-prep-economics-* | 9708 distinct P1–P4 academic gates, independent unseen retests, no fabricated written scores, separate learner release |
| СТАРТ CHEM / 03 Chemistry | latest appropriate docs/exam-prep-chemistry-j*.md; e.g., j21 and j22 source/backup gates; inspect recent PRs and Issues | Do not infer release approval from integration QA or an older document; preserve Chemistry scope |
| СТАРТ BIO / future Biology | docs/biology-source-audit.txt, existing Biology specs and actual open work | Create a dedicated chat only when active work warrants it |
| СТАРТ INFO / future Informatics | subject specifications / source bank, live Issues and PRs | Create a dedicated chat only when active work warrants it |
| СТАРТ ICLUB QA / 90 Audit | relevant target PR/Issue; issues/403 and 432 for cross-subject QA; current security PRs (verify status) | Independent SHA-specific review, source/privacy/security, academic evidence and owner release gates; no competing code changes by default |

URLs for stable entrypoints:
- Mathematics: https://github.com/jteshaboev1984-ops/iClub_APP/issues/450
- Economics: https://github.com/jteshaboev1984-ops/iClub_APP/issues/435
- Cross-subject retest: https://github.com/jteshaboev1984-ops/iClub_APP/issues/432

## How to pick work

Do not interpret this table as a command to run every stream. On START MATH, show only grounded Mathematics tasks; on START ICLUB, show a project-wide mix of actionable priorities. Prefer existing assigned work and unresolved documented dependencies. Do not duplicate tasks already implemented or publish work from a historical PR stack.

## Concurrency

Until owner-led cutover, existing chats continue independently. This documentation branch changes no active task. At activation, re-check current repo state, use one responsible working chat per subject, and place cross-cutting review in an audit chat. Use separate protected-isolation PRs for unrelated streams; do not force-merge older draft stacks into main.
