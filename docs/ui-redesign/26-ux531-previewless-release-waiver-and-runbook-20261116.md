# UX #531 — no-staging release verification (architect waiver 2026-11-16)

**Decision:** Architect approved continuing without a hosted isolated staging environment. This waives one infrastructure precondition; it does NOT waive ownership, academic verification, original data, pending user design acceptance, or broad production-release authorization.

## Free-only result and safe replacement
Supabase quoted $0 per month for a new project but refused the new free project because iClub and QISSA already occupy the active-free-project quota (2). A new paid database branch ($0.01344/hour) was rejected. No live project paused, reused or wiped. Never connect real user registration or Paper attempts in ordinary production-backed Vercel Preview.

Use the existing 55 exact-HEAD GitHub Actions tests as engineering proof: disposable PostgreSQL17/PostgREST/JWT/Chromium; 15 Mathematics combinations of RU/UZ/EN and 320/375/390/430/1440; B00–B08; S4 Paper history without written-method marks; all other signed flows. Visual screenshots: [Academy workflow #43827667400](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/43827667400) → Artifacts → ux531-academy-all-screen-review. This is **not live Work authentication or Telegram**.

Add a new independent `qa/ux531-previewless-release-firewall.cjs` workflow. Compare exact candidate vs base main: reject extra production files, migrations/Edge Functions/dependency/secrets, newly introduced localStorage purge, and rollout/AI/Mentor flag changes; keep approved non-school registration Study selection, owner-bound Practice Continue, separate P1/P5 History and D03 no-self-grading. PASS proves bounded source safety, not that a learner has tested production.

## Live baseline (SELECT-only, 2026-11-16)
Current main = current Vercel production = `b5cbf0c10e178c583aeb9c223cc25110cd10c65c`; candidate was `30a4a5efd3b353045f9566ca31efd9ccbeb3e891` before the new source-only guard. Live PostgreSQL17.6: rollout **controlled_beta**, core_enabled=true, QA Core/Weekly=true, ai_enabled=true, mentor_enabled=false, kill_switch=false; public users=1477, Math profiles=120, Core sessions=549, S4 Paper sessions=2, Practice attempts=507, Tour attempts=365, certificates=157; exactly one installed Math subject guard migration. Some historical checkpoints differ, particularly AI flag and Practice count: these point-in-time observations are **not** permissions to overwrite any setting or force counts back to old values.

## Release controls without staging
- No test account, assessment, Practice/Tour submission, data cleanup or unauthenticated simulation on live Supabase. Preserve both active Supabase projects and inactive Olimpiada.
- Before any publication require exact new candidate SHA, successful all applicable CI, review existing account/content-visible screens via offline screenshots, verify main/Vercel source identity, and identify rollback target; no new SQL or flags.
- After separately authorized source-only production release, verify Vercel exact SHA and public static assets by GET. SQL **SELECT counts/config only**, never reapply historical migrations or infer deletions from fluctuating activity totals. For actual login/Math UI acceptance, the real consented learner/owner acts in their own account; the assistant must not impersonate or create synthetic records in production.
- Unverified full handwritten Papers are **not** gradeable, no Stage3 completion credit without independent method marks; do not open mass rollout or invent Mentor requirements. #526 wider API remains non-blocking; P0-16B separate.
- Only a staging requirement has been waived. The new Mathematics v5.8 visual design has not been accepted by the owner; do not call these tests human acceptance. PR #540 stays Draft until a separately authorized guarded main release.

**Scope:** one existing Draft PR, source/test/docs only; no Vercel Preview, no Supabase migration, no production write, no accounts, no payment.
