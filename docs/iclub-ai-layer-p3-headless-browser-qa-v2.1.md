# iClub AI v2.1 — §38 Genuine Chrome viewport regression (QA only)

No new branch, PR, Vercel deploy, migration, production database or real learner. The local HTML fixture imports the **actual** checked-in iClub Global AI CSS and JavaScript unchanged. Supabase bootstrap is replaced with a deterministic in-page synthetic object, and model request callbacks always deny.

Node 22 directly drives headless Chrome DevTools with real viewport emulation: 320×568 RU, 390×844 UZ, 1366×768 EN, and short 390×480 RU. It checks the AI mark stays inside the viewport and above the mock bottom navigation, the panel and composer fit without horizontal overflow, the 76% mobile collapsed sheet, title/actions alignment, fullscreen/restore including the viewport bounds and accessible label, navigation context-close, Exam Prep diagnostic blackout and later recovery.

This is a true browser geometry/interaction test in **synthetic HTML**, not an actual iClub production screenshot, real data flow, or owner sign-off on the still-unapproved final AI icon. Chrome is required: missing browser means the CI step fails, it never silently skips. Actual mobile keyboard, safe-area on physical devices, dark mode and full integrated Preview remain open pending separately approved isolated QA Preview.


Real Chromium discovered the fullscreen panel briefly inheriting a scaled/translated 170ms entrance animation. The QA CSS now explicitly disables the pop-in animation and transform in the full-screen state, so it fills the viewport immediately. Browser tests check actual pixel geometry, not just presence of CSS rules.


## §39 same-tab account isolation browser regression

The original dormant UI shell retained all subject chat messages in `state.threads` across authentication events and had no protection against a late reply after a different account signed in. This is an unsafe same-device privacy possibility, even without persistent transcript storage. The QA fix clears only ephemeral in-memory chat on changed session ownership or signout; it bumps an auth epoch to invalidate in-flight replies/bootstrap and an independent context epoch for subject or protected assessment changes. A refreshed token for the SAME user preserves the session chat. The real Chrome harness now simulates a deferred old-user answer, switches to a different UUID, resolves the stale response, and asserts it never renders; then verifies the new account can chat and a same-user token refresh preserves it. No real student progress/state is modified.
