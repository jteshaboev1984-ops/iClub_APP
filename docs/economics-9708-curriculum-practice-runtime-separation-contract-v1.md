# iClub APP — Economics 9708: separation-of-concerns and no-data-loss contract v1

**2026-10-09 — production preservation / Stage 1 governance; DRAFT only.**
**System of record:** `docs/subject-ai-content-expansion-master-plan-v1.md`; [Cambridge Economics 9708 official syllabus for 2026–2028, Version 2](https://www.cambridgeinternational.org/Images/697423-2026-2028-syllabus.pdf); user-supplied fourth-edition Economics coursebook and approved seven-Tour curriculum map. **This document does not amend the approved Tour Map or change live state.**

## Never confuse these five identities

| Identity and ownership | Example | Meaning | Must not be substituted with |
|---|---|---|---|
| Official Cambridge *numbered syllabus point* | `5.2.4` | Exam-scope authority for teaching and assessment at a specified AS/A Level tier | A book chapter, a Tour number, a question ID, or a draft skill ID |
| Book chapter and approved iClub Tour placement | Ch22 / Tour 3 | Teaching order and course navigation; checked against Tour Map v1.0 | Cambridge's tier or an existing Practice question's historical tour |
| Provisional *atomic learning-action candidate* | `ECON-9708-5.2.4-03` | One proposed independently teachable/diagnosable competence; requires educator signoff | A Cambridge numbered point, already approved skill, or a historical student mastery key |
| Live Practice/Tour question association | Immutable `question_id` and existing `practice_pool_questions` rows | A real question, answer history, eligibility, active/inactive pool membership | Course syllabus coverage or an independently approved answer-specific source card |
| Theory, Tutor and diagnosis content | Skill × locale × content version × independent review status | Original source-supported explanation and specific question/diagnosis mapping **after** approval | Existing `public.questions.explanation_*` fields, generic topic fallback, or proof of mastery |

The key `ECON-9708-<point>-BASE` in an older, **unpublished** draft can be replaced with `-01/-02/...` **only within isolated draft content**. The draft parent's archived text remains source provenance/a possible broad overview, NOT automatically child-specific Tutor coverage. Never automatically remap an old `question_id`, user attempt, mastery record or stored learner-local progress when a parent draft splits.

## Academic tiers and assessment constraints

1. **AS syllabus content 1.1–6.5** is not an A Level-only mastery requirement, and additional A Level material (7.1–11.6) must retain separate provenance. Do not force A Level `9.4.3` Fisher `MV=PT` into AS simply because legacy question **Q2540** appears in old Practice Tour 2. Preserve Q2540 and its previous learner results untouched; resolve through approved future teaching/reporting logic, not database history surgery.
2. Numbered Cambridge `point_id` values are authoritative scope, but **are not automatically the unique atomic skill denominator**. A single official point can contain separate calculations, diagrams and comparisons. Conversely, paired definitions or one integrated evaluation may warrant just one skill.
3. Content authored for a parent overview or a wider textbook chapter is **not verified evidence** that each child can be solved, diagnosed or marked. Keep `verified_precise_question_ids=NONE_VERIFIED` until an independent question-specific review of stems, options/correctness, source rights, and marking rationale.
4. Keep question attribution levels distinct: exact validated `question_id` > validated precise subtopic/skill > topic-level fallback. A fallback may support a neutral explanation but **cannot claim precise error diagnosis or confirmed mastery**.
5. `EN`, `RU`, `UZ` require independent terminology, maths and pedagogical consistency review. An English-only SVG plus translated metadata is **not** an approved multilingual learner diagram.

## An actual planning-versus-production difference: Practice counts

**Approved Tour Map v1.0:** its original planning text explicitly specifies **60 Practice questions per Tour**, separately from the 20 Tour questions and no overlap between Tour vs Practice. This is the historical *design requirement* (not an instruction to mutate today's pool).

**Live Supabase read-only snapshot on 2026-10-09:** Economics subject_id 7; `public.practice_pools` and `public.practice_pool_questions` currently show exactly **70 distinct ACTIVE questions per Tour across all 7 Tours = 490 active references**. All seven pools are active. Tour 2 additionally has **7 inactive pool-question records**, for 77 total references; those inactive references are not active student questions.

| Tour | Planned by original Tour Map | Actual active Practice questions | Additional inactive Practice links |
|---:|---:|---:|---:|
| 1 | 60 | **70** | 0 |
| 2 | 60 | **70** | 7 |
| 3 | 60 | **70** | 0 |
| 4 | 60 | **70** | 0 |
| 5 | 60 | **70** | 0 |
| 6 | 60 | **70** | 0 |
| 7 | 60 | **70** | 0 |

**Decision status: UNRESOLVED ARCHITECTURAL POLICY DIFFERENCE.** Neither 60 nor 70 should be silently overwritten in documentation, UI, eligibility or database. The user/architect must explicitly decide whether the approved plan should be superseded by the established production rule, or whether a separately authorised and backward-compatible transition is desired. **Until then the real 70-per-Tour runtime behaviour is preserved; no migration/SQL writes, no auto-removal of 10 questions.**

Read-only verification method (for future authorised audits only):
```sql
SELECT p.tour_no,
       count(q.question_id) FILTER (WHERE q.is_active) AS active_count,
       count(DISTINCT q.question_id) FILTER (WHERE q.is_active) AS distinct_active_count,
       count(q.question_id) FILTER (WHERE NOT q.is_active) AS inactive_count
FROM public.practice_pools AS p
LEFT JOIN public.practice_pool_questions AS q ON q.pool_id = p.id
WHERE p.subject_id = 7
GROUP BY p.id, p.tour_no
ORDER BY p.tour_no;
```

## Lifecycle and permitted changes

| Stage | Deliverable | Current permission |
|---|---|---|
| 1 | Official syllabus ↔ chapter/Tour ↔ atomic skill *candidate* map, source evidence, denominator and tier review | **IN_PROGRESS**, draft GitHub and private workplan only |
| 2 | Original theory per **approved** independent skill × locale | Existing 40 parent overview drafts may be retained, **not promoted** |
| 3 | Distinct main/simple/alternative/focus Tutor versions with rights, provenance, hash and academic signoff | NOT AUTHORIZED FOR RUNTIME |
| 4 | Precise validated question source, deterministic error mapping and non-claiming fallback | NOT VERIFIED; protected old questions untouched |
| 5 | Formal academic, EN/RU/UZ, mobile graph, numeric and user-data safety QA | NOT PASSED |
| 6 | Optional additive, feature-gated rollout + rollback tested separately | **USER RELEASE CONSENT REQUIRED** |

**No Vercel API/build/preview/deploy, Codex consumption, merge, AI activation, permissions change, learner accounts, questions, answers, scores, attempts, Tour/Practice banks, certificates, payments, entitlements, localStorage or progress changes without separate explicit approval.**

## Current bounded snapshot (2026-10-09; academic review still pending)
- `docs/economics-9708-atomic-candidate-register-current.csv`: **498 provisional learning actions** mapped to **253 Cambridge official numbered subpoints**; zero untreated first-pass parent points, but not an approved skill denominator.
- `docs/economics-9708-current-253-point-decision-register.csv`: consolidated **253 parent decisions**; all 29 earlier sparse rationale entries reconstructed and source-scoped; **independent educator signoff still required**.
- `docs/economics-9708-semantic-overlap-review-current.csv`: **99** cross-parent overlaps with explicit editorial distinctions; **all 99 pending independent academic signoff**, no automatic merge or mastery inference.
- `docs/economics-9708-academic-approval-matrix-current.csv`: 40 parent overview drafts across three languages remain unapproved; verified independent atomic Tutor coverage still zero.
- The original 60-vs-live-70 per-Tour difference remains **UNRESOLVED** and must not be silently 'fixed'.
- All candidates are `runtime_allowed=false`, all exact-question mapping fields `NONE_VERIFIED`, no academic teacher signoff yet.
- Saved source SVGs `docs/economics-diagrams-v0/` are **only unfinished original editorial graphics**; no publishing until visually inspected and translated.
