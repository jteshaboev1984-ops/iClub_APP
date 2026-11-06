# Mathematics P1/P5 D10-10 — five repaired original items, six staged assessment versions

**2026-11-06 · Issue #450 · DRAFT only · NO PRODUCTION WRITE**

After source audit D10-08/09 found five exact same-problem pairs, five
mathematically new original replacement candidates (2 diagnostic, 2 retest,
1 mixed) were authored EN/RU/UZ and stored in the owner's private archive:
`/iClub_APP/Mathematics_P1_P5/Private_Question_Candidates/iClub_Math_P1P5_private_5_replacements_20261106.zip`.
Protected JSON source SHA-256:
`d788adc9b145cd308937a70f0ffdfa670545f5ee28a3d740b22fb5b33c7a158d`.

**Important source fact:** the one P1-DIF-05 mixed candidate Q6711 appears
in **two** different published assessments (IDs 188 and 338). The other
four candidates each appear in one published assessment. We therefore
must stage **5 new question rows + 5 new protected content-meta rows,
6 new draft assessment versions (24 cloned items, 6 question swaps)**.
This preserves both mixed routes, not just one.

## Practical implementation

- `scripts/ops/p1p5-d10-10-private-five-versioned-stage.cjs`
  validates the **exact** original private JSON checksum and five
  source key/ID/skill/role pairs, 3 languages, distinct four-option MCQs,
  time-limit inheritance and official scope. The file must be outside the
  public repository. No plaintext prompts or answer keys in Git, CI, stdout
  or frontend bundles.
- `check`: local protected payload and academic structure check, no SQL.
- `dry-run-isolated`: test CI only, disposable PG17 with two known users,
  source-locked. Executes the **same DDL/DML staging path** then ROLLBACK.
  Uses only synthetic `2+2` fixtures, never real content in CI.
- `stage`: **separate owner GO** `ICLUB_P1P5_PRIVATE_FIVE_STAGE_GO`
  plus exact private SHA is mandatory. Transactionally inserts entirely
  **new** `public.questions` records as inactive draft, new protected
  `exam_prep_question_content_meta` as withheld/draft with pending QA,
  and clones the six affected published assessments as distinct **draft
  versions**; originals are neither updated nor retired. Full row-count,
  hash and ownership checks run before committing.
- No question/assessment is automatically published or QA-approved.
  A future owner-reviewed release must decide whether to activate the
  newly reviewed versions and retire old assessment routes safely, without
  rewriting history or touching learner answers.
- Stored Practice, Tours, all other subjects, P1/P5 sessions, Paper marks,
  certificates, profiles, subject memberships, localStorage, AI and Mentor
  are untouched. Public Exam Prep release remains NO_GO.

## Acceptance checkpoints

1. Private `check` succeeds with SHA-256 from the owner's existing
   five-question ZIP. Source math was computed 5/5 in the previous task;
   no external human examiner is claimed.
2. An isolated real PG17 fixture inserts **only synthetic** replacement
   payloads, validates that exactly six draft assessments and their
   24 original-order items would be created, then ROLLBACK restores
   all question, assessment, content-meta, history and session counts.
3. The existing signed P1/P5 JWT/PostgREST/Chromium E2E still passes,
   including six real written Papers and normal study ownership.
4. **No live staging or publication authorized by this PR**. The separate
   12 new Extra Hard original challenges are handled by PR #499 and are
   likewise not yet imported or visible.

## Actual next step after this package

Author-controlled private staging/release decisions and versioned final
QA for both the five P1 replacements and the new 12 P1/P5 Extra Hard tasks.
Then refine **81-skill** preparation-hour methodology from genuine tasks,
instead of citing unobserved Cambridge personal-learning-minute norms.
