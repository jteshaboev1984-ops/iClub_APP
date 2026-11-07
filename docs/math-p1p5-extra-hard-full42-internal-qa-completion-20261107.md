# Extra Hard P1/P5 — Internal trilingual/technical QA completion

**2026-11-07 · Issue #450 · DRAFT · no production writes or public release**

## Actual source review

A new privately preserved review archive covers **42 of 42** multi-part original
Mathematics AS 9709 written challenges (24 P1/18 P5, 14 internal skill tracks
with 3 per track). The previously drafted 30 were reviewed
individually against their English source conditions, RU and UZ translations,
step-by-step solutions, exact answers and grade-neutral answer presentation.
Independent second-pass **SymPy/SciPy computational checks passed 30/30**.
Examples of reviewed risks: P1 open upper interval, P1 domain exclusions,
tangency discriminants and normal slopes, sector/segment units, box
optimisation boundary, P5 without-replacement selection order, conditional
probability, binomial cumulative tails, geometric memorylessness,
the normal continuity correction and Russian decimal-comma separators.

This is **INTERNAL AI-assisted content/editorial review only**. An independent
Cambridge examiner or external human expert has NOT signed off.
As decided by the architect, work should not remain artificially blocked by
an unavailable third-party reviewer; nevertheless question publication is
a **separate owner GO**, not implied by these QA flags.

The tasks' mathematical conditions, translations, worked solutions,
answer keys, task IDs, individual content SHA256 fingerprints and academic
mapping are **identical** to the preceding reviewed-notation archive.
Only 30 QA-state/evidence records were changed from draft/pending to
approved. The 12 earlier approved records are preserved, not regenerated.
Now exactly **42 internally approved / 0 draft / 0 published**.

## Controlled private source and importer

The authoritative protected archive is in the owner's PRIVATE Library:
`/iClub_APP/Mathematics_P1_P5/Private_Question_Candidates/ExtraHard/iClub_Math_P1P5_ExtraHard_FULL42_INTERNAL_QA_20261107.zip`

New protected JSON SHA256:
`2283f0a35697349dac6825accd199e85fc72bb61d4ac5f8b4aca9e5adaeea77b`

Previous (historical/draft) protected JSON:
`28b8872f499b8f2a79d680675a5fb7083b5f0b734bc05fd4b13dd41ca6c79a78` — **must not be used for new staged import**.
The archive includes `full42_internal_qa_20261107.json` with 30
per-task review markers and the explicit no-external-review caveat.

Changes in this **DRAFT PR**:
- Existing public code `scripts/ops/p1p5-extra-hard-private-full42-check-v3.cjs`
  checks exact new private source SHA, 42 individual original content hashes,
  EN/RU/UZ presence, 24/18, 14×3 and strictly 42 approved/0 draft.
- `scripts/ops/p1p5-extra-hard-private-full42-stage-v3.cjs`
  accepts only this exact new private source, requires separate owner-GO
  and explicitly named database target to store the 42 protected rows.
  It leaves the bank release OFF and does not mark any task published.
- Synthetic-only disposable PostgreSQL17 test exercises exactly 42 internally
  approved rows under a transaction and must ROLLBACK with unchanged
  learner/history/control rows.
- The original 12-only v2 importer and v2 bank/attempt records are untouched.
  No plaintext prompts, answers or solutions committed to GitHub, CI logs
  or frontend assets.

## Next user-visible product milestone

A separate owner-authorized restricted **v3 staging** would store the verified
42 rows without exposing them. Once their protected state and owner-access
boundaries are checked, a separate final **publish/release migration and GO**
may enable the optional Math-only Extra Hard catalog. Existing P1/P5 core
and other subject data remain untouched. Do not execute live staging, flip
the bank version or delete student/test data on the basis of this DRAFT.
