# Mathematics Practice v2 — Production Baseline

Date: 2026-10-07  
Mode: READ ONLY  
Production writes: NONE

## Protected Tour baseline

- Tours: 14
- Tour memberships: 300
- Tour attempts: 149
- Tour answers: 2477
- Tour session answers: 0
- Tours fingerprint: ddc7b31582a978ceb75ab45c825ecd2b
- Tour memberships fingerprint: 6d90602876f86adae3d9f04b06930d1a
- Tour attempts fingerprint: 6f980b884d615d7a79f02eb6152d9a79
- Tour answers fingerprint: 03edc51c7d0a6c4701b5b48ab6da6d09

The publish function recalculates the same protected fingerprint inside the release transaction before and after the Practice membership switch. Any difference aborts the release.

## Current Practice bank

| Practice | Pool | Active | Total rows |
|---|---:|---:|---:|
| 1 | 15 | 70 | 70 |
| 2 | 11 | 70 | 124 |
| 3 | 16 | 70 | 70 |
| 4 | 14 | 70 | 70 |
| 5 | 12 | 70 | 70 |
| 6 | 13 | 70 | 70 |
| 7 | 17 | 70 | 70 |

Active learner-facing total: **490**.

Practice 2 already has 54 inactive historical membership rows. Therefore the release must switch exact active membership IDs rather than assume every pool row is current.

## Separation and history

- Active Practice questions overlapping active Tour questions: **0**
- Existing Mathematics Practice attempts: **411**
- Existing Mathematics Practice answers: **4074**
- Distinct Mathematics Practice users: **167**
- Current Mathematics v4 main sessions: **0**
- Current Mathematics v4 drill sessions: **0**

Old Practice history stays stored. Practice v2 uses new question IDs, so the old bank does not mark new questions complete.

Legacy question rows are not physically deleted during release because they still have historical/support references.

## Release conclusion

The live baseline currently matches the controlled-release expectation:
- 7 active Practice pools;
- 490 active legacy memberships;
- zero active Practice/Tour overlap;
- protected Tour history is fingerprintable;
- no Practice v2 database migration has been applied yet.

Release remains blocked until additive migrations, invisible staging, read-only preflight and controlled runtime deployment all pass.
