# P0-16B — Scoped real Paper writer-token epoch gate (DRAFT)

Issue #450 · 2026-11-05 · stacked onto PR #494 · PUBLIC NO_GO.

**Practical case:** learner leaves a browser tab open across a future, separately
approved Exam Prep state-version cutover. An unexpired signed access token
issued before that cutover must not start, answer or finalize against the new
version. A new token for the SAME learner must preserve previous Paper history.

The additive `writer_min_jwt_iat` field on existing private feature config is
**NULL by default and this patch never activates it**. Four server-side Paper
entry points check its signed PostgREST JWT iat only after existing owner/Core
authorization: authorize timed, start session, submit response, finalize timed.
The last route is the new P4-05 post-result stage rebuild writer.

After the full P4-05 signed six-Paper E2E, a disposable PG17 HTTP regression
checks valid old and freshly issued JWTs for the same learner, P1 and P5,
the four write RPCs, retained read access to saved results, no duplicate
finalization, no stage/skill/response writes while denied, and the cutoff's
return to NULL. No fabricated score, no new user time limit or mentor gate.

**Still OPEN:** Other public writers and trigger-to-trigger/dynamic/Edge routes
must be mapped and fenced; client version refresh, real release backup and
architect-approved cutover are separate. This is not a completed P0-16B
or a permission for a rollout.

No production SQL, main merge, Vercel deploy, feature/cutoff activation,
beta cleanup, learner-data deletion, Practice, Tours, certificates or other
subjects are authorized. DRAFT PR #493 is a separate partial metadata audit.

## 2026-11-05 practical Core continuation

The same OFF-by-default guard now covers **six additional everyday
learner-side write entry points**: next diagnostic, ordinary session finalize,
governed written-step finalize, written Next, weekly action authorization,
and weekly plan regeneration. The existing common session-start/response
guard protects all question types. Tests use the same signed learner/token
epoch and assert identical P1/P5 persisted row fingerprints before and after
old-token rejection. Other Core writer functions and server triggers remain
separate open P0-16B coverage, not an invented complete audit.

## Projection-read writer edge repaired

The ordinary `get_exam_prep_state_safe_v1(text)` response previously invoked
`private.rebuild_exam_prep_state_v1(uuid,text)`, which deletes/reinserts
derived skill and stage rows. A stale but signed JWT could therefore write
via a screen-refresh **read** during the future epoch cutover, even after
scoping the 10 explicit write RPCs. The new shared epoch predicate skips
that rebuild only when the opt-in epoch is stale, while returning already
stored P1/P5 component and skill projections. Genuine signed owner HTTP E2E
now checks both old-token reads, the unchanged stage/skill-row fingerprints,
and resumed full Paper idempotency using a newly signed token. The cutoff
still defaults NULL and remains unset in production.

## The actual Stage-0 dashboard also writes on read

Two more normal learner displays, `get_exam_prep_placement_safe_v1` and
`get_exam_prep_diagnostic_progress_safe_v1`, call the placement rebuild
which can change stored placement/access-gate projections. The same
opt-in epoch now skips those writes when the JWT is old while returning
previously saved P1/P5 placement and diagnostic facts. The genuine signed
HTTP test checks both endpoints plus the unchanged placement and
access-gate row identities, in addition to objective stage/skill state.
