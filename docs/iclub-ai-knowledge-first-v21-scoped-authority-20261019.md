# Existing QA v21 scoped authority → free Practice source gate

**19 October 2026 — QA ONLY, no deployment.** Previous step validated exact Mathematics P1/P5 cards and exact Practice cards via service-only existing Supabase RPCs. This step connects the already documented *unapplied* server-owned context, active-exam protection, rollout entitlement, topic release and editorial source-proof RPCs to that exact read-only adapter.

## One trusted sequence

Supabase Auth verifies the actual bearer (no browser-supplied identity) → `get_iclub_ai_v21_runtime_service` checks independent owner release → `get_iclub_ai_v21_scoped_context_service` validates current 90-second owner-bound screen, finalized Practice and question membership → `get_iclub_ai_v21_protected_service` forbids active protected assessments → `get_iclub_ai_v21_rollout_service` revalidates entitlement and enrollment → existing `get_practice_ai_source_cards_service_v1` resolves **exact** question, never generic topic fallback → `get_iclub_ai_topic_release_service_v21` and separately `get_iclub_ai_v21_source_proof_service` verify publication, language, rights, hash, source version → repeat scope/protected/entitlement/publication checks before the QA-only handoff. No user-visible source content or grades are returned.

Implementation: `qa/ai-v21-knowledge-first-scoped-authority.cjs` with `qa/ai-v21-knowledge-first-scoped-authority.test.cjs`. The RPC caller is injected exclusively by the trusted backend. Its scope proof binds `owner_id`, `context_revision`, `practice_session_id`, `question_id`, `topic`, `subject` and `expires_at_ms`; it does not accept a browser `finalized:true` claim. Invalid/stale/revoked/mismatched evidence denies, no provider fallback.

**Critical limit:** the v21 scoped-context and independent publication RPCs are in `qa/sql_drafts/*UNAPPLIED.sql`, **not deployed to live Supabase**. When missing they fail CLOSED. Production Mathematics Exam Prep currently uses its own, independent Tutor. This bridge consciously does **not** claim that `exam_prep_skill` exists in the v21 context schema, and must not remap a protected Exam Prep assessment into a Practice view. No production readiness/rollout grant or official publication is implied.

No extra Vercel Preview, migrations, Supabase changes, registration, user result access, academic state writes or paid model requests. Existing production stays untouched. The earlier founder-approved `knowledge-first` order remains mandatory.
