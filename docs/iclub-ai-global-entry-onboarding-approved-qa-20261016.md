# iClub AI — approved global entry and onboarding UX checkpoint

**Date:** 16 October 2026. **Status:** owner-approved QA-only experience, **NOT** production Global AI launch.
**QA branch:** `qa/iclub-ai-layer-v21-20261012`; validated commit `d457f28dd0be4a379eca5f88df13ee3ad12770a0`.
**GitHub Actions:** https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38868516022 — **3/3 GREEN**.
**Protected Vercel Preview:** https://i-club-d3v3krg21-jasurbeks-projects-c5451f97.vercel.app/
**Deployment:** `dpl_B2pQj6kmxifiAZUzqW5Dsrv2AVU6`, READY, target=null.

## Exactly approved experience

1. Tapping the sole iClub AI icon opens the **same contextual chat, empty of new messages**: 2–3 screen-appropriate suggested questions and free-text input. Merely opening it never calls the answer route, charges usage, or generates a canned message.
2. Tapping a suggested question adds the learner's selection and then invokes the scoped answer route. Entered text uses a separate `promptKey=""` path and, in protected offline QA, gets an **explicit prepared mock fallback**, never an invented real model result.
3. The explicit, separate `Explain this mistake` action on the **original synthetic QA Practice review** still performs one-step open, scoped context, send, step-by-step explanation. No double-tap. No academic answer source is falsely marked approved.
4. After valid app Home bootstrap (and **never** in an active protected quiz), one soft, dismissible 5-second notice explains what iClub AI is for. No persistent tracking, cookie, localStorage onboarding flag, or learner profile write. First opened chat also shows a brief data/safety explanation only once within that running app session.
5. The panel header shows an honest localized status. In offline QA it says **Demo · prepared iClub guidance**; it does **not** pretend that source-governed, generative AI is connected.
6. RU/UZ/EN strings for welcome, status, first-use note, and controls. The approved Option A logo, unobtrusive icon placement, four tabs, subject isolation and blackout of active Practice, Tour and protected Exam Prep remain unchanged.

## Changes limited to QA files

- `qa/ai-v21-real-preview-ui-snapshot.js`: change global icon into pure chat navigation, add transient in-memory first-use flow, honest runtime indicator; preserve guarded explicit contextual actions and the protected answer route.
- `qa/ai-v21-real-preview-ui-snapshot.css`: soft onboarding callout and privacy information card without changing app navigation geometry.
- `qa/ai-v21-real-preview-browser.cjs`: assert zero messages when simply opening, selection-driven response, free-text mock behavior, intro once per session, existing explicit Practice error one-tap response and all-tab responsiveness.

**No** root app changes, production deployment, Supabase modifications, migrations, paid provider calls, tariffs or student records touched. Real model generation still requires independently approved server integration, genuine Auth, budgets and original/source-reviewed content before release.
