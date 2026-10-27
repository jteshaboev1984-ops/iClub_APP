# Core Exam Prep: delayed-retest resumption and controlled-beta evidence, 27 October 2026

**Owner decision:** preserve both temporary QA access overrides and all existing user sessions until an explicit later access-transition decision. No automatic revocation. No fake reviewers.

**Observed, read-only production:**
- Eight scheduled P1 delayed retests are all past due; the eight corrections are `retest_due`, mapped to eight active weekly plans with a pending retest item. Eight distinct users, none with an existing retest authorization/session; the authorization is meant to be created only when the learner chooses Start. Zero completed retests is not proof the app is broken.
- 56 active P1/P5 sessions had no activity for >30 days (51 diagnostics, 5 learning), including 1 from a current beta account and 55 from outside current beta. Leave those responses and sessions resumable: no deletion, expiry, or silent completion.
- Global Core/Weekly QA-open overrides remain true. Active user scope was broader than the three current consented beta members. Do not revoke while users may have unfinished attempts.
- Live product release decision remains `NO_GO` without four real signed weekly reviews. The fail-closed QA-open mass-release guard was added independently by PR #370.
- AI globally ON but individual entitlement determines actual access; Mentor globally OFF; Mathematics paper-written learning OFF until approved RU/UZ criteria.

**Regression added in this package:** real `exam-prep-live.js` and `exam-prep-weekly-flow-adapter.js` render an actionable overdue retest with correct labels in RU, UZ and EN at 390/1280px; reject starting premature retest; prevent duplicate session starts on rapid double click. The fixture is synthetic and never calls live Supabase or accesses learner browser storage. This cannot replace signed-off authenticated beta browser validation.

**Remaining:** owner-authorized real learner journey observation from entry diagnostic through retest, genuine beta-week governance reviews, security-approved gradual closure of QA overrides, plus independent translations before written route activation. No mass expansion or forced historic session cleanup.
