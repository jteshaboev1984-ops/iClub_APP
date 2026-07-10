# iClub APP — demo AI tariffs v1.2

## Gate 1: local data and safe shell

**Acceptance date:** 2026-07-10  
**Branch:** `demo-ai-v12`  
**Gate 0 rollback commit:** `7cf941a6029733907dd5ede438b9b59cabd251de`  
**Gate 1 runtime commit:** `5fd7f77c031d279ff33bc2a13616b2159b884bd1`  
**Production/default branch:** `main` — unchanged

## 1. Implemented scope

Gate 1 replaces the former production-dependent demo runtime with an isolated browser-only runtime.

Implemented:

- removed the Supabase CDN from `diagnostic-demo.html`;
- removed all production Supabase files from the runtime dependency graph;
- added a strict page CSP with `connect-src 'none'`;
- created seven original synthetic Economics MCQs in static demo data;
- fixed the question balance at 2 easy / 3 medium / 2 hard;
- added complete EN / RU / UZ question, option, feedback and next-step text;
- added the synthetic historical timeline required by v1.2;
- preserved practice, timer, result, review, question detail, source and archive flows;
- removed the decorative fake archive example from the active runtime;
- added local/session storage isolation and a scoped reset function.

## 2. Runtime file graph

`diagnostic-demo.html` now loads only same-origin static assets:

1. `logo.png`
2. `diagnostic-demo.css`
3. `diagnostic-demo-result-layout.css`
4. `diagnostic-demo-v12-data.js`
5. `diagnostic-demo-v12.js`

The route no longer loads:

- `@supabase/supabase-js`;
- `diagnostic-demo.js`;
- `diagnostic-demo-ai-ux.js`;
- production question RPCs;
- production answer evaluator RPCs;
- any production write-capable module.

The old files remain in the repository for rollback/reference but are not imported by the v1.2 route.

## 3. Static synthetic dataset

The dataset contains one synthetic learner timeline:

- Practice 1 — 10/10
- Practice 2 — 10/10
- Practice 3 — 10/10
- closed Tour 4 — 6/20
- Practice 4 after the tour — 10/10
- current seven-question diagnosis — dynamic local result

No real user ID, Telegram ID, school, region, attempt, answer or profile row is read.

The seven current questions are original iClub demo content and are not copied from Cambridge past papers, mark schemes or production question rows.

## 4. Storage contract

The runtime uses only the required scoped keys:

- `iclub_demo_v12.state`
- `iclub_demo_v12.chat`
- `iclub_demo_v12.cache`
- `iclub_demo_v12.history`
- `iclub_demo_v12.technical`

`state`, `chat` and `history` use local storage. Temporary cache and technical state use session storage.

Reset is available through:

```js
window.iClubDemoV12.reset()
```

The reset implementation enumerates both browser stores and removes only keys beginning with `iclub_demo_v12.`. It performs no network request and never calls `clear()` on the whole store.

## 5. Network isolation

The route declares:

```text
connect-src 'none'
```

Therefore fetch, XHR, WebSocket and EventSource connections are blocked by the browser for this page.

Static inspection confirms that the active v1.2 scripts contain no Supabase URL, publishable key, `fetch`, RPC call or production endpoint reference.

The technical namespace records:

```json
{
  "gate": 1,
  "data_source": "static",
  "production_calls": 0,
  "storage": "local/session only",
  "dataset": "1.2-gate-1"
}
```

It can be inspected through:

```js
window.iClubDemoV12.getTechnicalState()
```

## 6. Functional checks

Completed before commit:

- JavaScript syntax check for the static dataset;
- JavaScript syntax check for the local runtime;
- HTML-to-JavaScript ID contract check: no referenced element ID is missing;
- seven questions present;
- difficulty balance is 2 easy / 3 medium / 2 hard;
- all questions are MCQ with four options;
- RU / UZ / EN are present for each question and answer explanation;
- local answer evaluation changes the result dynamically;
- timer, pause and timeout paths remain available;
- result is saved only to `iclub_demo_v12.history`;
- review and per-question detail use the submitted local answers;
- archive contains only local diagnoses created during the demo session;
- Vercel status for runtime commit `5fd7f77c031d279ff33bc2a13616b2159b884bd1` completed successfully.

## 7. Safety statement

No migration was created or executed. No production table, policy, RPC, attempt, answer, score, recommendation, rating, certificate or user record was changed.

The working main application and its users remain on the unchanged `main` branch.

## 8. Rollback

For a Gate 1 rollback, point `demo-ai-v12` back to:

```text
7cf941a6029733907dd5ede438b9b59cabd251de
```

No database rollback is required.

## 9. Exit criterion

Gate 1 exit criterion is met:

> The demo works independently from the production database and performs no production user read or write calls.

Gate 2 may now add the Economics Subject Hub, the visible Sardor Karimov profile, the persistent Free / Plus / Pro switch, transition mapping and the compact “Scenario” menu without changing the isolated data contract.
