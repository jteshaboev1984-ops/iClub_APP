# iClub APP — demo AI tariffs v1.2

## Gate 0: deployment, isolation and rollback audit

**Audit date:** 2026-07-10  
**Repository:** `jteshaboev1984-ops/iClub_APP`  
**Production/default branch:** `main`  
**Baseline commit:** `1f6fd5d4b9f00dcd9ce82378f92ed336d19d3e14`  
**Isolated development branch:** `demo-ai-v12`  
**Demo route:** `/diagnostic-demo.html`  
**Public demo URL declared by the specification:** `https://i-club-app.vercel.app/diagnostic-demo.html`

## 1. Isolation decision

All v1.2 work is performed only on `demo-ai-v12`.

The production branch `main` is not modified. The baseline commit above is the rollback checkpoint for the whole demo route. Until the final acceptance, no demo commit may be merged into `main`.

Allowed paths for the v1.2 implementation:

- `diagnostic-demo.html`
- `diagnostic-demo.css`
- `diagnostic-demo-result-layout.css`
- `diagnostic-demo*.js`
- `demo-data/**`
- `api/diagnostic-ai.*`
- `iclub-ai-mark.svg`
- `docs/demo-ai-v12-*.md`

The main app files, production database migrations and real user flows are outside this scope.

## 2. Current file graph

`diagnostic-demo.html` currently loads:

1. `logo.png` — shared, static, read-only asset.
2. `diagnostic-demo.css` — demo-only stylesheet.
3. `diagnostic-demo-result-layout.css` — demo-only stylesheet.
4. Supabase JavaScript from `cdn.jsdelivr.net`.
5. `diagnostic-demo.js` — current demo logic.
6. `diagnostic-demo-ai-ux.js` — presentation patch and decorative archive logic.

The route does not import `app.js`, the main app state, production navigation modules or production write modules.

## 3. Current network/dependency audit

Static code inspection of the baseline shows these runtime requests:

- GET static HTML/CSS/JS/logo assets from the Vercel deployment.
- GET `@supabase/supabase-js@2` from `cdn.jsdelivr.net`.
- Production Supabase RPC `get_safe_questions_by_ids` for question delivery.
- Production Supabase RPC `evaluate_diagnostic_demo_answer` for answer evaluation.

The current client embeds the production Supabase URL and publishable key. No production write call was found in the demo route, but the route still reads production question data and depends on the production evaluator. This violates Gate 1 of v1.2 and must be removed before the demo is considered isolated from production data.

`diagnostic-demo-ai-ux.js` does not perform network requests, but it creates a decorative fake archive example. That example must be removed under v1.2.

## 4. Shared assets audit

Confirmed shared asset:

- `logo.png` — static and read-only.

Not shared/imported by the current demo:

- `app.js`
- main app localStorage state
- main app Supabase client instance
- production attempts, answers, ratings, recommendations or certificates modules

Fonts are system fonts; no external font request is declared in the demo CSS.

## 5. Data and storage risks found

The current demo has no dedicated `iclub_demo_v12.*` storage namespace and does not yet persist the single synthetic learner required by v1.2.

Required in Gate 1:

- `iclub_demo_v12.state`
- `iclub_demo_v12.chat`
- `iclub_demo_v12.cache`
- `iclub_demo_v12.history`
- `iclub_demo_v12.technical`

Reset must remove only keys beginning with `iclub_demo_v12.` and must not perform network deletion.

## 6. Rollback procedure

Because `main` remains untouched, rollback is isolated and deterministic:

1. Stop using the preview deployment of `demo-ai-v12`.
2. Redeploy the baseline `main` commit `1f6fd5d4b9f00dcd9ce82378f92ed336d19d3e14`, or point the demo branch back to that SHA.
3. Do not run database rollback: Gate 0 creates no database changes.
4. Browser reset, when later added, removes only `iclub_demo_v12.*` keys.

This provides a route-level rollback without resetting real user progress or production data.

## 7. Gate 0 acceptance status

### Completed

- Repository and baseline SHA fixed.
- Separate branch `demo-ai-v12` created from the baseline.
- Main branch left unchanged.
- Current demo dependency graph documented.
- Production Supabase dependency identified.
- Shared static assets documented.
- Rollback checkpoint and procedure documented.

### Deployment verification

After this commit, the GitHub/Vercel status must be checked for a branch preview. The production URL must not be used as the development target. If the repository integration does not create a preview automatically, a preview deployment must be created in Vercel from `demo-ai-v12` before Gate 1 is accepted.

## 8. Gate 1 entry condition

Gate 1 may start only after the branch preview is confirmed. Its first code change will remove the Supabase CDN/client/RPC dependency from the demo route and replace the seven questions, answer evaluation and historical attempts with synthetic static demo data.