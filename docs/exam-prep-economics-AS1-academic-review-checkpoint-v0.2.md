# iClub APP · Economics 9708 / AS-1 Academic QA — checkpoint 2026-10-23

**Stage:** AS-1 first full thematic pass; **not finalized / NO-GO**. This is an academically reviewed *draft shortlist*, not an approved exam bank. The canonical working plan is `docs/exam-prep-economics-working-plan.md`.

## Primary source and boundary

Official Cambridge 9708 Economics syllabus, **version 2**, exams 2026–2028:
https://www.cambridgeinternational.org/Images/697423-2026-2028-syllabus.pdf

Compared against printed pp. 15–18, especially:
- 1.1 scarcity, choice and opportunity cost
- 1.2 economic methodology
- 1.3 factors of production
- 1.4 economic systems
- 1.5 production possibility curves
- 1.6 classification of goods and services
- 2.1–2.5 demand/supply, elasticities, surplus and market relationships

The 30 legacy review items are inventoried in:
`exam-prep/academic/economics-9708-mcq/AS1-P1-Units1-2-30-question-review-shortlist-v0.1.json`.

Each item has a corresponding preliminary mapping and QA case:
`exam-prep/academic/economics-9708-mcq/AS1-P1-Units1-2-30-item-provisional-QA-dossier-v0.2.json`.

**Important:** This repository's visibility has been checked: **PUBLIC**. Never commit exact new exam question texts with answer keys or rubric secrets to it or expose them through static Vercel. The QA dossier contains only source IDs, proposed skill mapping and non-secret review statuses.

## Findings: 30 original shortlist entries

| QA area | Verified outcome | Limit |
|---|---|---|
| Legacy item identity | 30/30 distinct, published, active MCQ records | “published” refers to older bank, not this Exam Prep |
| Structure | 30/30 have exactly 4 options in EN/RU/UZ and A–D answer-key shape | This does not validate academic correctness |
| Localization presence | 30/30 nonempty EN/RU/UZ question text, options, explanation | First-pass check of stems/correct options only; full second reviewer pending |
| Academic mapping | 16 existing P1 Unit 2 candidate mappings; 14 new candidate mappings *proposed in dossier, not inserted into Supabase* | 0 approved; exact direct-skill evidence remains gated |
| Answer/economic logic | First-pass semantic consistency for all 30, including explicit numerical reasoning sanity-check | **Not independent academic acceptance**, do not set existing 4 QA flags pass |
| Paper 1 coverage | 14 items Unit 1, 16 Unit 2 | 0 units 3–6; not a complete diagnostic/mock |
| Practice/Tour collision | 4 active Practice overlaps, 0 active Tour overlaps | IDs `8616, 8619, 8621, 8625` excluded from independent unseen timed mocks |
| Graphs | None of 30 relies on an external diagram | Diagram competence requires separate question formats and rubrics |
| Provenance | Zero source `-T-` tags among 30 | Further near-duplicate and per-learner prior-exposure checks still required |

### Academic correction of earlier suspicion

**8618** maps to **2.4.3 alternative demand** and its canonical card `2.4.3-02`.
**8622** maps to **2.4.3 derived demand** and its canonical card `2.4.3-03`.

The primary Cambridge syllabus **explicitly includes alternative demand and derived demand in 2.4.3** (printed p.18). Therefore their earlier “maybe wrong 2.4.3” note is **resolved as correct mapping**. Do not repeatedly reopen that same concern without new evidence.

Potential language QA action: **8630** has a UZ PPC abbreviation that should be standardised consistently with neighbouring questions. Do not change the legacy Practice/Question record silently; stage a content revision proposal first.

## Original draft additions: 6, unpublished and hidden

Six completely original EN/RU/UZ MCQs with four options, unique key, explanations and distractor justifications have been drafted in the **private conversation artifact**:
`iClub_Economics_AS1_6_original_drafts_PRIVATE_2026-10-23.json`
- `EC9708-AS1-ORIG-001` → 1.2.1 economics as social science
- `EC9708-AS1-ORIG-002` → 1.2.2 positive vs normative
- `EC9708-AS1-ORIG-003` → 1.2.3 ceteris paribus
- `EC9708-AS1-ORIG-004` → 1.2.4 time periods
- `EC9708-AS1-ORIG-005` → 1.5.2 bowed PPC, increasing opportunity cost
- `EC9708-AS1-ORIG-006` → 1.6.3 merit goods/information failure

They are **draft-only**; independent examination of distractors, mathematical/diagram interpretations, Uzbek/Russian terms and collision against the entire legacy corpus is still pending.

Local raw JSON file SHA-256 after two language refinements: `bd7d8ae40167691dcfa2458872c4b55891c960b17ae029f35bc5eae0e0bfc6e5`.

A private service-readable secure draft vault has been created with migration `20261023101620_iclub_exam_core_private_question_authoring_vault_v1`. **Its row count is currently 0**: the six private drafts have **not yet been transferred** into Supabase, and must not be claimed as DB-stored or as Exam Prep candidates. The personal Library direct upload encountered a container-session-expired error; retain the original generated conversation file and transfer the complete exact-hash content only through a secure channel. Do not place keys in GitHub to work around this.

**Batch size: 30 existing first-pass screens + 6 original drafts = 36 draft/review items**. This is a working academic batch, **not 36 approved items**.

## Necessary QA to actually close AS-1

1. Full EN/RU/UZ meaning of all four options AND explanations for all 30 legacy and six originals; fix all relevant translation/ambiguity cases in new versioned drafts without changing live question history.
2. Independent second-pass economic logic, one unambiguously correct alternative, adverse assumptions and distractor plausibility per question; mark “revise” or “reject” where required. Do not bulk-mark 4 QA flags as pass based on this single audit.
3. Prepare missing exact syllabus-point coverage, map learning outcomes and AO, verify canonical skill hashes and programme version; at least 1.1.2/1.4.1 and several Unit2 objectives remain sparse.
4. Identify prior learner exposure and equivalent/near-duplicate stems across the wider Practice/Tour/question bank, not merely exact IDs. Keep unseen timed/diagnostic reserves separate.
5. Persist six original drafts in private storage with checksum and **then** build independent QA report for those exact bytes. No release flags, no learner access until approved.
6. Continue AS-2 Units 3–4 only when the substantial unresolved AS-1 issues have an explicit disposition; there is no need to micro-split AS-1 into 2–3 question jobs.

## Safety / checked production baseline

No modifications to `public.questions`, `public.practice_pool_questions`, `public.tour_questions`, old scores, attempts, user lessons, `index.html`, live Exam Prep Host, runtime keys or localStorage. Only a closed additive internal table schema plus review-only files.

Live Supabase check on 2026-10-23:
- Economics programme `launch_enabled=false`; existing MCQ candidates still 16 and approved 0.
- New internal draft vault exists, private; **0 rows**. `anon/authenticated` SELECT false; `service_role` SELECT true.
- Math Exam Prep 543 sessions / 1,976 responses; Practice 502 attempts / 4,816 answers; `user_subjects=2098`. Count comparison only, not row hash or authenticated browser test.

**Next starting point in a new chat:** read the working plan, this checkpoint, the 30-item provisional QA JSON and retrieve the 6 originals from the private conversation file. Continue independent QA, not premature publication, then checkpoint again.
