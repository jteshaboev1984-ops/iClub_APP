# Mathematics P1/P5 — 2026-11-08 protected V4 Full42 academic rework checkpoint

**Issue #450 · ARCHITECT: revise weak Extra Hard questions independently · PRIVATE CANDIDATE · DRAFT/PENDING · PUBLIC NO_GO**

## Authoritative product and permission interpretation

The architect asked the assistant to correct the questions, and previously allowed real
staging/publication **only if they genuinely merit Extra Hard and everything is safe**.
That condition is not automatically met by the old V3 42/42 technical/answer review,
or by the new machine-assisted checks. The app is live: no existing learner
records, Practice, Tours, certificates, Core progress or localStorage may be deleted
or reset to accomplish the bank replacement.

**Normal written Core:** learner independently solves paper tasks; app does not
grade writing; marking criteria disclosure is optional and Next never requires
opening it. This P4-08 contract is unchanged.

**Optional Extra Hard V3 UI currently differs:** requires a typed nonblank
written response before revealing a worked solution, though it assigns NO
grades. Align the future published Extra Hard UX with the architect's written
learning rule, or obtain an explicit separate Extra Hard UX decision. This
checkpoint does **not** authorize modifying production UI.

## New owner-private candidate, separate from immutable original

- Library path **(PRIVATE; never place its contents in GitHub, CI or frontend)**:
  `/iClub_APP/Mathematics_P1_P5/Private_Question_Candidates/ExtraHard/iClub_Math_P1P5_ExtraHard_FULL42_v4_DRAFT_PRIVATE_20261108.zip`
- New **bank version**: `math-extra-hard-2026-11-full-v4` (UNRELEASED).
- New source JSON SHA256: `8f9d8aec32da6de43e9415f8ab2965b8d425809bc2e849e6e3d1f4a1ee612a88`.
- New private ZIP SHA256: `4fc65560d1bf6e6f4f35b1f366e2f3a243e022b6a1d6df2fe07b316aeb52a164`.
- Previous immutable original archive source SHA256:
  `2283f0a35697349dac6825accd199e85fc72bb61d4ac5f8b4aca9e5adaeea77b`.
  **DO NOT** stage or publish that V3 bank: independent content review found
  numerous standard/routine tasks and a real near-duplicate.
- **42 newly versioned problem IDs**, not in-place updates of prior IDs.
  24 P1 and 18 P5, 14 syllabus strands with exactly 3 tasks each,
  all prompts and detailed worked solutions in EN/RU/UZ.
- **42/42 prompts substantively reworked**: 40 original multistep exercises
  strengthened by original nonroutine linked reasoning, including six further
  second-level mathematical reasoning refinements; two exercises replaced
  entirely: one P1 volume-of-revolution problem (P3-only technique, not P1
  §1.8) becomes an inverse bounded-area P1 integration problem, and the
  repeated P5 geometric-distribution scenario is replaced by a distinct
  first-success divisibility/infinite-series challenge.
- Every new private `content_sha256` generated from all actual task
  fields (including new detailed solution). Previous originals were left
  untouched. `exact_answer` updated as well; old V3 keys are not reusable.

## Concrete validation, without overstating academic certification

The second-pass private Python/SymPy/SciPy plus exhaustive counting regression
recomputed **42/42 new challenge-specific numerical/symbolic facts** and
checked all 42 canonical content SHA values, keys, component counts,
internationalized fields, no exact/near-identical complete EN prompts,
syllabus-family coverage and absence of the P3-only rotation technique.
Negative and limiting parameter ranges, continuity-corrected inverse binomial
thresholds, statistical variance optima, nested conditional counts, two
geometric waiting times, fixed-point domains and endpoint multiplicities
were checked. Two numeric/localization issues were corrected before final SHA.
All local test results are in a **private** verification manifest inside the ZIP,
not in GitHub logs.

**This is an internal computational and editorial candidate, not a fully
independent human/Cambridge examiner difficulty certification.** All 42 task
states are deliberately:
`qa_math=pending`, `qa_languages=pending`, `qa_technical=pending`,
`lifecycle_status=draft`; bank flags `release_enabled=false`,
`academic_approved=false`. No one may relabel them as academically approved
solely because 42 source checks returned PASS. Localized numeric token audits
may warn about decimal-comma conventions or harmless additional prose;
full bilingual semantic proofreading is a separate signoff.

An independent item-by-item **Extra Hard difficulty rubric** remains required:
unfamiliar method selection, nontrivial linked inference, technically reliable
worked solution, legitimate P1/P5 2026–2027 syllabus level, and no near-duplicate
solution paths. The final score/decision must be recorded per new task ID
without exposing source content.

## Release, history, security and next stages

1. Protected **V4** candidate was stored in the owner-private Library, **NOT
   imported**. Keep V3 original and exact archive SHA immutable. Neither V3
   nor V4 is a replacement for historical student answers.
2. The current DRAFT #509 integrator and V3 staging/release scripts are pinned
   to the **old V3 SHA and bank**. Do **not** just replace their SHA constant.
   A separate **V4-specific**, version-safe, never-overwrite loader and
   atomic publish gate must be implemented only after academic acceptance.
   It must use new V4 task keys and verify actual DB source fields, not cached
   hashes alone, preserving parent P4-09 stale-hash/tamper safety.
3. Live Supabase read-only audit as of 2026-11-08 showed
   `private.exam_prep_extra_hard_tasks_v1` and
   `private.exam_prep_extra_hard_release_v1` **not deployed**, with no live
   Extra Hard RPC. Current DRAFT CI passes are isolated synthetic PG17 tests
   only, not evidence that production schema is migration-ready.
4. Reconcile migrations, snapshot/backup, recoverability, RLS/ACL, P0-16B
   unfinished writer/epoch security review, no mass/core rollout, no test-data
   cleanup; preserve `controlled_beta` until a separate GO.
5. **Only after** independent difficulty and trilingual review of the V4
   candidate + genuine deployed database preflight + release-safety checks:
   obtain an unequivocal new-SHA/staging-target authorization, private
   stage verified 42 V4 rows while release stays OFF; then independently
   authorize public Math-only publish/switch and a short noncredit UX smoke.
   Do not treat the architect's conditional statement as GO before those
   prerequisites succeed.

**CURRENT STATUS: V4 PRIVATE DRAFT CREATED AND 42 MATH CHECKS PASSED;
ACADEMIC DIFFICULTY SIGNOFF, UX ALIGNMENT, DATABASE/SECURITY DEPLOYMENT
AND PUBLIC RELEASE STILL NO_GO.**

Syllabus reference: Cambridge International AS & A Level Mathematics (9709)
2026–2027, official `https://www.cambridgeinternational.org/Images/697427-2026-2027-syllabus.pdf`.
