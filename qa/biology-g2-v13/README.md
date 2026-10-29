# Biology G2 isolated diagnostic preview (historical synthetic QA)

This fixture was forward-ported **unchanged** from `qa/biology-g2-v13-shadow-preview-20261013` (blob `f6d71dbdfb46d089214fb9352572b752b7c048a7`), not merged from its old runtime branch. It is an optional QA fixture, **not** a learner route or an academic approval of any live question.

- Local-only synthetic exercise; no Supabase, network, forms, cookies, or persistent browser storage; CSP denies all connections.
- RU / UZ / EN copy is present to exercise diagnostic labels and fallback states.
- Nothing here is imported by the app entry point, app.js, Practice, Tours, or Economics/Chemistry code.
- Because it is a 2026-10-13 snapshot, do not use it as evidence that current production UX or source content is approved. Run independent current-main acceptance tests for release.

Manual smoke: open the HTML using a local static server, select wrong/right answers in each language and confirm correction labels reset and the state remains in memory only. Source branch is retained. No production SQL or student account is involved.
