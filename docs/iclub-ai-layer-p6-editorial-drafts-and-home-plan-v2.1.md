# iClub AI v2.1 — §52 Navigation Copy + Home Plan Acceptance (QA only)

**2026-10-14. Branch:** `qa/iclub-ai-layer-v21-20261012`  
**Authority:** editor/publisher signoff **not yet given**. No deployment, user progress change, SQL installation, AI enabled switch, or paid-provider call.

## Six actual navigation paths — 18 draft texts, NOT published

Existing app source `index.html` + `app.js` + `i18n.js` is authoritative for the route and on-screen label. `qa/ai-layer-v21-p6-navigation-editorial-drafts.snapshot.json` contains a draft response in Russian, Uzbek and English for exactly these six paths.

| Path | Real entry | Phrasing is grounded in |
|---|---|---|
| Home | Bottom `data-tab="home"` | `tab_home` |
| Study | Bottom `data-tab="courses"` | `tab_study` |
| Ratings | Bottom `data-tab="ratings"` | `tab_ratings` |
| Profile | Bottom `data-tab="profile"` | `tab_profile` |
| About | **Home** → `data-action="open-about"` | `tab_home` + `profile_settings_about` |
| Support | **Profile** → `data-action="open-support"` | `tab_profile` + `profile_support_title` |

**Important exact label:** The English Home/About entry button reads “About project” (key `profile_settings_about`), while the destination heading reads “About” (key `about_title`). The draft must tell the pupil the actual *button* label, not the destination heading. About and Support are not bottom tab items.

Node tests independently confirm that all 18 texts use exactly existing literal UI words, not invented translated names; `setTab()` accepts the stated four tabs; the Home/About and Profile/Support actions exist in the right containers and action handlers; and the draft contains no personal progress, prescriptions, exam claims or misleading academic readiness. Any drift to the actual UI/locale makes the draft fail CI.

The draft is **not** inserted into `private.iclub_ai_v21_editorial_source_versions` or `private.iclub_ai_topic_release_v21`. There is no content publication approval, rights endorsement, source version/hashes, signing key, or rollout permission. §51's independent three-locale gate remains closed until approved source, locale reviews, and verified UI entry paths are separately signed off. If this draft is ever approved, prepare properly versioned, exact-hash, per-locale editorial entries through the existing out-of-band publisher; never auto-approve a JSON file.

## Home next-actions — fail-closed API contract, not a plan engine

`qa/ai-layer-v21-p6-home-next-action-proof.cjs` is a pure, isolated proposal for a **server-side plan admission** component. It is not imported by the live app or actual Deno Edge routes and cannot make or show study recommendations.

A Home next action must have all these independent anchors, not merely a browser tab name or Profile counters:

1. Same authenticated learner, same active server-issued 90-second Home context handle and screen revision.
2. A fresh `readServerPlan` record from a **yet-to-be-approved** authoritative planner, with owner, screen revision, separate plan revision/hash, issuance and expiry under 90 seconds, and a small bounded number of actions. No personalized plan source currently exists or is claimed.
3. Independent `verifyPlanAuthority`, not a supplied `approved:true` client value.
4. **For each** proposed `continue_enrolled_subject`, `review_finalized_practice`, or `review_open_tour_archive`: exact backend `verifyAcademicEvidence` including a matching digest and revision. These are only *technical candidate action classes*, subject to separate architect review, not adopted product prioritization.
5. Independent `verifyEditorialRelease(locale, action)`, matching its source digest/version and current language. Without it, no Home AI.
6. Re-read the current screen and expiry **after** asynchronous evidence and source checks so navigation, expiry, user switch or revocation cannot produce a stale handoff.

On every failure, including incomplete proof service wiring or unsupported locale, the contract returns `ready:false`. On success in a synthetic unit test, it returns **only a handoff summary of action IDs and verified provenance**, never teaching copy, academic percentages, score, or permission to alter Core progress. Unit regressions cover omitted provider of proof, foreign screen/plan, missing evidence, forged action code, duplicate actions, locale restriction, expired plan and asynchronous navigation drift. No production planner/RPC/source data is created.

### Explicit NO-GO

Home's real `renderHome()` derives some tiles from `loadProfile()` and local subject selections. This cannot be repackaged as a **server-signed study plan**. An existing subject roadmap likewise does not automatically constitute a cross-subject Home action priority. Once the architect approves eligible actions and evidence semantics, next steps are: review real schema and published rights; design an authoritative read-only Home planner with revision/invalidation; review editorial copy per RU/UZ/EN; run protected isolated Edge/visual QA; and request a separate explicit beta release decision.

**Preserved:** original Mathematics Exam Prep Tutor, main/prod app, Supabase real tables, localStorage, real learners' Practice/Tours/exams, subscription/billing, and Vercel environments. All §52 artifacts are QA-only.
