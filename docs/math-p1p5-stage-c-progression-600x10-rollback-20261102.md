# Mathematics P1/P5 — Stage C actual earned progression, 600/10 scale and rollback

**Checkpoint:** 2026-11-02  
**Issue:** [#450](https://github.com/jteshaboev1984-ops/iClub_APP/issues/450)  
**PR:** [#463](https://github.com/jteshaboev1984-ops/iClub_APP/pull/463)  
**Exact tested candidate:** `5bdefc480d64998a6b6c5e3719cbbadc28249716`  
**PG17 / Chromium / real local PostgREST:** [GREEN #41408598269](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41408598269), job `125156201648`.  
**P2-78 600 / 10 concurrency & service transitions:** [GREEN #41408598294](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41408598294), job `125156201326`.  
**P2-79 disaster recovery / rollback:** [GREEN #41408598264](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41408598264), job `125156201416`.

## Distinct real results

A new guarded rollback-only PostgreSQL script, `supabase/tests/p1p5_stage_c_asymmetric_learning_correction_rollback.sql`, uses the existing **immutable P2-67** canonical source profiles `strong-p1` and `strong-p5`. It creates two distinct owned synthetic learners under a registered active P2-68 controlled clock, performs authentic server-authorized published Stage-0 diagnostics in **both** P1 and P5, and builds earned L2 credit from actual published learning items submitted and finalized through public Exam Prep functions, using only existing P2-69 **temporary engineering helper definitions**. There is no hardcoded grade/stage/mastery and no fabricated correction record.

| Source profile | Earned real-server objective L2 | Other component L2 before / after | Actual newly opened correction case from wrong learning | Other component learning sessions |
| --- | ---: | --- | ---: | ---: |
| `strong-p1` | **P1: 7** | P5: **0 → 0** | P1: **1** | P5: **0** |
| `strong-p5` | **P5: 6** | P1: **0 → 0** | P5: **1** | P1: **0** |

Exact CI result marker: `STAGE C SOURCE-ANCHORED P1 P5 ASYMMETRIC LEARNING CORRECTION PASS`.

The P1/P5 learning setup is an **isolated test-only direct assessment authorization**, rather than a genuine weekly-plan client authorization. Positive weekly flow, positive mixed/section/paper and all Chromium browser paths are independently proven in earlier parts of the **same** green HTTP job. The new asymmetric progression loop itself calls real public DB functions inside disposable SQL, **not** separate HTTP browser sessions for each strong-learner case. A wrong MCQ answer is deliberate test evidence, but the correction case and mastered levels come from original server logic.

### Release-safety and cleanup

- The new script refuses any nonlocal DB, unexpected users, QA-open Core/weekly bypass, AI/Mentor enabled state, beta review or legacy practice/tour/certificate data. The P2-68 synthetic virtual clock is registered, transitioned to `running`, and initialized before any evidence event can be stamped.
- **All synthetic changes are inside one explicit `BEGIN ... ROLLBACK`**. The final postflight marker `STAGE C ASYMMETRIC LEARNING + CORRECTION ROLLBACK RESTORED TWO USERS PASS` proves exactly the previous two CI users and no test-run ledger / synthetic identity residue.
- All previously validated signed HTTP/JWT, P1/P5 actual Math Chromium 12 locale/viewport flows, security/first-write concurrency and 33 initial-profile baselines reran green on this exact candidate.
- The *existing* P2-78 test re-executed 600 synthetic learners / ten active mentor scopes with fallback/AI isolation and governed cleanup, no paid AI provider calls; the *existing* P2-79 recovery/disaster test re-executed its simulated recovery and previous-revision rollback. These are separate exact-candidate CI runners, **not** a claim of actual live production rollback or 72-hour monitoring.
- The two test fixes before final green were: (a) PL/pgSQL parenthesized CASE expression; (b) guarded P2-68 registered synthetic run and initialized clock. The protected DB rejected an uninitialized test run as designed. No app runtime defect was established, so no application code or production migration was altered.

### Scope still open

Stage C remains **IN PROGRESS**. The two source-anchored progression cases do not close all **15 canonical / 18 adversarial full event contracts**. The 33 source profiles have **Stage-0 baseline** evidence in PR #462, but the longer deterministic states (failed/reopened retests, 30+ day interruption, content retirement, stale auth and plan actions, focus/visibility comparability, plan budget revisions, locale formulas) still require specific end-to-end behavior tests. P2-78/79 are existing dedicated simulations revalidated on the candidate, not a new 33-learner longitudinal simulation.

Stage B's **hosted GoTrue session refresh** and consented **real Telegram WebApp on actual learner devices** remain open. Human weekly reviews, real beta wave and 72-hour live monitoring have not been simulated and must not be fabricated. **No production Supabase writes, no real learner progress/Practice/Tours/certificates/localStorage changes, no mass-beta activation. Mass release is NO_GO.**
