# Master Plan v2.1 — protected Preview on actual iClub UI

Branch: `qa/fix-exam-prep-subject-isolation-20261011`. QA route: `/qa/ai-real-ui-preview.html`.

This route is derived directly from this branch's original 80 KB `index.html`: original tabbar, Home, subject hub, Practice quiz, result and review, and original CSS files. Only original script tags were stripped, replaced with synthetic in-memory QA controller and latest checked-in AI QA screen binder, evidence publisher, glue and conversation shell. **The original iClub root index.html, app.js, Math Exam Prep, live auth, practice data and every user record are unchanged.**

CSP: `connect-src 'none'`, `frame-src 'none'`, `form-action 'none'`, `default-src 'none'`, no external scripts; no localStorage, sessionStorage, service worker or provider calls. No actual login, no student records, no paid calls. Questions/answers are deliberately synthetic Economics mini-scenarios with false-only fake session IDs (101/202/203) and independent, no persistence. Existing root preview may connect to production Supabase; **do not use that root page for AI acceptance or create accounts**. Use ONLY QA route.

QA path: native Home -> Study -> Economics subject hub -> Practice -> active quiz (AI fully hidden) -> synthetic finalized result -> review one question -> prepared local context explanation within actual AI conversation panel; protected diagnostic event hides AI. Unsupported subjects say “В разработке.” 3 languages and 320×568, 390×844, 1366×768 responsive checks. No synthetic runtime in original app, and production AI is NOT enabled.

This confirms **real iClub presentation fidelity**, not end-to-end original `app.js` with production DB or server-integrated v2. No production release allowed from this preview test.