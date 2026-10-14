# iClub AI v2.1 — §51: General Help navigation source & Home plan boundary

**Date:** 2026-10-14  
**State:** QA contract and editorial candidate only; **NOT APPROVED for learners**. All SQL is `UNAPPLIED` and runs only against disposable scratch databases.

## Verified from the actual production-baseline UI

The following are existing app routes, not invented AI destinations. Names are extracted **verbatim** from `i18n.js`; routes were checked against `index.html` selectors and the actual `setTab()` router in `app.js`.

| View | Source in UI | Русский | O‘zbekcha | English |
|---|---|---|---|---|
| `home` | `data-tab=home` | Главная | Bosh sahifa | Home |
| `courses` | `data-tab=courses` | Учёба | O‘qish | Study |
| `ratings` | `data-tab=ratings` | Рейтинг | Reyting | Ratings |
| `profile` | `data-tab=profile` | Профиль | Profil | Profile |
| `about` | `data-view=about` | О проекте | Loyiha haqida | About |
| `support` | `data-view=support` | Поддержка | Yordam | Support |

Technical candidate: `qa/ai-layer-v21-p6-navigation-candidates.snapshot.json`. It contains **only these verified labels, route selectors and editorial review requirements**. It cannot be used as an approved answer. `qa/ai-layer-v21-p6-navigation-candidates.test.cjs` reruns exact-route, exact three-locale dictionary and no-invented-content checks against the unchanged app source each CI. Changes to the UI or translations invalidate the candidate until reviewed; no auto-translation.

`support` and `about` are real global pages, not persistent bottom tabs. Student explanations must state that distinction if/when editorial copy is later drafted. No assertions about where/how these pages are accessed were invented.

## One governed navigation source, without a second AI system

`qa/sql_drafts/iclub_ai_source_proof_bundle_v21_UNAPPLIED.sql` permits a future editorial entry `surface='global', subject='general', feature='app_help', topic='navigation'`. It requires the **same independent** subject/feature/topic/locale publication, source version/hash, rights, correctness, safety, accessibility, integrity, content publisher and owner-approved rollout gates as all existing AI content. Global navigation is **prepared-only**: it cannot call the provider to improvise UI instructions. No publisher, source rows, permissions to draft from the learner, or approved release are created.

`qa/sql_drafts/iclub_ai_v21_p6_navigation_gate_UNAPPLIED.sql` implements `get_iclub_ai_v21_general_scope_service()` as a proposed read-only `service_role` RPC. It allows a General Help capability **only** if the independent `get_iclub_ai_v21_source_proof_service()` confirms **all three** locales (RU, UZ, EN), with one common version and exact SHA256 evidence. Missing one locale, content conflict, tampered bytes, changed version, revoked rights or kill switch denies General Help as a whole.

`qa/sql_drafts/iclub_ai_v21_real_schema_screen_proof_UNAPPLIED.sql` adds a `navigation` evidence kind requiring a live JWT-owner-bound **global** view handle with the same exact requested view, unexpired TTL and current screen revision, plus the above full source capability. It returns **only provenance metadata** (view, source version+digest, owner); it does not disclose personal profile data, route text, school data, learner answers or chat history. Other app screens cannot spoof the selected global navigation view. Home next-actions continue to deny because a navigation label cannot act as a personal study recommendation.

## Home next-actions: intentionally NOT invented

Existing `renderHome()` uses `loadProfile()`, locally selected/enrolled subjects, Tour/Practice overlays and screen state. Existing `learning_roadmaps` is a separate **subject-specific**, possibly AI-enhanced stored plan; its existence does **not** establish a current, independently signed **cross-subject** Home next-action list. No production RPC guarantees a current, immutable, context-revoked Home action plan with per-action source IDs and reproducible academic evidence. Accordingly:

- `home_next_actions` remains **DENIED** by the proposed `get_iclub_ai_v21_screen_evidence_service`; a valid Home handle does not create a recommendation.
- The existing `TrustedAppWideServerAdapter` requires an independently verified owner-bound aggregate; the backend does not yet supply it.
- Before drafting user-facing Home suggestions, specify actual allowable actions, server-owned priority evidence, revision/expiry, protected-exam exclusions, independent academic ownership and source/locale release. Reconcile these with the real Home UI separately, without changing the student's Core plan.
- Profile's verified activity counts are NOT mastery or a basis to infer recommended subjects or a readiness score.

## Verification and explicit release gate

The existing disposable scratch PostgreSQL `context` suite imports the new source gate alongside existing source/release tables and tests missing/partial locale, three-locale synthetic approvals, matching current/foreign/wrong view, prepared-only route, rights revocation and stale source version. Positive test text is explicitly marked **SYNTHETIC** and is rolled back; it is not approved content. Node checks live UI + literal RU/UZ/EN labels. All existing Math/Practice/Tour security suites, Deno/Edge routes, Chromium, quota and monetary controls continue to run.

**Remaining blockers:** real editorial signoff on each multilingual navigation explanation, approved immutable per-locale source texts, verified UI entry actions, registered release rows, service-role RPC security review, a genuine Home next-action planner and isolated UI/Edge navigation/logout integration. Without these, General Help and Home AI remain **NO-GO**, regardless of passing mock tests. No production SQL/PR/deploy or data mutation is authorized by this stage.
