# Core-first beta — next operational gate

The code path is ready for a real 3-learner Core canary only after all three production candidates explicitly consent. Deployment of the governance/self-consent migrations must leave Exam Prep fail-closed. After deployment, verify `rollout_state=off`, Core/AI/Mentor all false, `kill_switch=true`, cohort still draft, 3 candidates still present, and zero active entitlements. Then collect 3/3 authenticated learner consent, approve the cohort, activate wave 1 only, and begin the first-72h P1-01 monitoring window.

Do not fabricate consent, activate AI Assist, activate Mentor Care, or bypass the existing rollback/incident gates.
