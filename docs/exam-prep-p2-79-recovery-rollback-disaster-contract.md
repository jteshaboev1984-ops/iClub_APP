# P2-79 — Recovery / Rollback / Disaster Rehearsal Contract

Status: validation contract for P2-79. This document does not authorize a real cohort expansion, AI enablement, Mentor Care enablement, destructive rollback, or production data repair.

## Purpose

P2-79 proves that Exam Prep can fail closed, recover and replay without rewriting learner academic truth or touching legacy Practice/Tours/history. It is an engineering rehearsal only. It does not prove real traffic behavior, real learner UX, or real mentor capacity.

## Source-faithful recovery law

The approved architecture and release plans require rollback-first, additive changes. Feature/capability rollback must preserve evidence/history. Database rollback is logical: stop using or supersede the affected capability/content while preserving historical evidence and auditability. AI outage must fall back to deterministic Core. A deployment rollback uses a previous known-good repository/deployment snapshot. Existing Practice, Tours, ratings, certificates, localStorage and pending-operation state remain protected.

The existing recovery engine remains authoritative for learner interruptions. Recovery may change pace, planning metadata and revalidation requirements. It cannot lower evidence standards, transfer P1/P5 mastery or change a stage merely because time passed or a learner was absent.

## Required rehearsal cases

The isolated P2-79 gate must cover all of the following on the exact candidate SHA:

1. Kill switch during an active governed session. Server access fails closed; after restoring the switch, the same idempotency key resumes the same session rather than creating a duplicate.
2. Failed migration in disposable CI. The intentionally failed subtransaction leaves no partial schema object and the current Core contract remains usable.
3. Interrupted synthetic validation run. The run becomes terminal with a recorded failure code and remains eligible for governed cleanup.
4. Interrupted cleanup. A simulated cleanup failure resumes through the existing failed -> pending -> running -> clean lifecycle. A second cleanup call is idempotent and leaves one cleanup summary audit event.
5. Bad/stale content version. A previously issued authorization cannot start against retired content; restoring the exact governed content status permits a clean replay without creating a session during the bad interval.
6. Expired/stale client authorization. Expired authorization is rejected; a fresh authorization succeeds; duplicate retry resumes the same authoritative session.
7. AI outage. AI is disabled without changing Core access or deterministic academic state. Provider generation remains disabled and the CI gate makes zero paid provider calls.
8. Learner recovery. A source-defined interruption creates separate P1/P5 recovery cases while preserving evidence standards and forbidding automatic stage downgrade.
9. Deployment rollback rehearsal. The previous known-good commit is checked out separately and its Exam Prep/legacy-storage boundary is re-run before the current candidate is accepted.
10. Final replay and cleanup. A fresh synthetic run can complete and clean after the simulated failure without manual repair; zero P2-79 synthetic residue remains.

## Protected state

P2-79 must assert that these deterministic academic objects are unchanged by outage/recovery operations unless the scenario explicitly creates new valid academic evidence:

- evidence events;
- P1/P5 skill state;
- component placement;
- stage state.

Legacy Practice attempts/answers, Tour attempts/answers, ratings cache and certificates must remain unchanged inside the rehearsal. Browser rollback checks must preserve legacy storage keys and must not introduce destructive localStorage/sessionStorage behavior into the live Exam Prep module.

## Production boundary

P2-79 is test-only. It introduces no production migration. Its database scenarios run only with `p279.isolated_db=true` and finish with `ROLLBACK`. Production must remain:

- `rollout_state = controlled_beta`;
- Core ON;
- AI OFF;
- Mentor OFF;
- kill switch OFF;
- AI generation OFF / runtime shadow;
- zero active P2-79 synthetic identities.

Any failure keeps P2-79 IN PROGRESS. P2-80 may start only after the exact candidate and post-merge P2-79 gates are GREEN and the normal three-seed Core dress rehearsal remains GREEN.