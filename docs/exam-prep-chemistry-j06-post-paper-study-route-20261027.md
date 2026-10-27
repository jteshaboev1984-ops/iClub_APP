# iClub Chemistry 9701 — J-06: honest post-P1 review route (27.10.2026)

**Release status:** Draft/OFF. Work continued on the **existing** `work/chemistry-9701-j02-auth-host-20261026` branch; no PR, merge, production Vercel deployment, real beta consent, or learner attempt.

## Source contracts and scope

- Current official Cambridge 9701 **2025–2027 syllabus**: **22 AS theory topics**, plus practical skills; P1 has 40 multiple-choice questions/75 minutes. Source: https://www.cambridgeinternational.org/Images/664563-2025-2027-syllabus.pdf
- Verified current iClub private Chemistry editorial P1: **40 proposed items and four reserves**, covering all 22 AS units. Most topics have two items, four units have only one. This is insufficient to assert topic mastery, reliable level prediction or a true diagnostic measure.
- Internal project `Tour Map v1.0 — Chemistry.docx` groups lessons into seven tours and may use different **textbook chapter numbering** from official Cambridge 2025–2027 syllabus outcome numbering. For Exam Prep P1, the **official 1–22 syllabus units** are canonical; do not equate Tour Map chapter numbers to syllabus unit numbers.

## Shipped under OFF gates

- New, additive `public.iclub_exam_chemistry_p1_review_plan_v1(p_session_id,p_language)`, private authoritative completed-P1 session only, RU/UZ/EN.
- Inspects stored original item order, server-owned correct letter and saved shuffled answer position. Aggregates 22 topics: questions seen, correct, incorrect, unanswered. Returns the five most urgent **evidence-backed topic reviews** based on mistakes and misses, and all 22 topic names. Does not return keys, original item texts, user identifiers other than caller-owned session ID.
- Requires `auth.uid()` session ownership and all existing Chemistry member/owner/published program + P1 gates. **Before finalize = `finish_first`**; wrong user = `not_found`; revoked or OFF = `not_available`. `anon` EXECUTE denied, no service-role key in browser, no direct private table access. **Stable read-only RPC**; does not write grades, revision flags, scores, or user history.
- Response explicitly includes `can_credit_mastery=false`, `exam_prep_diagnostic_result=false`, `evidence_limit=one_or_two_questions_per_topic_no_mastery_inference`. Any UI using this API must call it **a review of this paper**, never official Cambridge topic mastery or a substitute for an entry diagnostic.

## Frontend in existing shared host

- The gated Chemistry renderer adds **«Что повторить» / «Nimalarni takrorlash kerak» / «What to review»** *after finalized result only*.
- Screen shows first priority topics with error and skip counts, a concise warning about limited evidence, then expandable full 22-unit summary with accurate EN/RU/UZ unit names. It never claims a skill has been confirmed/learned. Uses existing card, grid and responsive patterns, leaves Mathematics/Economics paths intact.
- On denied/missing data, shows safe error with back-to-result action; source result does not disappear. No localStorage changes.
- HTML cache tokens were refreshed to load the updated Chemistry JS/CSS only when/if branch is later merged and released.

## Verification

- Positive **SQL test inside BEGIN/ROLLBACK** temporarily used existing authorized Mathematics beta identity and staged the 40 Chemistry questions as a hypothetical Paper1 submission; saved one correct and one wrong, finalized **1/40** (38 unanswered). Checked topic totals=40 across 22 topics, priority list of five, localized UZ title, no plan before finish, cross-user isolation and revocation.
- This was an authorization-context **simulation** using a transaction-local signed-in identity, *not* the real user's browser session. It was fully rolled back; no approved items, beta members or attempts remain.
- Repeatable synthetic browser-module test: `scripts/qa-chemistry-9701-j06-review-plan-ui.cjs` — **7/7** (final-only control, no implicit data fetch, priorities, 22-unit list, evidence warning, EN→UZ, safe error).
- Live read-only QA: `scripts/qa-chemistry-9701-j06-post-paper-review-readonly.sql` — **26/26**. Existing Mathematics 544 sessions/1,979 responses and Practice 502 attempts/4,816 answers preserved as verified at this checkpoint. Economics unaffected; original 26 Chemistry variants retained.
- Last repeatable Chemistry J-05 UI test remains **4/4**. J-04 source/user-scoped exam API remained closed and existing production data unchanged.

## Still required before Chemistry beta GO

1. **True entry diagnostic with fresh, independent, syllabus-mapped assessment inventory**, not reused published Paper1 items. 40 P1 items alone should not be recycled into a scored diagnostic that reveals their answers. Need sufficient unique tasks and reliable calibration, plus repeat-check questions after teaching.
2. Link actual study content safely to official AS syllabus units and practice tasks; Tour Map mapping cannot be assumed identical to syllabus numbering. After errors, offer contextual explanations and genuinely new rechecks (not claiming mastery after one MCQ).
3. Actual browser/device QA with authorized consenting learner (desktop/mobile, keyboard, interruptions). Current test is simulated DOM, not screenshots or a remote live browser check.
4. Owner approval and exact content manifest, controlled beta gating and rollback drills; preserve Mathematics/Economics, Tours, Practice and all localStorage/user progress. **Do not change `main`, Vercel, or Chemistry launch flags without explicit GO.**

**Status:** J-06 post-P1 learner follow-up implemented and tested in isolation; complete Exam Prep Chemistry not released.
