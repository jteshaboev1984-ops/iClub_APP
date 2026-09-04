# Exam Prep Controlled Beta — Core-first Amendment

**Program:** `math_as_p1_p5`  
**Decision date:** 2026-09-04  
**Scope:** P0-16 / P1-01 controlled beta governance  
**Status:** implementation amendment to the older fixed/mixed-cohort wording

## Final operating rule

- `planned_size` is a **capacity**, with a maximum of 12 learners; filling all 12 seats is not a prerequisite to start.
- The initial controlled-beta cohort may start **Core-only** once at least 3 real allowlisted learners have explicit consent and all technical/safety gates are green.
- AI Assist and Mentor Care representation is **not** a prerequisite for the first Core canary. Those service modes are added and tested only when their independent readiness gates are satisfied.
- Additional learners may be enrolled incrementally after the Core canary starts, up to remaining cohort capacity. New members must be assigned to a future wave, explicitly consent, and be approved before activation.
- AI Assist activation remains blocked unless the AI runtime/readiness gate is green.
- Mentor Care activation remains blocked unless assignment/capacity/readiness gates are green.
- Existing Tours, Practice, ratings, certificates and learner history remain outside the Exam Prep beta mutation boundary.
- Learner consent is mandatory. Project-owner approval is not learner consent.
- Revocation by an active learner remains fail-closed and pauses live beta access; a not-yet-active future-wave learner may withdraw without stopping already-live Core learners.

## Current production roster at the amendment point

The production cohort `math_as_p1_p5_beta_2026_09_01` has capacity 12 and currently contains 3 Core candidates in wave 1. The cohort remains draft and feature access remains OFF until the consent and approval sequence is completed.

## Roadmap interpretation

This amendment changes only the controlled-beta enrollment/release interpretation. It does not lower academic evidence standards, content-runway requirements, component isolation, rollback requirements, or the separation between Product Content-Complete, Syllabus Closure and Learner Exam Ready.
