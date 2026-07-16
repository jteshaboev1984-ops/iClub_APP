# iClub AI demo — learner next-step map

Branch: `demo-ai-premium`

## Product decision

The learner must never reach a content screen without a clear continuation path. This does not mean adding a large card everywhere. The interface uses one of three patterns:

1. one primary button;
2. a compact “Next step” card;
3. a recommended marker on an existing action.

The personal learner report is useful and is included as an on-demand Pro screen. An automatic weekly push or email is not included in this demo. The report updates after completed practice and closed-tour evidence and can later become a Profile-level multi-subject report.

## Screen map

| Screen / state | Recommended continuation | Implementation |
|---|---|---|
| Subject Hub Free, no diagnosis | Complete the 7-question diagnosis | Compact next-step card → Practice |
| Subject Hub Free, diagnosis exists | Repeat after reviewing mistakes | Compact next-step card → Practice |
| Subject Hub Plus | Review the latest incorrect answer with AI | Compact next-step card → contextual AI review |
| Subject Hub Pro | Open trajectory first; report is secondary | Primary → Trajectory, secondary → Learning report |
| Practice start | Complete the diagnosis without hints | Supporting note + existing Start button |
| Practice question | Select an option and submit; AI opens only afterwards | Supporting note + existing Answer button |
| Free result with errors | Review mistakes before recommendations | Existing Review card marked “Start here” |
| Free result without errors | Continue to the subject / next practice | Compact next-step card |
| Plus result | Review the first incorrect answer with AI | Compact next-step card → contextual AI review |
| Pro result | Open trajectory | Existing Pro analysis card labelled “Next step” |
| Question review | Open recommendations after reviewing answers | Next-step card → Recommendations |
| Recommendations | Reinforce the material in another practice | Next-step card → Practice |
| Tutor empty state | Choose one suggested academic question | Existing suggested prompts |
| Tutor verified/live/fallback answer | Use the answer actions; practice reinforcement is the closing action | “Next step” label above answer actions |
| Tutor no-source state | Edit the question | Inline action |
| Active Tour blocked state | Ask a safe general-theory question | Inline theory action |
| Tutor History | Select a past request or return to the current request | Existing history rows and context control |
| Pro trajectory — Summary | Move to Plan after reading the conclusion | Existing “Go to plan” action |
| Pro trajectory — Skills | Move to Plan after reviewing skill states | Added full-width Plan action |
| Pro trajectory — Plan | Start the prepared set | Added full-width Start set action |
| Skill evidence sheet | Check the skill in the prepared plan | Added Plan action |
| Personal learning report | Open the recommended learning plan | Primary action → Pro Plan; secondary → Subject Hub |
| Plan comparison | Select Plus or Pro | Existing plan buttons |
| Scenario / technical panels | Presentation controls, not learner flow | No learner recommendation required |

## Personal learning report

The Pro report contains:

- reporting period;
- number of recorded learning activities;
- practice count;
- closed-tour count;
- latest diagnostic result;
- latest five activities;
- repeated errors;
- positive signals;
- historical errors not yet rechecked;
- three skills from the targeted set;
- reliability of the diagnostic conclusion;
- one recommended next action.

The report does not:

- show the learner name outside Profile;
- claim overall Economics mastery from one attempt;
- send a weekly notification in the demo;
- use an LLM to determine skill state or next action;
- connect to production Supabase.

## Runtime records

The hidden technical state records:

- `next_step_audit`;
- `personal_report.delivery = on_demand`;
- `personal_report.weekly_push = false`;
- the report evidence sources.
