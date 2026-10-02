# TEMPORARY — P3-02 Synthetic Scale + AI Execution Plan

Status: ACTIVE  
Started: 2026-10-02  
Delete only after all completion gates below are green and production-safe postchecks are complete.

## Hard invariants

- Do not fabricate, insert or backfill real beta weekly-review evidence.
- Synthetic evidence must never satisfy the real P3-01 mass-rollout gate.
- Existing users, localStorage, Practice/Tour history, ratings, certificates and real Exam Prep evidence are immutable.
- P1 and P5 academic state remain independent.
- Core must remain usable with AI OFF and Mentor Care OFF.
- AI can explain only approved deterministic context; it cannot mutate academic state.
- Mentor Care remains assignment-scoped and independent of Core/AI.
- All production-facing changes require CI first, then governed deployment, then production postcheck.
- Every synthetic production-safe validation path must be run-scoped, identifiable and cleanable without touching real data.

## Work packages

### [ ] A. Preflight + synthetic isolation
- Revalidate current main, production counts, feature state and P3-01 real gate.
- Audit existing synthetic run engine, identity provenance, virtual time and cleanup.
- Add only missing run-scoped isolation/cleanup controls.
- Prove synthetic rows cannot contribute to real weekly-review denominator.
- Audit the exposed Biology temporary staging table and close it only through a separate safe decision.

Acceptance:
- synthetic test data is unmistakably tagged to one run;
- cleanup is exact and fail-closed;
- real P3-01 remains NO_GO for only real-evidence reasons;
- no legacy/user-history delta.

### [ ] B. Core scale + resilience
- Reuse existing Stage 0–6 synthetic engine.
- Run 15-profile regression plus 100/300/600 learner scale.
- Test retries, duplicate submit, idempotency, recovery, rollback, P1/P5 parity, AI OFF and mentor absent.

Acceptance:
- no academic-state drift;
- no queue leakage;
- no legacy deltas;
- Core remains independently functional.

### [ ] C. Mentor Care synthetic lane
- Validate 600 learners / exactly 10 active Mentor Care assignments.
- Validate assignment, queue, written review, second check, pause/reassign and absence behavior.
- Verify 590 unassigned learners create zero routine mentor tasks.

Acceptance:
- exactly assigned learner scope only;
- mentor outage/capacity hold never freezes safe Core/AI.

### [ ] D. AI shadow/pre-live audit
- Reconcile GitHub and deployed exam-prep-ai Edge Function.
- Verify server-owned entitlement/runtime/generation gates.
- Verify answer-key, active-assessment, source allowlist, component firewall, budget/concurrency/timeout, audit and fallback.
- Keep real learner AI OFF.

Acceptance:
- deterministic context only;
- no academic writers;
- server-only provider secret;
- deployment reproducible from main.

### [ ] E. Synthetic real-provider canary
- Use registered synthetic identities/run IDs only.
- Enable provider path only inside a service-owned synthetic QA gate.
- Exercise progress_summary and weekly_plan_narration for P1/P5 in RU/UZ/EN.
- Record latency/tokens/cost/fallback without changing academic state.

Acceptance:
- real model output is useful and source-bounded;
- generated output is rejected safely when validation fails;
- academic state before/after identical;
- real learners cannot self-grant access.

### [ ] F. AI adversarial safety
- Prompt injection, fake privilege/mentor, answer-key request, active-assessment request, cross-component request, unsupported number, unsafe markup, long prompt, unsupported locale, no_source, timeout/429/provider outage.
- Run across RU/UZ/EN where applicable.

Acceptance:
- blocked/fallback/no_source behavior is correct;
- no secret/answer-key leakage;
- no Core degradation.

### [ ] G. Governed AI value expansion
- Open interactions one at a time only after approved source coverage:
  1. established_error_explanation
  2. repeated_error_summary
  3. theory_explanation
  4. multilingual_explanation
- Do not invent diagnosis when deterministic mapping is absent.

Acceptance:
- each enabled route has source coverage + golden eval + safety eval;
- at least three meaningful AI-specific value flows pass.

### [ ] H. AI learner UX
- Validate AI panel, actions, loading, no_source, unavailable, timeout and retry.
- RU/UZ/EN mathematical equivalence.
- Mobile 360x800, 390x844, 430x932 and desktop.
- No internal engine terms in learner copy.

Acceptance:
- learner understands AI explains but does not change results/state;
- no broken Core flow when AI is OFF.

### [ ] I. A-to-Z service-transition rehearsal
- Core-only -> AI Assist -> Core-only.
- AI outage while Core continues.
- Mentor assignment/pause/reassign independent of AI.
- Compare deterministic state under identical raw evidence.

Acceptance:
- same evidence => same P1/P5 academic state in every service mode;
- capability transitions do not rewrite history.

### [ ] J. Cleanup + final held-ready state
- Clean runtime synthetic data by exact run manifest.
- Verify no orphan auth/public/private rows.
- Preserve only reusable scenario definitions and QA evidence needed for regression.
- Keep real P3-01 governed by real weekly evidence.
- Keep real-user AI OFF until separate explicit AI activation decision.

Acceptance:
- synthetic runtime residue = 0;
- real user/history counts unchanged;
- Core production healthy;
- AI stack technically ready but real-user activation remains explicit.

## Completion rule

This plan is complete only when A–J are all green, independent CI/audit passes, production invariants are rechecked, synthetic runtime data is cleaned, and no real release gate has been bypassed. After that, delete this temporary file in the closing governed change.
