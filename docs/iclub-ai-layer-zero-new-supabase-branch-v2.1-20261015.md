# iClub AI Layer v2.1 — zero-new-Supabase-branch execution boundary, 2026-10-15

## Architect decision

**A separate Supabase development branch was explicitly rejected.** Do not create a branch/project, obtain billing consent on the user's behalf, or use production Supabase as a writable testing substitute. Keep the existing production database, student progress and legacy Mathematics Tutor immutable.

## Existing available infrastructure (no extra Supabase branch)

- QA Git branch `qa/iclub-ai-layer-v21-20261012`, no merge to main.
- GitHub Actions PostgreSQL 16 disposable databases `iclub_ai_v21_scratch_ci_*`. Each local source suite uses synthesized fixtures, verifies ownership and academic state and drops its database. No production URL or credentials are used.
- QA-only Node/Deno modules and browser testing. Source copied into test memory, no localStorage/progress writes.
- Already deployed protected Vercel *static* QA demonstration `dpl_BswWrQATQYEL86vEAxaECgQhs27r`, with `connect-src 'none'` and no Supabase/provider. Not an integrated beta.
- Optional schema verification is strictly metadata-only against live `information_schema`; never SELECT student/user rows, never create SQL objects or functions on production, never execute UNAPPLIED migration there.

## Correctness improvements §92–§93

A) `qa/sql_drafts/iclub_ai_v21_home_scan_scratch_UNAPPLIED.sql` no longer treats all enrolled subjects as equal for every action. Each scanner candidate requires a matching **active subject mode** (`study` for Practice and continuation, `competitive` for open Tour archive) and a synthetic, owner+subject+intent allowlist grant. The allowlist is deliberately scoped to disposable PostgreSQL and does **not** impersonate the real commercial contract. It only determines the permitted demonstration choices; the downstream server bridge must still verify genuine feature rights independently.

B) `qa/sql_drafts/iclub_ai_v21_home_scan_local_pg.psql` additionally tests switching the user's subject mode and revoking only one synthetic subject grant. A revoked subject cannot hide an alternative correctly authorized subject; revoking every eligible subject returns no Home recommendation. No user data is used.

C) `qa/ai-layer-v21-p6-home-signed-server-bridge.cjs` now rechecks **academic evidence and editorial/source rights/hash/version** after all asynchronous waits, not only commercial entitlement. It then rereads the complete current screen and scanner result before signing. Changed data, revoked rights, changed source, or account/screen drift fails closed, with no plan signed.

D) Corresponding Node tests simulate a right revoked between reads, hash/source version change, last-moment screen revision change, and whole-scan drift. They do not insert anything into Supabase.

## Safeguards still essential

The approved 18 navigation lines are product copy, **not** automatically published academic or protected source content. Real source rights/editorial release, commercial owner-bound AI feature entitlement, server-bound trustworthy signature keys, actual Edge runtime integration and real signed-in Preview tests remain future release gates. No provider spend or student-facing AI until explicit separate GO.

**Do not classify static Preview + offline PostgreSQL as real full app/Edge/Supabase beta.** Such an environment would require a separately authorized architecture. For now the approved deliverable is a fail-closed reproducible offline implementation and an isolated visual Preview.

GitHub Actions run #221 is the evidence target for this checkpoint; record its actual final conclusion (not merely that it was queued) before declaring CI GREEN. No additional Supabase cost authorized.