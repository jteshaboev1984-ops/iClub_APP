# iClub Economics 9708 — existing Exam Core academic acceptance route (no new tables)
**Date:** 2026-10-26 · **Status:** READ-ONLY architecture / release contract · **Economics stays draft/off / NO-GO**.

## What is already implemented

Based on actual current GitHub migration sources:
- `supabase/migrations/20261021203000_iclub_exam_core_review_queue_and_shell_v1.sql`
- `supabase/migrations/20261023072744_iclub_exam_core_stage5b2_readonly_academic_allowlist_v1.sql`

Existing private objects already provide the required structural gate:
1. `private.iclub_exam_core_skills_v1`: canonical syllabus subject/version/paper-independent skill with `status='reviewed'`, exact library snapshot/content_hash and `level_code`.
2. `private.iclub_exam_core_paper_skills_v1`: relation to P1 or P3 with `status='approved'` and `link_role='direct'`; subject level must match paper level (AS for P1; A for P3). A paper can assume AS prerequisites for **Theory only**, not count them as direct A paper questions.
3. `private.iclub_exam_core_question_review_v1`: initial frozen metadata/snapshot of legacy `public.questions`. Initial `review_scope/review_answer_key/review_languages/review_exam_format` fields are explicitly constrained to **pending** by their original schema; do not try to use them as editable four QA flags or author an unnecessary new review table. This object holds source provenance and original snapshot MD5.
4. `private.iclub_exam_core_question_candidates_v1`: existing program/version/paper/skill/source association, `status` and four **actionable** QA scopes `qa_scope_status, qa_academic_status, qa_language_status, qa_format_status` (`pending/pass/fail`). It is the correct existing question-level review/promotion object.
5. `private.iclub_exam_core_native_content_allowlist_v1(...)`: implemented service-only, returns **safe metadata** if and only if all preconditions hold and pinned hashes match; explicitly always `can_issue_learner_task=false`. No frontend integration, answer delivery, personal scoring, or learner-plan issuance is implied.

**No new tables, functions, migrations, branches or written task links are needed for the *review* work.** Actual learner assessment runtime is a separate beta-gated task, not solved by approvals.

## Item-by-item admission standard (not bulk flags)

Start from the existing *review-only* question ID/skill mappings stored in GitHub. For each source item, before any later permitted service-only writes:

- **Scope:** official 9708 v2 learning objective, exact canonical `skill_key`, paper P1 AS or P3 A, one direct target; investigate any mismatched role, cross-unit, or AS disguised as A.
- **Academic:** examine full actual stem and all four answer alternatives; independently solve arithmetic, economics, counterfactuals and any diagrams. Check that precisely one is defensibly correct (not only A–D format). Correct-answer letter, meaning and explanations must agree. Reject/flag distractors that become correct under unstated assumptions.
- **Languages:** EN/RU/UZ stem, each of four options, answer choice position, numerical units and explanations must mean the same thing. Nonempty strings are only structural. User-facing language must be natural, not literal machine jargon.
- **Format:** exactly four distinct alternatives per locale, one supported A–D answer; time/diagram suitability, no malformed markup or missing figure; source text/explanation not cut off.
- **Reuse:** check active Practice/Tour references plus content-equivalent sources and prior learner exposure before claiming any `unseen` timed mock. A question may be okay for teaching/review but disallowed in unbiased diagnostic mocks.
- **Integrity:** calculate exactly the original legacy `md5(jsonb_build_object(...))` snapshot expression documented in 20261021203000; candidate.source_snapshot_md5 = review.source_snapshot_md5 = live source. Frozen hash is **necessary, not proof of academic correctness**: it would faithfully preserve even a wrong answer. When content needs correction, use a deliberate versioned repair process, never silently rewrite a historical source and rescore learners.
- **Final state:** only after all four independent questions are answered for that exact item can the existing candidate QA statuses be set `pass`, candidate `approved`, corresponding paper link `approved` and canonical skill `reviewed`; review/library versions/hashes must match, and offline tests must confirm metadata changes are isolated to Economics.

No external expert dependency. Perform **one real item-level evaluation** for each *newly promoted* item; do **not** re-run checks for already documented completed questions without a concrete reason. Never automatically approve all 193 working positions at once.

## Concrete hold and targeted repair items

- **ID 9732: known FAILED academic key in published legacy source.** Its recorded answer letter says D with $400,000 but actual outlay $300,000 against $100,000 budget gives a **$200,000** overspend, matching source option B. Do not permit academic `pass` or Exam Prep issuance, do not change old student attempts/answers; record as *needs content repair*. This is a data-quality defect found during content selection, not an invitation to audit all legacy source again.
- **ID 8982: terminology review** of deflationary expenditure gap versus equilibrium-output gap if it is ever placed in a strict unseen assessment. Target only that question at the promotion gate.
- **P1 legacy `8616,8619,8621,8625`: active Practice exposure**. Review use cases separately; not acceptable as unexposed diagnostic stock even if academic content is correct.
- **Cross-batch conceptual duplicates** (e.g., same government-retraining effect, external-cost summations, repeated PPP and FX-defence) must not appear together in the same short timed set. Track selected independent equivalents in the set blueprint.
- A newly created full original exam question with answer keys is held only in **private ChatGPT Library** during drafting. It is **not** available in `public.questions`, so do **not** create a fictional candidate link to it. Only later migrate through the established content pipeline after an architect-approved production-safe plan. Never put full unpublished keys in the public repository.

## Release invariants

- Current Economics `program.status='draft'`, `launch_enabled=false`. Maintain these until actual user journey/evidence, access-control, bank depth, Paper1 and Paper3 mocks, and P2/P4 written policy pass E2E.
- `question_review_v1` is not an issuance API; `native_content_allowlist_v1` is **always a preview** and returns `can_issue_learner_task=false`, even if records are approved.
- No marks, diagnostic outcomes, retests, mastery or learning plans derive from merely navigating or viewing Theory.
- Server checks source state/version, access role and ownership for every learner operation when runtime is eventually implemented; isolate legacy Math P1/P5 and all existing user records.
- Written Paper2 and Paper4 cannot be treated as MCQs or automatically graded without approved written-task↔skill↔source mapping and marking evidence.
- A **zero approved MCQ** count must not be misconstrued as the absence of source content; review inventory != activation.
- Do not spend Supabase calls on repetitive full scans; use saved five source packages, targeted sixth package, and exact 498-skill gap manifests. Query only bounded new IDs for a real promotion check.

## Decision on work order

1. Current content pass: **25 genuinely distinct previously untargeted A skills** added to the **source proposal**, not database, in `exam-prep/academic/economics-9708-mcq/A-level-Units7-9-11-25-unused-source-gap-pack-v0.1.json`.
2. Updated canonical inventory: `exam-prep/academic/economics-9708-mcq/9708-exact-skill-coverage-gaps-v0.2.json`: 188/498 skill targets proposed, 310 not targeted. AS 92/200, A 96/298.
3. **Next approval work**: small *substantive* group of eligible existing P1/P3 items with clear source credentials and no prior-exposure conflicts; review keys, distractors and all three languages *once* and keep exact QA evidence before advancing flags. Use existing Core, no new schema. This changes no app until explicit carefully tested service-side approval.
4. Then use the remaining skill gap manifest to author only missing substantial content, and separately resolve Paper2/Paper4 written and actual authenticated assessment runtime.

**No live database modifications were performed by this architecture memo.**
