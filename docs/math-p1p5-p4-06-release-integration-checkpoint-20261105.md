# Mathematics P1/P5 — P4-06 integration / release-boundary checkpoint

**5 Nov 2026 · Issue #450 · DRAFT PR #494 stacked on DRAFT PR #492 · PUBLIC NO_GO.**
This is a source-backed integration checklist, **not a release authorization**.

## Evidence accepted so far

- [Full authentic signed E2E #42021090022](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/42021090022) **SUCCESS** at actual code SHA `96b974241518bac7c74594734e409c80b9ef5f24`. An isolated PostgreSQL 17 and local PostgREST/Chromium executed P1/P5 Stage0 diagnostics, published objective learning+retests, owner-signed timed catalog/authorization and six distinct full Paper finalizations (three per component), plus the second required timed section in each component, with **real Stage 3→4→5→6 operational progression**.
- All 51 written task answers across six full Papers were preserved as *ungraded* content (P1 3×10, P5 3×7). No student, AI or app assignment of essay marks; `score_comparable` false for the six and no verified Cambridge grade.
- **Negative**: fourth signed, fully skipped/blank full Paper each P1/P5 was saved only as a historical attempt, not execution evidence; **3 executed among 4 stored** per component. Same-key signed finalizer replay stayed idempotent and old full-paper milestone / Stage6 / `INSUFFICIENT_EVIDENCE` remained intact.
- Same run also completed owned/foreign/anon/expired-JWT checks; existing browser routines exercised EN/RU/UZ on mobile-like 385px and desktop 1280px, noncredit written review, lost ACK, browser reopen, concurrent retries, kill-switch, synthetic identity cleanup and protected legacy tables. Source test harness is separate from app production.
- Earlier exact-code [72/72 Actions SHA `8b0ded7a650c2ee453f76009984f9086784e057b`](https://github.com/jteshaboev1984-ops/iClub_APP/pull/494) tested P4-03/P4-04 **before** later P4-05 changes; **must not be copied as green for the new integration SHA**.

## New P4-06 integration source guard

`scripts/math-p1p5-p4-06-release-integration-guard.cjs` and
`.github/workflows/math-p1p5-p4-06-integration-guard.yml` enforce:
the 4 additive migration scopes and immutable result/score boundaries,
service-only access to private functions, source-fingerprinted Stage3/4
rewiring and Stage5/6 operational/assessed split, post-ledger stage refresh,
3+3 genuine Paper forms, 1+1 fully skipped negatives, and cleanup ordering.
The guard includes mutation-negative tests of its own safety assertions.
It has **no database credentials** and **cannot approve release**.

## Integration gates to finish before claiming P4-06

1. Independently run all existing PR source CI against the **new exact combined SHA** (not old 72/72). Check P2-36, P2-80, P2-78, P2-79, Stage D, and signed JWT/Chromium PG17.
2. Review the **stacked PR #492 + #494** migration order, object ACL/search_path, first-commit/old-JWT epoch protection, triggered write graph, future retest selector and old preserved answers. Record actual failures and fix only safe regressions.
3. Read production catalog metadata (SELECT only) and compare expected new functions **ABSENT** from production, flags and approved grade thresholds unchanged; verify `main` and parent PR heads unmerged.
4. Preserve `P0-16B` as an independent **open** security requirement in [DRAFT PR #493](https://github.com/jteshaboev1984-ops/iClub_APP/pull/493), including post-finalizer state rebuild writer classification and old-tab/old-token epoch fencing. Complete rollback/backup readiness and eventual release approval separately.
5. Architect previously **DEFERRED beta cleanup**. Never execute live DML/DDL, merge, Vercel deploy, modify progress/localStorage, or publish the five pending versioned D10-08 replacements as part of this audit.

**Status now: P4-05 isolated SUCCESS; P4-06 full CI/integration OPEN; PUBLIC NO_GO unchanged.** The academic 81-skill time estimates, original 12 Extra Hard and five unmerged duplicate replacements remain separately tracked, not silently declared fixed.


## 2026-11-05 — P4-06 exact-code integration evidence, duplicate CI still pending

**Candidate code SHA `72e89a41fdc7b871900c84b1a7b5ea92e4d93355`**: after temporarily targeting `main` for full CI **only**, **74 of 75 Actions SUCCESS**, **0 failures**, and one *duplicate* signed JWT/PostgREST/Chromium E2E [#42029601940](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/42029601940) still **IN_PROGRESS** at the latest verified check. Do **not** state 75/75 or complete the final P4-06 all-runs acceptance until that run completes. The PR has been returned to its original DRAFT stacked base #492; no merge/deploy/live SQL.

Independent completed critical Actions at **this exact SHA**:
- [Real signed JWT/PostgREST/PG17/Chromium #42029597270](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/42029597270) **SUCCESS**; logs explicitly confirm P4-05 3 genuinely completed P1 and 3 P5 Paper, 1 genuinely blank/fully skipped P1 and P5 negative, three-language viewport/browser safety, real stage 3→4→5→6, genuine governed synthetic cleanup and new P4-06 runtime guard **PASS**.
- [P4-06 source-only integration/mutation guard #42029596925](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/42029596925) **SUCCESS**.
- [P2-36 current schema #42029597482](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/42029597482), [P2-78 concurrency 600/10 #42029596814](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/42029596814), [P2-79 disaster recovery/rollback #42029597402](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/42029597402), [P2-80 independent audit #42029596936](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/42029596936), [Stage D consolidated #42029597177](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/42029597177): **SUCCESS** each.
- New `supabase/tests/p1p5_p4_06_runtime_writer_acl_disposable.sql` runs after real signed Paper positives/blank negatives but **before** synthetic cleanup and verifies five private service-only ACLs, SECURITY DEFINER/empty search_path, genuine authenticated finalizer ACL, correct immutable timed-ledger→stage-rebuild order, separation of operational Stage6 from human-scored grade and untouched legacy tables. No new production migration added for P4-06.
- Migration manifest (657 SQL migration files on exact source SHA) remains chronologically ordered; parent 20261104110000 self-mark prohibition precedes four additive child migrations 20261105153000/154000/155000/160000. PR #494 diff contains only Mathematics P1/P5 scripts/migrations/CI/docs. Avoid merging DRAFT 162-file PR #492 as part of this verification.
- READ-ONLY live Supabase catalog: both new P4-02/P4-04 private functions and the P4-05 finalizer hook ABSENT live; approved graded-writing thresholds **zero**. Live feature config still **controlled_beta**, `core_enabled=true`, `ai_enabled=true`, `mentor_enabled=false`, `kill_switch=false`. These observations are not rollout approvals and were not modified.
- `main` unchanged `bdb98e0c85f7ffdf0b15736068d79259fbb810d3`, parent #492 unchanged `925fdffe44f5c63c20009a4798ed2f2fb35b0c78`. No user responses, local progress or retained audit data rewritten.

**Separate OPEN safety dependency P0-16B / DRAFT PR #493:** the newly added `public.finalize_exam_prep_timed_safe_v1`→`private.rebuild_exam_prep_state_v1` **post-ledger privileged writer edge** must be included in the final combined write/trigger/old-authorization-epoch graph; PR #493's existing metadata graph (129 trigger bindings, 70 transitive DML candidates) is explicitly only a partial prior inventory, not a security or release sign-off. Validate old-tab/old-JWT epoch fencing, nested routes and retained audit history with signed PG17 E2E before any controlled deployment/rollout change. Do not impose new learner restrictions.

**Next exact action:** check final duplicate run #42029601940, record its real conclusion, then finalize P4-06 engineering checkpoint. PUBLIC **NO_GO** remains unchanged; production deployment, merge, beta cleanup, user-data mutation and any public Cambridge grade are explicitly not authorized.
