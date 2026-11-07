# Mathematics Extra Hard Full42 — guarded publish preparation (no live release)

**2026-11-07 · Issue #450 · DRAFT · NO LIVE SQL / NO RELEASE GO**

The owner-private fully internally-reviewed source holds 42 original tasks
(P1 24, P5 18; 14 iClub syllabus tracks), pinned to JSON SHA256
`2283f0a35697349dac6825accd199e85fc72bb61d4ac5f8b4aca9e5adaeea77b`.
The source archive remains only in the owner's private Library.

The next *separate* step after the owner-authorized private 42-row import
is a controlled publish and release switch. The new
`scripts/ops/p1p5-extra-hard-v3-release-gate.cjs` checks:
- source hash plus 42 exact per-question content hashes, all QA approved internally;
- all 42 records already staged, 24 P1/18 P5, all still approved/unpublished;
- previous v2 release selector OFF, no mismatched existing learner attempts;
- a **different explicit architect PUBLIC GO and two target confirmations**.
Then only one DB transaction may mark the 42 v3 records published and
switch the Extra Hard release pointer to v3; a failed check aborts everything.
No content/answer strings are embedded in public Git, in SQL source,
frontend, or action logs. This is not a general rollout of Mathematics Core.

**Synthetic-only CI dry run:** generates 42 artificial 1+1 questions in an
isolated two-user PG17 instance, exercises the exact publish/switch logic,
then ROLLBACKs before any result persists and checks the previous database
snapshot is identical. No actual student data or source archive enters CI.

This PR does NOT execute any live SQL, upload actual protected task content,
activate a bank, merge into main, deploy Vercel, publish exam grades,
enable AI, or clean test data. Final production GO remains a separate
architect decision after source-matched restricted v3 staging and a brief
real Math-only smoke test.

**Review provenance:** 42 tasks have internal mathematical and EN/RU/UZ
editorial acceptance, 30 of them after an additional 30/30 independent
SymPy/SciPy second pass. This is not an external Cambridge examiner review.

## 2026-11-07 — Exact stored-content fidelity before any guarded release

The earlier release gate compared each approved owner's source `content_sha256` with a
**stored `content_sha256` column**. That cached column is not proof that the
actual database prompt or solution still matches the privately reviewed source:
a database row could change without updating the cached digest.

The stacked isolated P4-09 fix in DRAFT PR (linked from Issue #450) makes
the **same atomic release transaction** copy the exact owner-approved source
fields into a temporary source table, with a local client-only mode-0600 CSV
deleted after use. Before it is allowed to publish, it locks the candidate
task rows and release selector, then checks each of the 42 stored rows for
exact equality on task key, bank, component, skill, syllabus section, book
reference, all three titles, prompts and solutions, exact answer and original
source kind, plus an active canonical program version. The existing cached
SHA, QA and 24/18-count checks remain additive and fail closed.

The content is **not** embedded in GitHub SQL, workflow logs or stdout.
An independent **synthetic-only** PostgreSQL 17 adversarial test changes
one stored `prompt_i18n` but deliberately retains the same saved hash,
then proves publication refuses the modified row and rolls back all dummy
data. The normal 42-task synthetic publish+switch continues to require
its transaction rollback and unchanged snapshot. Both modes run with
CI-only self-generated tasks, not the real protected bank.

This is an engineering correction, not a request to publish content,
approve a Cambridge grade, require a Mentor, or alter P1/P5 Core.
**All release flags remain OFF, all real questions remain private.**
Separate, explicit owner authorization for protected 42-row staging and
for live release still applies, as does the independent unfinished
P0-16B security work and deferred test-only beta cleanup. P4-08's
written-work contract remains authoritative: the app never grades a
learner's independently solved written Mathematics exercises; criteria
disclosure is optional and Core may continue without it.
