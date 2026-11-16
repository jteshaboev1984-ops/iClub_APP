# UX #531 — isolated staging / Work E2E gate

Date: 2026-11-15. **Draft PR #540 only. NO production release, deployment or database mutation.**

## Latest verified facts

- Live iClub Supabase project: `mmmduffgpvwjdpruzikw` (ACTIVE_HEALTHY). The available list contains no other **active, confirmed-disposable iClub staging** project; inactive `Olimpiada` and active `QISSA` are NOT staging substitutes.
- The live `i-club-app` Vercel project exists. No deployment for the exact Draft PR #540 branch was returned by a branch-filtered deployment lookup. An ordinary Vercel Preview must **not** be assumed to use a separate DB.
- In current `app.js`, `SUPABASE_URL` and public anon key are hardcoded to live Supabase and the auth bootstrap calls `window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY)`. Some separately loaded AI runtime scripts also embed/validate the live Supabase origin.
- Previous UX #531 CI was 13/13 successful at `4e2472d3dccb8d743d6eaa5790f33b4c77a91fa9`; those green checks are static/mock/disposable-runner coverage, **not full authenticated staging E2E**.
- Registration runtime mock `qa/ux531-registered-navigation-e2e.cjs` previously stripped the live stylesheets and omitted B04–B08: this is now corrected in the same Draft branch, without app business-logic changes.

## New source-only work in the same PR #540

1. `qa/ux531-staging-preflight.cjs --audit`: inspect only local scripts loaded by `index.html`, list filenames and line numbers referencing the live Supabase project. No credentials logged; no network, auth or database access.
2. `--self-test`: verify fail-closed rejection of the production domain, mismatched backend IDs and the live iClub UI domain using synthetic project URLs.
3. `--enforce`: **only for a future, dedicated staged artifact**, require separately attested backend ID, exact 40-character commit SHA, staging manifest, rewritten runtime `app.js`, local-script scan with **zero** references to the live backend and restrictive browser CSP targeting staging. Fail if any requirement is absent or mismatched. It cannot prove RLS, data isolation or cleanup by itself.
4. `.github/workflows/ux531-staging-preflight.yml`: runs source audit/self-test only, **not deployment**. A successful workflow is expressly NOT staging readiness.
5. Registered-learner browser QA now also loads `visual/iclub-academy-ux531-b04b08.css`, so it does not accidentally inspect the pre-redesign source styling.

## Strict staging build requirements (before Work)

- Establish a **dedicated isolated Supabase project or disposable local Supabase stack** accessible to Work. Never use existing production iClub, QISSA or legacy Olimpiada accounts/DB. Creation of a new hosted Supabase project or billable branch needs an explicit cost quote and separate architect approval. No cloning of identifiable student or private production rows.
- Use a disposable, synthetic schema/data fixture with RLS, functions, correct foreign keys, signed JWT/PostgREST and GoTrue, plus sufficiently representative unlocked/locked/empty/error states for B00–B08. Copy governed code/migrations as appropriate, **not production secrets, tokens, auth rows or attempt history**.
- Build a distinct SHA-pinned staging browser artifact, not a raw clone of `index.html`. Replace the live backend URL **and** anon/public key in the staged `app.js`; review other scripts containing live origin assumptions and disable/repoint them without enabling unreviewed AI. Provide a CSP **before every script** with `default-src 'self'`, `connect-src 'self' https://<isolated-ref>.supabase.co wss://<isolated-ref>.supabase.co` (no wildcards or broad schemes), `form-action 'self'` and `base-uri 'self'`. The preflight now scans inline HTML as well as direct local scripts and rejects permissive origins. Verify via real Chromium network inspection that no request reaches production; source scanning and CSP alone do not establish RLS or complete network isolation.
- Create or identify a separate non-production Vercel staging deployment, with correct project, team, hostname and protection/Work access. Do not promote to production and do not change `i-club-app` production environment variables.
- Generate `ux531-staging-manifest.json` in the staging artifact with `commit_sha` and `backend_ref`; run `node qa/ux531-staging-preflight.cjs --enforce` using the verified isolated inputs. Record exact URL/SHA/backend ID and clean network trace.
- Work is a **separate cloud-browser mode**. The user must start Work with the verified staging URL and this acceptance plan. Until then, do not claim Work executed registration, created an account, tested Telegram WebView, or cleaned anything.

## Work acceptance contract — only after staging proof

Follow `23-ux531-all-screens-and-work-e2e-master-plan-20261115.md`: fresh two-step registration; record unique synthetic `auth.users.id` and `public.users.id`; navigate Home, Subjects, Practice pause/resume/results, Tours timers/attempts, P1/P5 separation, Economics/Chemistry gates, Ratings, Certificates, Profile/Settings/Notifications/Support; RU/UZ/EN at 320/375/390/430/768/1440. Capture screenshot+pass/fail for each dynamic state. Test cross-account ownership with a second **isolated synthetic** account. Never reset production attempts, scores or local user state.

At completion, perform **isolated backend only** UID-scoped dependent-row inventory and verified deletion, or dispose of the whole disposable test stack; capture before/after counts without real learner data. Logout/clearing localStorage is not account deletion. If any UID, foreign-linked record or token remains, cleanup is FAILED and release remains NO-GO.

## Decision status

- **Draft UI source implementation:** present, final human visual approval pending.
- **Isolated staging backend:** NOT PROVISIONED.
- **SHA-pinned working staging URL:** NOT VERIFIED.
- **Work E2E:** NOT STARTED.
- **Test identity / cleanup:** NOT CREATED / NOT APPLICABLE.
- **Production:** NO-GO, unchanged.
- **Next authorized code action:** advance only source-safe QA and staging design in PR #540. Creating billable infrastructure requires explicit approval; actual Work acceptance requires its isolated runtime preconditions.
