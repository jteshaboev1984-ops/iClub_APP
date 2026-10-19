# Existing Supabase Auth + academic RPC read-only bridge (QA)

**Scope:** Prepared on the existing QA branch only. No new Vercel Preview, live Edge deployment, production source publication, Supabase migration, academic data write, or paid model call.

## Actual existing server contracts connected

1. **Identity:** `GET /auth/v1/user` with the current **user's JWT** and public Supabase anon key; owner ID is returned by authenticated Supabase Auth. Untrusted client `userId` is ignored.
2. **Math:** service-only `get_exam_prep_ai_tutor_card_service_v1(p_component_code,p_skill_code,p_locale)` returns approved P1/P5 cards with precise skill and locale. The second service-only `get_exam_prep_ai_source_cards_service_v1` checks exact linked `source_card_key`, component, skill, 64-hex approved source hash and version. Tutor card hash is 32-hex, its source hash 64-hex — distinct.
3. **Practice:** service-only `get_practice_ai_source_cards_service_v1` with `p_card_type=answer_explanation`, `p_question_id=...`, null topic and 12-card bounded list. This RPC can mix question-bound and **generic** candidates; the adapter categorically excludes fallback cards and requires exactly one verified subject+locale+question match.
4. **Independent release:** No live equivalent of trusted `readEditorialRelease` is installed in this scope. The adapter demands a separate independent proof matching source key, original hash, release version, card digest, locale, subject, P1/P5 skill or Practice question, editorial QA/rights and revoke state. Without it the result is `in_development`. Active DB card availability alone cannot publish a Tutor.
5. **Screen, assessment blackout, entitlement:** A required separately trusted server-provided `readCurrentScope`, `readProtected`, `verifySubjectRights` all feed the preexisting knowledge-first gate with rechecks after awaits. Browser hints cannot substitute for them.

## Safety invariants

No browser-side service key, no insertion/update, no grade/mastery changes, no learner marks/answers in responses, no OpenAI request, no financial hold, no registration, no generic Practice answer as personal error. Fetch targets fixed to official HTTPS Supabase Auth and the three allowlisted existing RPCs. Every result is QA metadata-only with `releaseAllowed=false` and `learnerVisibleText=null`. The existing active Mathematics Exam Prep Tutor is not called or replaced.

No real-user rollout or production AI state is changed. Follow the previously approved plan: **trusted iClub knowledge and data first; model only when necessary and separately funded**.
