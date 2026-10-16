# iClub Chemistry 9701 — Academic Knowledge Layer (first consolidated build)
**Version:** 2026-10-16, `CHEM9701-KL-v1-DRAFT`  
**Operational state:** **DRAFT / NOT INSTALLED / NOT RUNTIME-ENABLED**

## What was completed in this build

1. Verified the **existing Mathematics P1/P5 model** directly from Supabase: `private.exam_prep_syllabus_nodes`, `private.exam_prep_ai_source_cards` and `private.exam_prep_ai_tutor_cards`. Maths has 81 approved theoretical and Tutor skill families, each in EN/RU/UZ. Chemistry is not yet at that maturity.
2. Reconciled the official **Cambridge Chemistry 9701 syllabus 2025–2027 V1**, the actual Chemistry Coursebook 3e contents and iClub Chemistry Tour Map v1.0. Official Cambridge 9701 includes topics 1–22 at AS, 23–37 at full A Level; practical competencies are separate.
3. Designed **152 internal iClub skills** across the 37 syllabus topics (140) and 12 cross-tour practical competencies. These are editorial **skill subdivisions**, not official Cambridge outcome identifiers and **not** a final line-by-line outcome crosswalk.
4. Wrote **41 skill families × 3 locales = 123 original theory cards** and **123 AI Tutor cards**, covering all 7 tours and two practical competencies. Each is structured with core reasoning, a worked example, a critical check and a distinct alternative explanation. These drafts have hashes and explicit `runtime_allowed: false`.
5. Mapped **all 630 currently linked active Chemistry question IDs** to provisional skill candidates on the existing GitHub **QA branch only**. This is an **unreviewed heuristic crosswalk**: 522 stem matches, 50 topic metadata matches, 58 low-confidence fallbacks. Nothing can award mastery from these candidates.
6. Ran 25 file-level QA checks, all passing, including independently recalculated worked numerical examples.

## Why 630 questions ≠ 630 learning cards

A skill is a stable concept or ability. Multiple question IDs can assess the same skill; a complex question can assess several skills. Source cards and Tutor cards are skill-based. Question→skill mapping and achievement determination are versioned, separate, server-authoritative operations. 

## Critical scope and safety rules

- Canonical source precedence: official Cambridge syllabus > internal skill map > textbook support > Tour Map > legacy question labels. The book is an instructional reference, not permission to copy its questions or diagrams.
- No Cambridge book paragraphs, exam question statements, figures, mark schemes or protected answers are republished in these original cards.
- AS 9701 includes official theory topics 1–22. Full A Level additionally includes 23–37 and builds on AS. The initial Tour Map's wording about AS finishing at Tour 3 must **not** override this; Tours 4 and 5 remain assessed AS areas.
- Practical skills, mechanisms, and worked/method-based competencies cannot become `mastered` solely from MCQ selection. Explicit experimental/structured evidence is needed, and any `mentor_verified` status requires a real human review.
- AI Tutor can explain approved concepts but **never writes to** scores, historical answers, course states, readiness, placement, entitlements, or mentor decisions. No AI support for a protected active assessment; no correct answers or protected question bank sent to model before submission.
- The system must work without AI. No availability or completeness promise is made for content not yet authored and approved.

## Current gaps — must be completed before Chemistry AI release

- 111 of the 152 skill nodes have no source or Tutor cards yet. This build is a substantive first content tranche, **not** a finished full 152-skill Chemistry service.
- Full per-learning-outcome source crosswalk must be verified within each of the 37 official topics and practical guidance.
- The 630 provisional mappings need item-level academic review, multi-skill flags and release-approved immutable snapshots. Only 522 had even a stem-level regex signal; a regex signal is not academic verification.
- EN/RU/UZ professional-language parity and chemistry editorial sign-off must be performed for each new card; current statuses are draft SELF_CREATED, not external approval.
- Learner-facing server retrieval/entitlement checks, answer-key protection, diagnostic integration, UI and protected Preview/E2E are not completed by this package.
- Existing Chemistry `private.practice_ai_source_cards` explain answers but **are not** a substitute for 152 theory/Tutor skill families. The old answer-card bindings include replaced IDs; they must not be reused blindly.

## Files

- `01_CANONICAL_9701_SKILL_MAP_DRAFT.csv` — 152 curriculum/practical skill nodes.
- `01_TOUR_SCOPE_AND_SOURCE_MAP.json` — grouping and source identity.
- `02_THEORY_CARDS_3LANG_DRAFT.json` — 123 original learner-focused theory cards.
- `03_TUTOR_CARDS_3LANG_DRAFT.json` — 123 aligned tutoring variants.
- `04_INTEGRATION_AND_RELEASE_CONTRACT.md` — architecture, safe import and guards.
- `05_QA_RESULTS.json` — 25 checks and precise availability counts.
- `06_SOURCE_AND_SCOPE_DECISIONS.md` — authoritative boundaries and legacy conflicts.
- `07_QA_BRANCH_MAPPING_POINTER.md` — verified GitHub location of all 630 candidate mappings.
- `SHA256_MANIFEST.csv` — integrity checksums.

## Live database status

All Supabase investigations in this build were **read-only**. GitHub changes are **QA branch documentation only**. No production code, database schema, user answers, localStorage, scores, season status or AI permissions changed in this Knowledge Layer build.