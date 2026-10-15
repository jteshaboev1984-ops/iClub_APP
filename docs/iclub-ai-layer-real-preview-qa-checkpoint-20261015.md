# iClub AI v2.1 — real-app protected Preview checkpoint, 15 Oct 2026

**Status:** QA browser and source gates GREEN; **visual direction only** preliminarily accepted by architect ("вроде ок"). No permission for commercial Global AI beta or production rollout.

## Exactly what was built

- Reused existing `qa/iclub-ai-layer-v21-20261012` and existing Vercel project `i-club-app`.
- Kept actual iClub `index.html`, `app.js`, `style.css`, `i18n.js`, the real four tabs, course stack and Exam Prep bundle.
- Frozen production-facing `global-ai-ui.js` and `global-ai-ui.css` at original QA blobs `023516d2127a838f8b12b398215745304fe11d9e` / `27150c82d8204d423f178b56b01715a04cdbc1bc`; no visual change made to production-facing files.
- The Preview build `qa/ai-v21-real-preview-build.cjs` copies real app files then overlays **only its disposable output** with `qa/ai-v21-real-preview-ui-snapshot.js` and CSS. Any source hash mismatch aborts the build. Git branch and Vercel environment guards fail closed.
- A synthetic session and prepared replies are supplied by `qa/ai-v21-real-preview-fixture.js`, not Supabase. The generated HTML replaces the two external authentication/Telegram SDK scripts and inserts an early Content Security Policy equal to the Vercel response header. `connect-src 'none'`, `form-action 'none'`, `frame-src 'none'`, no outside data transfers. Database mutations in the fixture explicitly fail.
- The unfinished branded AI icon is represented by neutral `AI` lettering. Do not claim this is the approved iClub AI brand mark. Architect must separately choose the final design.
- Screen-safe suggestions are separated for Home, Study catalogue, Subject, Lesson, Practice start, Practice result/review, Tours and Profile. During active Practice/Tour the shell hides completely. No mock score or error is fabricated; after completion, proof-dependent help is explicitly unavailable.

## QA evidence (not a production release gate)

- GitHub Actions: `38738638985`, **success** on commit `337d59b1c53fc989f7f5e7f25c51e2b9fa9f3d91`.
- Automated offline unit/contract tests: **10/10 passed**.
- Native Google Chrome on actual product app source: genuine Home → Study tab navigation; panel closed on route change; Practice pre-start suggestions; active Practice and Tour blackout; return after result screen; guarded mock score explanation; viewports 320/390/1280 px. **No external network responses** and **zero JS runtime exceptions** in this test.
- Source drift gate: `app.js`, `index.html`, `exam-prep/`, `supabase/migrations/` unchanged relative to protected baseline; QA original shell/CSS unchanged relative to frozen QA base.
- Source-only test environment is loopback Chromium; it does not count as full authenticated production or protected hosted-browser beta.

## Deployed Vercel Preview

- Project: `prj_c1U3yBXrdYtg6uEU5m9AWaja9ie4`.
- Git branch: `qa/iclub-ai-layer-v21-20261012`.
- **Commit pinned:** `337d59b1c53fc989f7f5e7f25c51e2b9fa9f3d91`.
- Preview target, **not** production.
- Deployment: `dpl_9AANkQb3akqcqck8JE7XQLPdE9YE`, `READY`.
- Immutable URL: https://i-club-94b9iwnsf-jasurbeks-projects-c5451f97.vercel.app
- Vercel SSO applies to the project Preview. No domain alias to main, no tariff activation, no production DB access.

## Still NOT implemented / mandatory STOP before a true AI learner beta

1. Production server-verified authenticated context, readiness, user and subject rights; V2 context+answer routes and the 23 missing RPC contracts (as reported by the 15 Oct P0–P9 metadata preflight). Offline QA adapters are not a production backend.
2. Reviewed editorial publication and verified source rights/version/locale. This Preview gives prepared **navigation guidance only**; no real source-backed subject answer, verified lesson explanation, student diagnostic, result, error or readiness inference.
3. Real finalized Practice proof and question IDs; verified Tour archive timing and ownership; independent Mathematics P1/P5 verified skill proof and Tutor continuity; full anti-cheat and forbidden-key tests.
4. Approved final brand mark, deeper mobile/RTL/accessibility QA, first-use disclosure and exact contextual actions.
5. Independently authorized beta cohort/provider money, tariff caps, rollback and server kill switch. **No production or paid AI enabled.**
6. No new paid Supabase branch: the architect explicitly rejected it; remain on scratch/disposable tests until another safe real-integration strategy is approved.

## Next engineering work

Use this checked-in QA shell to implement and test genuine verified server context selectors in a **separately isolated, no-production-write** integration contract. Preserve the original Mathematics Tutor and four real tabs. A Preview-only UI success does not authorize migration, Supabase writes or changing existing learner state.
