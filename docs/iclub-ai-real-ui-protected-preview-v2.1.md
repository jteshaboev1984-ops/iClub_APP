# Master Plan v2.1 — protected Preview on actual iClub UI

Branch: `qa/fix-exam-prep-subject-isolation-20261011`. QA route: `/qa/ai-real-ui-preview.html`.

This route is derived directly from this branch's original 80 KB `index.html`: original tabbar, Home, subject hub, Practice quiz, result and review, and original CSS files. Only original script tags were stripped, replaced with synthetic in-memory QA controller and latest checked-in AI QA screen binder, evidence publisher, glue and conversation shell. **The original iClub root index.html, app.js, Math Exam Prep, live auth, practice data and every user record are unchanged.**

CSP: `connect-src 'none'`, `frame-src 'none'`, `form-action 'none'`, `default-src 'none'`, no external scripts; no localStorage, sessionStorage, service worker or provider calls. No actual login, no student records, no paid calls. Questions/answers are deliberately synthetic Economics mini-scenarios with false-only fake session IDs (101/202/203) and independent, no persistence. Existing root preview may connect to production Supabase; **do not use that root page for AI acceptance or create accounts**. Use ONLY QA route.

QA path: native Home -> Study -> Economics subject hub -> Practice -> active quiz (AI fully hidden) -> synthetic finalized result -> review one question -> prepared local context explanation within actual AI conversation panel; protected diagnostic event hides AI. Unsupported subjects say “В разработке.” 3 languages and 320×568, 390×844, 1366×768 responsive checks. No synthetic runtime in original app, and production AI is NOT enabled.

This confirms **real iClub presentation fidelity**, not end-to-end original `app.js` with production DB or server-integrated v2. No production release allowed from this preview test.

## UX correction after architect review (2026-10-13)

**Source-backed decisions:** 1A single brand mark; 18A «Объяснить» context panel; 5A screen+question context; 33B blackout; 39A synthetic-only. Architect clarifies that «Объяснить» must immediately display a populated, question-specific input, automatically submit one prepared request and then render the explanation. A different «Спросить AI / AIdan so‘rash / Ask AI» button opens the same contextual chat with an editable draft and **does not send** until the student chooses to send. Duplicate taps must not double-dispatch; navigation and assessment revoke context.

QA icon correction: the actual Exam Prep Tutor uses `assets/iclub-ai-mark-temp.jpg?v=1` via `exam-prep/exam-prep-ai-ui.js`; use exactly this existing temporary mark in contextual buttons and the floating global mark. The previous iClub `logo.png` was wrong for the AI mark. No logo artwork is modified. This file is named temporary and is not independently approved as a permanent symbol.

**Remaining plan gaps (not disguised as done):** real user and production v2 service link, publication/editorial source approvals, active Tours archival rules, P4 tutor parity integration, tariff accounting and provider gating, single approved cohort rollout and final brand approval are NOT validated in this preview. Browser uses original app HTML/CSS but not original app.js; fake Practice and ready replies do NOT represent real accepted academic content. QA must stay server-disconnected and never write progress or use real accounts.
