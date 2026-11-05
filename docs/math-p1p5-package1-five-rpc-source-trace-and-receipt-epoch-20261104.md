# Mathematics P1/P5 — Package 1: five newly introduced client RPCs, permissions and regression scope

**4 November 2026 • Draft PR #469 • Issue #450 • Not production release authorization.**

The original Stage A source-to-RPC trace tracked exactly 61 existing Mathematics API entrypoints. Package 1 introduced **five** additional RPC routes in the isolated Exam Prep client; the source audit correctly failed until each new route was explicitly documented and reviewed. This addendum does not waive the 61 old checks.

| Exact new RPC | Client route / purpose | Server permission and invariant |
| --- | --- | --- |
| `get_exam_prep_personal_horizon_safe_v1` | Mathematics Exam Prep personal P1/P5 exam horizons after completed diagnostics | Owner-scoped Core entitlement; independent P1/P5 completion timestamps, school/centre-confirmed appointment fallback, date evidence not an official Cambridge grade or readiness |
| `save_my_exam_prep_exam_appointment_v2` | Explicit learner save of existing operational exam appointment | Owner-only, one paper at a time, rejects mismatched/invalid dates or past dates; no tour/practice/results write, never silently edits another paper |
| `get_exam_prep_study_schedule_safe_v1` | Retrieve learner's elective minutes/day and study days/week | Owner-only; read projection, not time-on-platform measured activity, not a lesson access gate |
| `save_exam_prep_study_schedule_safe_v1` | Explicitly save learner-selected cadence | Owner-only, validates minutes/day x days/week and existing hours, no automatic weekly budget rise, no academic state or account-profile reset |
| `claim_exam_prep_periodic_study_report_safe_v1` | Once-only completed weekly/monthly in-app report delivery | Owner-only Core, real completed diagnostic anchor and real finalized sessions, row uniqueness by **user + program_version_id + diagnostic_anchor_at + period kind/end**; no daily popups, no inferred study hours or algorithmic mastery credits |

**Key privacy/retention improvement (draft-only):** the receipt storage is additionally scoped by `program_version_id` and `diagnostic_anchor_at`. This allows a new post-beta completed diagnostic to claim a new report without reusing/suppressing receipts from an older diagnostic cycle. A duplicate request for the *same* period and cycle is still idempotent even across devices. Historic receipts remain protected, and no retention/deletion permission is conferred.

**Source obligations:** All five APIs must stay in the existing reviewed Mathematics `exam-prep/exam-prep-api.js` transport, with no browser direct `.from()` table access. Their corresponding functions are confined to the additive draft SQL migrations `20261103023000`, `20261103024000`, and `20261103025000`. The new source-to-RPC trace must continue to reject any sixth undocumented entry, missing old endpoint, subject bleed, disappearing answer ACK or written self-grading claims. The genuine signed JWT/PostgREST/PG17 test remains separate from source-guard acceptance.

**Release blockers independent of this change:** draft PR #470's learner-selected dates supersede the older school-confirmed-appointment UX; the two routes must be reconciled at final combined release. The central production Core guard currently checks rollout/entitlement but does not enforce a new learning epoch on all write RPCs. Retained beta progress and old signed tabs remain a NO_GO cleanup risk until the separate governed epoch, one-shot authorization, encrypted backup and explicit architect GO are verified. Do not merge PR #469 into main on the basis of this source trace alone.
