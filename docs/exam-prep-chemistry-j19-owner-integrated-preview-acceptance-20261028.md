# J-19 — Owner acceptance of integrated Chemistry preview

Date: 2026-10-28

## Attestation
The project owner was asked to verify **three specific non-mutating items** on the latest integrated preview and explicitly replied **«3/3 ОК»**:

1. Mathematics and Economics open without visible UI errors.
2. Chemistry is visible but Exam Prep assessments and Tutor remain unavailable.
3. RU / UZ / EN switching and phone responsive layout work correctly.

The verified protected preview was:
https://i-club-lgij9k27x-jasurbeks-projects-c5451f97.vercel.app
Deployment `dpl_8uv2zfcJgcAEYapGvdfpUU2xomdn`, pinned commit `b595a4ce1f9e782508ed7d83f6d9e18619054069`, status READY.

This is **owner-reported 3/3 visual/navigation smoke acceptance**, not independent automated browser instrumentation, authenticated end-to-end examination, server backup restore proof, or an authorization to enable Chemistry learning for students.

## Separation of authorities
The owner independently approved academic review and content rights for Chemistry in J-18. The owner has **not** given Chemistry learner publication GO, nor agreed to turn on Core, Entry, P1, Recheck, P3, P5, Tutor or invite a new cohort.

Production risk boundary: do not overwrite student data, clear localStorage, reset learning history, approve learners, change release switches or publish Chemistry.

## Integration restrictions
- GitHub PR #388 must be synchronized to current main and pass relevant safety checks; original historic GitHub Actions had stale static asset cache-version assertions. Do not blindly relabel failed checks as passing.
- Backup/restore rehearsal remains unproven. Never restore production in order to run rehearsal.
- All Chemistry release conditions stay OFF until an independently authorized future rollout.
