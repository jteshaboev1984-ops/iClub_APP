# iClub AI v2.1 — useful prepared help, UI polish and next release

The architect reported beta confusion on 2026-10-20: post-consent **Not now** looked like consent was reversible; nav-only quick prompts did not feel helpful or premium. This release keeps the previously approved Option A mark, full panel layout, color palette, typography, thread data and Math Tutor untouched.

**Product copy:** seven first-party guidance topics, each in RU/UZ/EN (21 texts), authored against current production's Study → Subject, Practice Start/Result/Review/Recommendations, Books, Tour Rules and Profile → Support. These are generic instructions, never model-generated academic answers or personalized learning plans. Approved beta UI quick chips reference ONLY seven published keys; existing 18 navigation sources remain intact. Content publication uses source hashes and separate source version `app-guidance-main-1ce0c45-v1`.

**Consent UX:** Before consent: secondary action 'Позже / Keyinroq / Later' closes invite without change. After successful consent: replace both old actions with a clear primary action 'Открыть iClub AI / iClub AI’ni ochish / Open iClub AI' when eligible, or a single 'Готово / Tayyor / Done' if not yet eligible. Closing the dialog does not undo consent; panel opens on tap. Errors remain actionable. Nothing is enrolled without a real user's affirmative tap.

**Rollout:** Keep cohort limited to the three existing eligible candidates, only with their own Global AI consent. No paid provider call, no modification to academic grades or Supabase historical usage. Release migration is additive and requires preserved 18 navigation entries. Exact SQL `qa/live_candidate/iclub_ai_v21_product_help_21_publish_20261020.sql`. UI snapshot is `qa/ai-v21-real-preview-ui-snapshot.js`; adapter `qa/live_candidate/iclub-ai-v21-browser-adapter.js`.

**Next milestone:** study-context sources and verified Practice/Tours results should be linked to their actual user-scoped server data, without weakening the separate Math Tutor. School questions are not yet answerable through the first-party prepared navigation/guidance endpoint.

## Deployment and live beta evidence

- Original iClub main was updated with ONLY `iclub-ai-v21-beta-client.js` and `iclub-ai-v21-ui.js` at commit `190c63ca70ce3f97db7248a4dd160dd890bfa71f`; Vercel production deployment reached `READY` on 2026-10-20. Existing CSS, approved Option A icon, index, Math Tutor, Practice, Tours, Economics and persistence are unchanged.
- The post-consent primary action is now **Open iClub AI** (RU, UZ, EN), and **Later** only appears before consent; closing the dialog never reverses recorded consent.
- Exactly seven verified public product-help keys were added in three locales (21 prepared answers) without modifying the previously published 18 short navigation answers. This release retains the existing 3-learner cohort and requires voluntary recorded consent before any answer; no paid model is enabled.
- The independent new Edge route `iclub-ai-v21-prepared` was updated to version 4 with JWT verification; its `practice_after` key uses the prepared-only service RPC with the same owner/active-assessment/usage rules. The beta tutor is not authoritative over any marks or academic placement.
- The screen-aware prompt set now covers Study, Practice result and review, Recommendations, Tour rules, Books and Support, instead of shallow navigation. It is strictly generic product guidance, not invented learner-specific feedback.
- Regression test `qa/live_candidate/iclub-ai-v21-product-ux.test.cjs` exercises three-language consent state change and the explicit open-panel action; current-main integrity must match actual deployed AI JS byte-for-byte. Live signed-student E2E depends on the student using the production app; never impersonate their sessions.

## Next actual functional milestone

Continue with **verified academic source connection**: screen-specific Study topic and Practice/Tour post-assessment explanations keyed to a server-verified learner and exact published content. First inventory subject content rights/revisions and actual Supabase RPCs. Avoid converting existing Math Exam Prep AI rights or legacy approved cards into new Global AI publication without separate owner/reviewer authority. Do not introduce generic generated answers as a substitute for missing academic sources. UI must keep the accepted Option A mark and panel structure.
