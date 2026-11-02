# Mathematics AS P1/P5 — Stage D consolidated engineering evidence and production real-user boundary

**Snapshot date:** 2026-11-02 (UTC)  
**Issue:** [#450](https://github.com/jteshaboev1984-ops/iClub_APP/issues/450) · **PR:** [#467](https://github.com/jteshaboev1984-ops/iClub_APP/pull/467)  
**Exact tested PR candidate SHA:** `1cc6789657ad4774b216f8b7f5cbb5cdea2110f5`  
**Automation:** [Stage D consolidated evidence gate #41428628417](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41428628417) — **GREEN**, job `125221292095`; artifact `math-p1p5-stage-d-evidence`, id `13133506222`, JSON and Markdown report.

The Stage D tool is **an engineering evidence aggregator**, not a fake fourth academic test. It uses live GitHub Actions run metadata, job steps and the **same exact SHA** for three independent workflows, and refuses missing, failed, skipped, differently versioned, stale-green or unfinished evidence. Its standalone negative test suite also passed. Only the full three-workflow bundle can return Engineering **PASS**.

## Four independent release verdicts

| Independent decision | Current evidence and verdict | Meaning |
| --- | --- | --- |
| **1. Published content** | **Observed in production SELECT-only:** P1 has 32 `published` content versions and 370 published assessments; P5 has 38 `published` versions and 346 published assessments. The automated Stage D report intentionally says `NOT_ATTESTED` for production publication because GitHub CI does not access production Supabase. | Published supply exists. These counts are not proof of manually solving every mathematical question, all 81 skills or full academic quality. |
| **2. Isolated engineering E2E** | **PASS:** [real Math Chromium→JWT/PostgREST→PG17 #41428628313](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41428628313), [600/10 concurrency #41428628401](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41428628401), [disaster/rollback #41428628363](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41428628363). All **GREEN at exact SHA**. [Stage D gate #41428628417](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/41428628417) independently checked **18 mandatory execution steps** rather than just workflow status. | Technical CI on actual isolated application/API/database and fault tests passed; **not** hosted GoTrue or real Telegram device. |
| **3. Real-user beta evidence** | **BLOCKED / INCOMPLETE:** production canary 3 active users with 3 recorded consents, 2 users with real sessions (32 sessions, 30 finalized, 2 active; 2 started in last 7 days), **0 genuine authorized weekly reviews**. Current `development_data_state='real_monitoring'`, real monitoring epoch is set. | Actual usage exists but four real weekly mentor reviews, consented-device smoke, hosted GoTrue refresh and 72-hour monitored wave acceptance remain unproved. |
| **4. Mass release / governance** | **NO_GO** from `private.exam_prep_p3_01_mass_core_rollout_gate_v1('math_as_p1_p5_beta_2026_09_01')`. Separate beta expansion gate says `ready=false`, `reason_code='four_real_weekly_reviews_incomplete'`. | No technical CI result may override production gates or architect approval. |

**Read-only incident check:** 0 Sev0 since the real-review epoch and 0 *currently open or mitigating* Sev1 in the monitored cohort. These are current recorded incidents only; they do **not** prove absence of undiscovered problems.

**Production switches observed (not changed):** `rollout_state=controlled_beta`, `core_enabled=true`, `ai_enabled=true`, `mentor_enabled=false`, `kill_switch=false`, `qa_open_all_core=true`, `qa_open_all_weekly=true`. Both broad QA overrides require a future explicit, carefully planned access transition. **Do not change them automatically now**: existing beta and historic-user access must be preserved and the gate deliberately remains NO_GO.

## Exact trace and fail-closed protections

- New reusable pure classifier: `scripts/p1p5-stage-d-release-gate.cjs`. It accepts only exact 40-character candidate hashes, PR-event jobs from that hash, the **most recent** attempt for each workflow, three successful completed jobs and all 18 required completed successful steps. A previously successful attempt cannot mask a new failed one.
- Negative regression: `scripts/p1p5-stage-d-release-gate.test.cjs`. Handles wrong-SHA, missing run, pending run, failed run, missing/skipped step, stale success, recovery after failure, push-event contamination, invalid SHA, missing job evidence, and separation of human/mass NO_GO.
- New read-only GitHub automation: `.github/workflows/p1p5-stage-d-consolidated-release-gate.yml` on PR or explicit `workflow_dispatch`. It queries GitHub Actions via scoped `actions:read`, waits for the three independently triggered workflows and generates inspectable JSON/Markdown artifact. No Supabase keys, no hosted user database connection, no feature flags toggled, no mass GO action. Re-running the bundle requires the **same source SHA**.
- Existing three source workflows receive **path triggers only** so a change to the gate reruns all three expensive checks as one coherent release unit. Their actual exam-prep runtime, SQL migrations, correct-answer banks, user sessions and storage logic were **not** touched.
- This new gate is **technical Stage D progress**, not entire Stage C completion. The historical **15 canonical / 18 adversarial** model definitions are not all proven as whole longitudinal learner journeys; additional UI/time/locale and hosted-device evidence is not automatically resolved by a green summary.

## Actionable remaining gates (human and operational, not substitute synthetic tests)

1. Test actual hosted Supabase GoTrue token refresh and real Telegram/browser sign-in/out/resume using only **consenting real beta users** under the existing live cohort controls; verify no account/progress reset.
2. Collect **four real authorized weekly mentor reviews** and the true service-mode decisions through the existing operating model; do not insert dummy rows or grant the model reviewer rights. Test actual P1/P5 participation from at least two consented learners.
3. Independently observe required **72-hour real wave** and incident response. Confirm low-risk handling of historic users and temporary `qa_open_all_core/weekly` overrides; no hidden privilege removal.
4. Re-evaluate both **server-side** beta and mass gates read-only after the real evidence is present. The owner/architect explicitly approves any phased access change; no unconditional mass release.

**Current Stage D: IN PROGRESS** (automated engineering gate implemented and verified, real-user/governance blockers remain). Stage B and C remain IN PROGRESS. **Mass GO: forbidden.**
