# Mathematics P1/P5 — V4 Full42 protected draft staging contract (2026-11-09)

This is **DRAFT / PRIVATE / NOT A PUBLIC RELEASE**. See Issue #450 and its canonical P4-08 written Core rule. P1 and P5 retain separate executed-paper and independently verified-mark ledgers; unmarked writing has **unknown** awarded marks, not zero or a Cambridge grade. Mentor Care remains optional.

## Actual reviewed source identity
- Private owner Library ZIP: `iClub_Math_P1P5_ExtraHard_FULL42_v4_DRAFT_PRIVATE_20261108.zip` (not in repository).
- ZIP SHA256: `4fc65560d1bf6e6f4f35b1f366e2f3a243e022b6a1d6df2fe07b316aeb52a164`.
- Inner JSON SHA256: `8f9d8aec32da6de43e9415f8ab2965b5d425809bc2e849e6e3d1f4a1ee612a88`.
- Bank key: `math-extra-hard-2026-11-full-v4`.
- **42 NEW versioned task keys**; 24 P1, 18 P5, 14 strands × 3.
- **All 42 remain `draft`, all three QA fields `pending`, bank academic_approved=false, release_enabled=false.** The previous computational checks do not confer independent mathematical-difficulty or multilingual-editorial approval.

## Implemented source-protected operation
- Separate `scripts/ops/p1p5-extra-hard-private-full42-stage-v4.cjs` never reuses V3 bank, SHA or task keys. It refuses any mismatched source byte SHA, wrong component/skill, absent locale, per-item content-hash mismatch, improper release/QA state or bank count/strand discrepancy.
- `check` is read-only; `dry-run-isolated` requires **only** synthetic tasks and disposable PostgreSQL17 identity and rolls back transaction.
- The **real `stage` mode is a non-production-only pending/draft import**, not a publish. It requires an explicit Supabase *development branch project ref* matching the PostgreSQL host, database, port and named target. The production iClub_APP project ref is explicitly forbidden. No implicit `postgres`-named target can accidentally authorize production.
- Stage transaction prevents overwrites, verifies count, all 42 stored hashes **and actual source fields** (title/prompt/solution/answer/skill/section/book), and verifies live release pointer remained original disabled. No learner table, released bank or historic task is updated. Task source passes via a local mode-0600 temporary CSV and PostgreSQL COPY; protected text/keys do not appear in Git, CI fixtures, docs or logs.
- `scripts/p1p5-extra-hard-full42-stage-v4-isolated-test.cjs` executes 42 synthetic drafts and hard denials for wrong GO, tampered content, premature item academic approval and bank public approval, then proves transaction rollback restores original snapshot.

## Explicit remaining gates
1. Obtain the owner's authorization for the **hourly cost** of a new Supabase branch; live iClub_APP currently has no development branches. No branch was created by this change.
2. Establish a new restricted dev DB and apply/check the complete non-production migration dependency chain. The live project does **not** currently have Extra Hard tasks/release schema. No SQL has run against live Supabase.
3. Independently review all 42 actual V4 prompts, solutions and EN/RU/UZ meanings, score difficulty with evidence, and version separately. Draft import must never be mistaken for academic signoff.
4. Separate new V4 source-pinned release gate, combined security P0-16B release review, Extra Hard written UX decision and rollback drill are still required **before** any public mathematics section switch. This script intentionally cannot enable the section.
5. Beta-data cleanup separately **not authorized**.

**NO main merge, no production database writes, no Vercel or public feature-flag change, no progress/Practice/Tours/certificates/other-subject mutation.**