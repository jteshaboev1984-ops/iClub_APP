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
