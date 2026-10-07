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
- Tour recommendations: 572
- Tour recommendations fingerprint: 390dc2bcc96708e14b0a1735eed6b4d7

The reset/publish function recalculates the protected Tour fingerprint inside the same transaction before and after the Mathematics Practice reset and bank switch. Any difference aborts the whole transaction.

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

Owner decision (2026-10-07): legacy Mathematics Practice history does **not** need to be preserved. The 411 attempts / 4074 answers above are therefore reset scope, not protected data.

Practice-derived recommendations are also reset scope. Latest READ-ONLY count: **791** Mathematics recommendations with `source_type='practice'`. The **572** Mathematics recommendations with `source_type='tour'` are protected and must remain.

Dependency audit of the 490 current Practice question IDs:
- 4 are referenced by historical Tour memberships; those question rows must remain even after Practice cleanup.
- those 4 currently have no Tour answer or Tour session-answer references;
- 39 Practice-derived legacy evidence rows and 7 Practice skill-map rows reference legacy Practice questions and may be removed with the Practice reset/cleanup;
- no current legacy Practice question is referenced by Exam Prep assessment items, Exam Prep session items, Exam Prep content metadata or question-version links.

Physical question deletion is delayed until after the new bank passes smoke QA. Cleanup deletes only Practice-only question rows and automatically retains any row with Tour or another protected dependency.

## Release conclusion

The live baseline currently matches the controlled-release expectation:
- 7 active Practice pools;
- 490 active legacy memberships;
- zero active Practice/Tour overlap;
- protected Tour history is fingerprintable;
- the legacy Practice data above is explicitly disposable under the owner-approved reset policy;
- no Practice v2 database migration has been applied yet.

Release remains blocked until additive migrations, invisible staging, read-only preflight and controlled runtime deployment all pass.
