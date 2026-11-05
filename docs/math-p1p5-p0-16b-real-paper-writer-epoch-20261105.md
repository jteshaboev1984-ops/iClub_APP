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
