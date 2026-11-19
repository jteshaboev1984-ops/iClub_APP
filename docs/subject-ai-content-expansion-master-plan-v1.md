# iClub APP — Subject AI Content Expansion: Master Work Plan v1.0

**Date:** 2026-10-08  
**Status:** APPROVED FOR EXECUTION — academic/content preparation; learner-facing activation NOT approved  
**Scope:** Economics → Chemistry → Biology. **Informatics DEFERRED** until the architect selects the Cambridge syllabus (AS/A Level 9618 vs IGCSE 0478).  
**Source of truth:** this permanent plan, mirrored in private Supabase project tracker `private.iclub_subject_ai_content_workplan_v1` and `private.iclub_subject_ai_content_stages_v1`. Keep the plan and evidence after completion for audit; update status, never delete historical evidence.

## Purpose and existing situation
Extend the **governed theory source → learner-first Tutor Card** pattern established for Mathematics (P1=45, P5=36, 81 internal skills) to the other three subjects, without assuming the same skill count. Distinguish:
1. existing trilingual answer explanations on `public.questions` (not approved subject Tutor Cards);
2. `private.practice_ai_source_cards` for Practice post-answer/result explanation;
3. new academically mapped subject theory cards;
4. separate learner-first Tutor Cards (main/simple/alternative/focus);
5. deterministic wrong-answer diagnosis.

Baseline, live read-only on 2026-10-08:

| Subject | Questions (all/active) | Practice AI source cards (per locale) | Individually question_id-linked cards (per locale) | Diagnostic rules/questions | Practice questions in 7 pools |
| --- | --- | --- | --- | --- | --- |
| Economics | 809/790 | 80 + 1 result context | 4 | 277 / 73 | 490 |
| Chemistry | 867/850 | 38 | 33 | 52 / 15 | 490 |
| Biology | 962/864 | 0 | 0 | 0 confirmed | 490 |
| Informatics (deferred) | 928/830 | 0 | 0 | 0 confirmed | 490 |

All four question banks have non-empty EN/RU/UZ explanation fields and book_ref; **this is not proof of separate theory/Tutor approval**. Economics 76/80 and Chemistry 5/38 Practice explanation cards per locale use topic/subtopic rather than direct question_id. Existing questions and topic strings are legacy data, not canonical syllabus nodes. Global AI and Practice AI are currently OFF, and **stay OFF** through this work.

## Academic authority & source hierarchy
1. Official syllabus of the selected Cambridge qualification and actual candidate year controls examinable scope.
2. Canonical internal subject skill map derived from that syllabus; exact skill count is determined after audit, never invented from chapter count.
3. Supplied textbooks (Economics 4th edition, Chemistry 3rd, Biology 5th) explain concepts, provide chapter mapping and examples of conceptual scope; **do not copy exercises, figures, diagrams, marked answers or extended text**.
4. Approved Tour Maps describe existing seven-tour content order, but cannot supersede the official syllabus.
5. Production question bank supplies legacy metadata and question mapping; preserve content with user history.

Materials: supplied Tour Map v1.0 Economics, Chemistry, Biology, the three coursebooks, annual AS roadmap; governance pattern: `04_Content_Governance_Model_P1_P5_v1.1`, `06_AI_Layer_Safety_Architecture_P1_P5_v1.1`; repo: `docs/ai-rollout-working-canon.md`, `docs/exam-prep-tutor-content-v3-audit-repair.md`, `supabase/functions/practice-ai/index.ts`.

## Execution stages — strictly ordered per subject

### 1 — Academic canonical source map
Create a versioned complete syllabus → chapter → topic → atomic teachable/diagnosable skill map, with explicit AS/A-Level boundaries; compare approved Tour Maps and actual `book_ref`, `topic`, `subtopic`, seven Practice pools and Season 2 Tours. Audit missing, duplicated and out-of-scope topics. Deliverable: subject map, exact noninflated skill denominator, mismatches and review gates. **Economics IN PROGRESS; other subjects QUEUED.**

### 2 — Original trilingual theory cards
For every approved in-scope skill write an original iClub theory explanation grounded in sources, with key concepts, reasoning/method, an original example and common traps, EN/RU/UZ. Separate `draft`, `approved`, `runtime_allowed`, `content_version`, `content_hash`, provenance. Do not rewrite question bank or approved runtime versions.

### 3 — Trilingual learner-first Tutor Cards
One per skill per language, with distinct **main explanation / simpler explanation / alternative mental model / focus and checks**, plus readable title. Create an immutable source-card link of same subject/skill/locale, version and hash. No internal IDs in learner text. New rows are draft and runtime OFF until independent QA/promotion gate. Mathematics v3 quality is a pattern, not a cross-subject schema shortcut.

### 4 — Practice explanations and deterministic error map
Associate each currently active Practice question with its strongest source: question-specific > precise subtopic > validated broad-topic fallback. Compute **exact coverage vs fallback coverage** separately, never treat topical cards as individual question coverage. Validate trilingual correctness and rule-based misconception evidence. AI may describe a specific misconception **only** when the deterministic mapping supports it. Protected Tour/review eligibility enforced server-side.

### 5 — Academic, language, safety and regression QA
Verify 100% in-scope skill×locale theory/Tutor coverage; distinct card variants; source fidelity and originals; numeric units/graphs, chemistry reaction conditions, biology process correctness; translations, grammar and no code jargon. Verify hashes, uniqueness, no cross-subject leakage, no answer-key exposure, existing Core with AI=OFF, budget/killswitch and no academic-state changes. Any BLOCKER => hold that slice.

### 6 — Separate additive integration/release decision
Only after stage 5 GREEN, prepare optional feature-gated server lookup/runtime integration without changing existing Practice, Tours or Exam Prep mastery. Preview and controlled canary first. **Do not enable global AI, AI entitlements, plans, payments, provider generation or change learner-facing UI without a separate release authorization.** Rollback through additive versioned promotion, no deletions.

## Per-subject order
1. **Economics:** finish 53 chapter content-map audit (chapter 54 is assessment methodology), exploit 80 current Practice cards per locale, repair topic-to-question precision.
2. **Chemistry:** 30 chapters, include numeric calculations, reaction mechanisms, practical and visual evidence; retain 38 existing Practice cards per locale.
3. **Biology:** 19 chapters and 7 tours; start theory/diagnostics from trilingual legacy bank without falsely claiming existing Tutor cards.
4. **Informatics:** **DEFERRED**; supplied book is IGCSE/O Level while legacy Tour Map includes post-IGCSE skills. No mapping/content/runtime work until explicit 9618-vs-0478 decision.

## Non-negotiable preservation and release rules
- No INSERT/UPDATE/DELETE in `public.questions`, history tables, Practice/Tour pools, attempts/answers, ratings, certificates, user accounts or any Exam Prep evidence.
- No new active user entitlement, AI runtime feature, tariffs/payment integration, front-end switch or Supabase Edge function deployment.
- No modifying legacy localStorage, question IDs, order, correct answers or existing history.
- All new content isolated/private, service-only, RLS and browser access denied; release only after approved guards.
- Each stage requires written evidence, status in private Supabase tracker, and a review decision. Record blocked cases instead of fabricating completion.
- First persistence action is documentation and private non-runtime tracking only.

## Acceptance
Stage 1 produces a source-backed map signed off before large-scale card generation. Every later stage has QA and explicit rollback controls. Plan stays stored in GitHub and Supabase until all three subjects complete and remains archived thereafter. Informatics remains deferred independently.
