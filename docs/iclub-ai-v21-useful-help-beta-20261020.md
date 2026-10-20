# iClub AI v2.1 — useful prepared help, UI polish and next release

The architect reported beta confusion on 2026-10-20: post-consent **Not now** looked like consent was reversible; nav-only quick prompts did not feel helpful or premium. This release keeps the previously approved Option A mark, full panel layout, color palette, typography, thread data and Math Tutor untouched.

**Product copy:** seven first-party guidance topics, each in RU/UZ/EN (21 texts), authored against current production's Study → Subject, Practice Start/Result/Review/Recommendations, Books, Tour Rules and Profile → Support. These are generic instructions, never model-generated academic answers or personalized learning plans. Approved beta UI quick chips reference ONLY seven published keys; existing 18 navigation sources remain intact. Content publication uses source hashes and separate source version `app-guidance-main-1ce0c45-v1`.

**Consent UX:** Before consent: secondary action 'Позже / Keyinroq / Later' closes invite without change. After successful consent: replace both old actions with a clear primary action 'Открыть iClub AI / iClub AI’ni ochish / Open iClub AI' when eligible, or a single 'Готово / Tayyor / Done' if not yet eligible. Closing the dialog does not undo consent; panel opens on tap. Errors remain actionable. Nothing is enrolled without a real user's affirmative tap.

**Rollout:** Keep cohort limited to the three existing eligible candidates, only with their own Global AI consent. No paid provider call, no modification to academic grades or Supabase historical usage. Release migration is additive and requires preserved 18 navigation entries. Exact SQL `qa/live_candidate/iclub_ai_v21_product_help_21_publish_20261020.sql`. UI snapshot is `qa/ai-v21-real-preview-ui-snapshot.js`; adapter `qa/live_candidate/iclub-ai-v21-browser-adapter.js`.

**Next milestone:** study-context sources and verified Practice/Tours results should be linked to their actual user-scoped server data, without weakening the separate Math Tutor. School questions are not yet answerable through the first-party prepared navigation/guidance endpoint.
