# Economics 9708 Section A — source delivery hardening (27 Oct 2026)

Status: **STAGED ON FEATURE BRANCH ONLY — NOT DEPLOYED — NO-GO for learner P2/P4**.

## What is changed
- New private, row-level-secured, versioned source-card and question-binding tables.
- New private `open_with_source_v2` wraps the existing learner-owned written task open: Section A source is required, approved, locale matched, version bound and SHA-256 verified.
- Existing public `iclub_exam_written_open_v1` keeps its parameter signature, now delegates to v2.
- Existing public `available`, `next`, and `criteria` include explicit source-ready gate for Section A so a future approved task with an unapproved source is not presented as ready.
- Written view shows locale-matched source before question and accessible, horizontally contained data table; uses textContent (no HTML injection).
- No modifications to existing Mathematics, Practice, Tours, ratings, scores, localStorage or user attempts.
- No new question publication, human-mentor judgement, AI grading, marks, or mastery credit.

## Evidence available in this QA stage
- 22 trilingual Economics P2/P4 candidates, 14 P2 / 8 P4; distinct *new* candidate task_version. **Candidate seed SQL remains a local review artifact and has not been applied.**
- Two source cards: Isara P2 Section A and Nerava P4 Section A, linked to 10 Section A subquestions. Both remain in DRAFT.
- Calculations: Isara weekly shortage 160−100=60 thousand kg; Nerava goods/services balance −12 in Year A, −9 in Year B.
- 9/9 controller/view synthetic tests (EN/RU/UZ × approved source, missing source, no-source B question).
- 12/12 isolated-browser layout tests (P2/P4 × EN/RU/UZ × 375px/1280px) with no page-level horizontal overflow.
- Private live Supabase baseline via SELECT: 14 P2 / 8 P4; 0 approved, 0 released; written plan/access/item counts all zero; anon/authenticated no direct private task SELECT.
- PostgreSQL compilation and authenticated-owner smoke E2E passed inside a single `BEGIN ... ROLLBACK` transaction (not installed). This checked unapproved-source denial, EN/RU/UZ shape validation, missing RU and malformed row denial, owner-only access, localized source payload, no early criteria in open, explicit criteria, source revocation, cross-user denial, idempotent advancement, and status recovery.
- Post-rollback read-only checks: source tables = 0; smoke task = 0; access/plans/items = 0; Economics P2=14/P4=8, released=0. No persistent source records or migrations were created.
- **Real persistent production server deployment, independently authenticated browser E2E and actual 22-task release are NOT performed yet.**

## Release gates
1. Review v3 content + locales + source table column labels, values, headings.
2. Validate and apply additive migration in controlled environment with rollback plan, then separate candidate seed under default DRAFT.
3. Run real authenticated E2E for owner, other user, revoked entitlement, invalid/changed source hash, missing locale, source without approval, idempotent Next, and criteria no-leak.
4. Verify browser mobile/desktop in the actual app, not only isolated fixtures.
5. Explicitly authorize beta publishing/plan assignment only after all gates pass.

## Preservation
Feature branch: `feature/economics-written-source-gate-20261027`.
Production main is unchanged by this branch. Existing learner progress remains untouched.

## Concurrent GitHub main reconciliation

On 27 Oct 2026 `main` advanced with an unrelated AI Practice migration numbered `20261027213000`. The Economics source migration has been renamed to `20261027221000_iclub_exam_written_private_section_a_sources_v1.sql` before integration; there is no duplicate migration version. The AI Practice files were not touched by this branch.
