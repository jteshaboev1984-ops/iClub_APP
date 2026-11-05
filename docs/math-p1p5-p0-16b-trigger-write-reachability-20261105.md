# Issue #450 — P0-16B: real trigger writer reachability inventory (partial)

**5 Nov 2026 · Package 0 safety continuation · metadata-only production SELECT · no GO or cleanup**

## Baseline and evidence, not a release claim

Re-read the architect-approved v2.0 workplan, the PR #468 execution ledger,
its P0-16A live 580-function catalog audit, the P0-20 old-JWT signed HTTP
checkpoint, and the subsequent **DRAFT PR #492** (71/71 exact-SHA checks).
The original D10-08 five-duplicate content fix remains DRAFT and unmerged.
We do **not** restart or replace the earlier E2E work.

Two **new SQL-only reproducible inspections** were executed through the
connected Supabase read-only catalog query surface against the current live
project. They inspected `pg_trigger`, `pg_class`, `pg_proc` and
`pg_namespace` metadata. No user, session, answer, question text, key,
consent or entitlement rows were read or mutated.

| Observed fact | Result |
| --- | ---: |
| Exam Prep private tables with non-internal triggers | **83** |
| Trigger bindings across those tables | **129** |
| Distinct bound trigger-function OIDs | **52** |
| Bindings whose function source contains a direct DML pattern | **66** |
| Distinct such function names/OIDs | **10** |
| Bindings reaching DML text through up to 12 levels of qualified public/private helper calls | **70** |
| **Previously invisible nested-only DML candidates** | **4** |
| Trigger bindings on sessions, stage states, responses, plans and retests combined | **17** |

**Crucial distinction:** 66 does **not** mean 66 independently vulnerable
endpoints. Of those 66 bindings, **57** use the same audit helper,
`private.exam_prep_audit_row_change_v1`. A trigger binding is not the
same as a callable RPC or an attack path. Further, absence of the pattern
does **not** establish a trigger as side-effect-free.

The four new *qualified-call* write candidates not detected by scanning
their trigger function body alone are:

1. `exam_prep_correction_cases` / `exam_prep_z_plan_transition_sync_v1`.
2. `exam_prep_retest_events` / `exam_prep_z_plan_transition_sync_v1`.
3. `exam_prep_sessions` / `exam_prep_z_plan_transition_sync_v1`.
4. `exam_prep_human_review_recommendations` / `exam_prep_recommendation_enqueue_v1`.

The larger scan was increased **from 7 to 12 qualified-call edges** after
the first pass hit its depth ceiling (7). The second live SELECT returned
maximum observed depth **11**, 129 roots, 70 transitive DML candidates,
and 4 nested-only candidates. That is deeper coverage, **not proof of
exhaustive SQL call tracing**.

## Files and reproducibility

- `supabase/tests/p1p5_v2_package0_trigger_writer_inventory_readonly.sql`
  — catalog summary, canonical source fingerprints and grouped function candidates.
- `supabase/tests/p1p5_v2_package0_trigger_transitive_write_routes_readonly.sql`
  — trigger-rooted qualified nested helper graph and four newly observable cases.
- A local no-secret static guard checks both SQL files remain strictly SELECT-only,
  catalog-scoped, and preserve NO_GO labels. It does not substitute for runtime E2E.

**Explicit limitations:** source regex can match comments/string literals or
miss dynamic/unqualified/overloaded calls; a trigger can call another
trigger via table DML; other schema/Edge/REST direct table writes are not
in this graph. There is no evidence here of active release-epoch enforcement.
No claim that existing 52 trigger functions must be changed is justified;
classification precedes implementation. Source counts may change in future
migrations and must be compared with the final combined PR source, not
hard-coded as permanent production invariants.

## Exact next P0-16B work — existing scope, no new learner blocker

- Combine actual PR #468 and current unmerged PR #469–#492 migration/writer
  changes into a **versioned, owner-classified** source/write/trigger manifest.
  Separate Core learner state from Mentor, consent, AI grants, other subjects,
  retained audit logs and release-time one-shot state.
- Verify real mutation boundaries through AUTHENTIC signed JWT/PostgREST,
  isolated PostgreSQL 17, two clients and stale session tokens, including
  session finalization, retest, correction and the four nested-only trigger
  candidates. Require exact-source tests and protect existing records.
- Only after complete review design the additive, disabled-by-default
  epoch/maintenance fence and its old-authorization conflict behavior.
  Neither this inventory nor a green test grants release or data-cleanup
  permission. The architect's prior instruction to defer prelaunch cleanup
  is preserved.

## Safety

`main`, live Supabase schema/rows, Vercel, flags, AI entitlements,
Mathematics Practice, Tours, certificates, students' progress and other
subjects were **not changed** by this metadata audit. The original
release NO_GO state continues unchanged; no extra learning quota, timetable
restriction, app-visible text or new approval condition was introduced.
