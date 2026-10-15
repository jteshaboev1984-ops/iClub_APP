# iClub AI Layer v2.1 — §96–§97: actual local HTTP → PostgreSQL → signed Home → Chromium

**Date:** 2026-10-15. **Mode:** QA ONLY. **Production/beta/provider:** NO-GO.
**Cost:** no Supabase branch/project or provider calls, no new billing.

## Architecture under test

The isolated integration is no longer a static hand-coded response. It combines:

1. **Real PostgreSQL 16 scratch database** with synthetic versions of the source-audited iClub tables, seeded by `qa/sql_drafts/iclub_ai_v21_home_http_fixture_local_pg.psql`. The database is explicitly named `iclub_ai_v21_scratch_ci_home_http`; SQL installation/execution requires a scratch name and local PG connection. The GitHub Actions job destroys it after the test.
2. **Server-side local HTTP gateway** `qa/ai-layer-v21-p6-home-pg-http-gateway.cjs`, bound to `127.0.0.1` with exact Origin, JSON structure and synthetic Bearer-token guards. The request body cannot supply the account/user identity; only `contextHandle` and `locale` are permitted.
3. **The existing real-table SQL scanner**, `buildHomePlan`, commercial proof checks, independent academic evidence, reviewed-locale **synthetic publication double**, HMAC verification and owner-approved priority `QAHomeApprovedPriority`. The HTTP output includes only a candidate action or unranked subject choices, never grades, correct answers, secrets, HMAC or academic data.
4. **Actual headless Chromium** navigates `/qa/home/demo` served by the same localhost HTTP server, and fetches `/qa/home/next` with the synthetic identity. This QA-only UI is `qa/preview_v21/home-pg-local.html`; it is NOT the existing deployed Vercel static Preview. RU 320×568, UZ 390×844 and EN 1366×768 verify local text, action, accessible navigation landmark, no horizontal clipping, no external traffic and suppression after client logout.

## End-to-end tests

`qa/ai-layer-v21-p6-home-pg-http.test.cjs` checks correct Practice priority, same-rank subject choice, Tour after subject-mode switch, fallback to another permitted subject after one grant is revoked, foreign owner, malformed caller-supplied userId, wrong handle, wrong Origin, missing credentials, no cookies, no disclosed HMAC/grades/answers and rejected requests after server Home-handle revocation. HTTP session, subject grants and rights are **synthetic**. Nothing is written to production Supabase.

A real CI discovery: using PostgreSQL `EXISTS(...)::text` returns `true`, not the wire-protocol shorthand `t`. The QA adapter was corrected to parse that value properly; no server access policy was loosened.

## Confirmed verification

[GitHub Actions #236](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38680967823) **GREEN** on the QA-to-QA branch:
- 628/628 existing Node tests, 14/14 independent scratch PostgreSQL suites, existing Deno/Edge, existing Chromium and two concurrency suites.
- New real scratch PostgreSQL → HTTP → signed Home → native Chrome **three locales PASS**.
- New HTTP negative/positive subtest **1/1 PASS** (multiple scenarios inside).
- Verification of legacy Exam Prep and protected shell unchanged.

## Boundaries / work remaining

- **No real source publication took place.** The QA gateway has an **explicitly synthetic published-rights test double**; product approval for 18 navigation copies does not establish academic source rights or editor signoff for live users.
- Commercial proof comes from **synthetic subject grants**, not the live Supabase commercial authorization service.
- `qa/preview_v21/home-pg-local.html` uses a synthetic test token and MUST NEVER be shipped to Vercel, production, or real users. The previously created Vercel Preview stays a no-network static demonstration.
- No live Supabase credentials are used; no account, localStorage, progress, certificate, paid reply or Math Exam Prep logic is touched.
- Actual full integrated iClub + live Edge remains separate and requires explicit owner rollout GO and a safe authorized backend environment. The architect rejected paying for another Supabase branch.

**Verdict:** local authentic HTTP/PostgreSQL/Chromium integration **GREEN**, Global AI **NO-GO**.


## §98 follow-up: real scratch source release/revocation, CI #245

The previously synthetic hard-coded `ready:true` gateway publication double has been replaced by a *real query* of `private.iclub_ai_v21_home_source_test_releases` inside the same disposable PostgreSQL. Twelve independently fingerprinted local-only records (RU/UZ/EN × action/subject) are created by `qa/sql_drafts/iclub_ai_v21_home_http_fixture_local_pg.psql`. A released rights/source change is reread by the signer before the result is issued; denied or revoked source prevents rendering. HTTP regression now actually mutates PostgreSQL `revoked_at` and `rights_approved`, confirms denial and then restores only test permissions.

One local fixture-generation bug (literal SQL `$` mishandled during code replacement) was caught by the first full CI and fixed by regenerating the file with a structural assertion; no protected code was changed.

[Complete GitHub Actions #245](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38681529131) is **GREEN**: 628/628 main Node, 14/14 independent PostgreSQL suites, additional browser + HTTP signed Home suite (all three locales), Deno and two race checks. This validates a **synthetic approval workflow**, NOT real rights, real provider publication or a backend connected to a real user's Supabase records. The source test entries are discarded with the CI database. Global AI remains NO-GO for the live product.
