# Exam Prep Parallel-Build Amendment — 2026-09-07

Status: **APPROVED BY PROJECT OWNER**

This amendment records the Project Owner's explicit operating decision for Cambridge AS Mathematics Exam Prep P1+P5.

## Decision

Engineering, content, AI, Mentor Care, Stage 3–6 tooling, QA and release-hardening work must continue in parallel and must **not wait for real learners to accumulate beta evidence or for any elapsed monitoring period**.

The Master Implementation Plan remains a planning framework, not a rule that forces idle engineering time. The Project Owner may change sequencing based on current circumstances.

## Safety boundary that remains unchanged

- The live iClub APP, existing Practice/Tours, ratings, certificates and learner history must not be reset, rewritten or broken.
- P1 and P5 remain academically and technically separate components: P1 = 45 internal canonical skills, P5 = 36.
- Synthetic fixtures and isolated tests may be used to validate later-stage logic without manufacturing real learner evidence.
- Engineering may prebuild and deploy additive, dormant or independently gated capabilities before learners reach the corresponding stage.
- No synthetic/test result may be written into a real learner's mastery, placement, evidence, retest, readiness or mentor decision history.
- AI remains non-authoritative: it may explain/personalize only; deterministic server state remains academic authority.
- Mentor Care remains assignment-scoped and must not become a dependency for Core.
- Optional capabilities may be developed and validated while their learner-facing entitlement/feature flag stays OFF or independently gated.

## Operating instruction

Do not pause implementation merely because real learners have not yet produced the evidence expected by a later planning milestone. Continue with the next technically safe work package using isolated fixtures, additive schema, dormant feature flags and regression tests. Real learner evidence is used later for product/academic calibration, not as a prerequisite for continuing engineering work.
