# Mathematics P1/P5 — P6 real student access channel, feature OFF

**2026-11-05 · Architect's practical milestone · Issue #450 · DRAFT**

Prelaunch implementation only: registered users who actually selected **Mathematics**
as study **or** competitive will be eligible for Mathematics Core in the
**separately approved** `rollout_state='mass'` plus
`public_math_core_enabled=true` state. `public.user_subjects` +
active `public.subjects.subject_key='mathematics'` is source-of-truth; the
helper never grants access to someone who selected only Economics or Chemistry.

All existing controlled-beta entitlements, per-user weekly enrollment,
three-learner AI entitlements/consent, disabled Mentor, member results and
practice data remain unchanged. A separate central kill switch still wins.
In mass mode **temporary `qa_open_all_core` and `qa_open_all_weekly` do
not grant universal access** and must both be OFF before public Math access.

Current code should not rely on `rollout_state='controlled_beta'` to mount
the existing UI, progress view and weekly flow when the API says authenticated
Mathematics Core is available. The new optional `mass` mode is admitted
only through the same already existing capabilities path.

**Not activated:** the new flag defaults false and no migration updates
rollout state, existing users, subjects, AI grants or production. Prelaunch
cleanup remains separately approved and future; NO_GO remains until
all other academic content and short practical signed E2E are accepted.
Do not run live DDL/DML, deploy, merge or reset any learner here.
