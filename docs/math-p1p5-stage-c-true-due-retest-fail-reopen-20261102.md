# Mathematics P1/P5 — Stage C genuine delayed-retake pass/fail and reopening

**Date:** 2026-11-02  
**Tracker:** [#450](https://github.com/jteshaboev1984-ops/iClub_APP/issues/450)  
**PR:** [#464](https://github.com/jteshaboev1984-ops/iClub_APP/pull/464)  
**Exact executable candidate:** `4f06e03aed9327223794255a7f6e7dc02d066b73`  
**Main real browser + server PG17 CI:** [41417328909](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41417328909), job `125184259158` — **GREEN**.  
**P2-78 600-learners/10-mentor isolated stress:** [41417328965](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41417328965), job `125184259320` — **GREEN**.  
**P2-79 backup/recovery/rollback rehearsal:** [41417329104](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41417329104), job `125184259255` — **GREEN**.

## Exact results and method

The previously GREEN source-backed `strong-p1` / `strong-p5` synthetic learner matrix (`supabase/tests/p1p5_stage_c_asymmetric_learning_correction_rollback.sql`) now continues **past** a genuine wrong-learning session and its real server-opened correction. It executes actual learner RPCs to authorize/finish remediation, confirms early retest authorization is denied, advances the governed P2-68 synthetic clock by exactly seven days, checks that elapsed time generated zero objective evidence, authorizes a genuine delayed retest, and completes **both** contrasting outcomes:

| Source scenario and real server outcome | Result |
| --- | --- |
| `ADV-03-RETEST-DELAYED-FRESH` analog: P1 remediation + after-due correct retest | actual correction status `resolved` |
| `ADV-02-RETEST-FAILED` analog: P5 remediation + after-due **all machine questions wrong** retest | actual correction status `reopened` |
| Both initial pre-due retest attempts | denied as `exam_prep_retest_too_early` |
| Real correction audit events `retest_passed` and `retest_failed` | exactly one each tied to the finalized retest session |
| Evidence created **only** by seven days of clock advancement | 0 rows |
| Other component objective L2 progress after remediation/retest | unchanged |
| Previously earned `strong-p1` / `strong-p5` verified L2 | 7 P1 / 6 P5 prior to retest path |
| Failed P5 skill receiving automatic L2 credit from its failed retest | forbidden and not observed |
| New synthetic user data after final rollback | 0 residual users; original two disposable CI users restored |

CI exact outcome marker:

`STAGE C ACTUAL P1 DELAYED PASS P5 FAILED REOPENED RETEST PASS | 1 | 1 | 2 | 0`

The P5 wrong-answer injection **submits ordinary objective answers through `public.submit_exam_prep_response_safe_v1`** and finalizes via `public.finalize_exam_prep_session_safe_v1`, without inserting `is_correct`, changing mastery or directly modifying the correction table. It validates the existing production retest reconciliation action log. The P1 correct retest likewise uses the existing server-graded published pack. Thus this is beyond the earlier **static manifest** and **Stage-0-only** evidence.

The tests execute in a transaction-local PostgreSQL connection reusing the P2-69 *temporary helper definitions*, not a separate new HTTP browser per synthetic learner. The same exact candidate also ran the independently proven genuine Chromium→signed HTTP/JWT→PostgREST/PG17 browser journeys and complete prior Stage C suites in the workflow. **This distinction matters**: neither row above claims actual learner Telegram device usage or live GoTrue refresh.

### Safety and remaining tasks

- The test hard-requires `current_database()=postgres`, `iclub.e2e_isolated=true`, exactly the two known initial CI identities, zero legacy Practice/Tour/certificates, no real beta reviews, disabled optional layers and no global QA override. It registers/uses a P2-68 active synthetic calendar, with bounded +7-day advancement that the protected server accepts.
- The academic changes are transaction-scoped and **rolled back**. Separate P2-78 load and P2-79 disaster/rollback suites reran against the exact candidate and passed without paid external AI calls.
- No application JS/HTML/CSS, migration, production Supabase data, entitled user, learner history, locale preference, certificate or feature switch changed.
- Stage C remains **IN PROGRESS**: this verifies the **specific** P1 delayed pass and P5 failed/reopened cases, **not** all 18 adversarial source event contracts or all 15 canonical longitudinal journeys. Long interruption/revalidation, weekly plan/target revisions, retired content, time-zone boundaries and more real-device UX remain to be proven at the same rigor.
- Stage B hosted GoTrue refreshed authentication, real consenting Telegram/browser learner test, four genuine weekly reviews, and authorized 72-hour real wave remain missing. Stage D remains NOT STARTED; production mass release **NO_GO**.
