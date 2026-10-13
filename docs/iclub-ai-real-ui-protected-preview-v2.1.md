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


## Owner-approved UX B consolidation — review of best tutoring and financial app patterns

- One iClub AI conversation per subject in memory, never a new per-question chat/database table. Each user/assistant message may hold only a small in-memory question-id and localized label; no browser storage or real student records. Existing 40-message cap, bounded 40 cached explanations.
- **Explain solution** on a correct choice, **Explain mistake** on a wrong choice. Synthetic replies explicitly distinguish both wrong answers and the correct answer for each question in RU, UZ and EN. Academic production statements still require server/editorial approval; this QA sample is not production content.
- One contextual Explain click shows compact prepared text, sends once, and displays response. Contextual quick prompts suppress duplicate \"Explain this topic\". Reopening a completed explanation uses tab-memory cache tied to the exact finalized session and question and cannot dispatch a second request. A distinct **Ask AI** opens empty editable composer with question in header; free text returns **In development**, not a fabricated explanation.
- Navigation into another question increments a QA context epoch before asynchronous mint/answer; stale replies cannot impersonate the new question. Restart, leaving the subject, or protected exam clears cached explanations. Individual messages include question labels so the single subject transcript remains intelligible.
- Expanded panel gets real styling/accessibility; mobile panel height increased while preserving safe-area constraints. Working Exam Prep AI image retained. This is QA **only** and uses the genuine iClub index/CSS, no original app.js, production DB or provider connections.
- Manual acceptance: Q1 correct, Q2 wrong, both automatic replies, cached Q1, Q1 Ask AI with empty composer and unavailable free-text answer, protected exam blackout, mobile expansion and no external network.
