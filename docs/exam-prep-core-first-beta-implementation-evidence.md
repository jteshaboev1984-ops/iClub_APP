# Core-first controlled beta — implementation evidence

**Date:** 2026-09-04  
**Working branch:** `exam-prep-p0-host`

## Verified gates

- P0-15 isolated alpha remained GREEN after the Core-first governance change.
- P1-02 content runway gate remained GREEN.
- P1-03 timed-paper gate remained GREEN.
- P1-01 weekly-governance gate passed with the learner-consent/Core-first overlay.
- P0-16 controlled-beta gate passed the legacy mixed-service matrix, current-schema sequencing, Mentor hold point, 12-seat capacity boundary, learner consent, authenticated self-consent, and the new Core-first incremental matrix.

## New acceptance scenario

The P0-16 regression now proves the operational path required for the first real cohort:

1. create a capacity-12 cohort;
2. stage 3 Core learners in wave 1;
3. require explicit consent from all 3;
4. approve without artificial AI/Mentor placeholders;
5. activate only the 3 Core learners;
6. add a later Core learner as a future-wave candidate without stopping the canary;
7. require consent and approval for the added learner before activation;
8. allow a later AI candidate to be staged/approved while still blocking AI activation until the AI runtime gate is ready;
9. roll back all synthetic state with zero residue.

No production learner was activated while proving this path.
