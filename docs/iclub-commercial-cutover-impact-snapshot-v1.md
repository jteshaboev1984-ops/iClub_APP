# iClub commercial cutover impact snapshot v1

Date: 2026-10-06  
Source: read-only aggregate queries against current production.  
Purpose: validate grandfathering strategy before any tariff enforcement.  
No learner record was changed.

## Current production shape

Total users: 1,443  
Total user_subjects rows: 2,044

Users by number of legacy user_subjects rows:
- 0 rows: 128 users
- 1 row: 672 users
- 2 rows: 574 users
- 3+ rows: 69 users
- maximum observed: 5 rows

Legacy rows by mode:
- Competitive: 1,753
- Study: 291

Users by Competitive count:
- 0 Competitive: 249
- 1 Competitive: 635
- 2 Competitive: 559
- more than 2 Competitive: 0

School / non-school split:
- school learners: 1,145
  - 4 have 0 subject rows
  - 570 have 1
  - 534 have 2
  - 37 have 3+
- non-school learners: 298
  - 124 have 0 subject rows
  - 102 have 1
  - 40 have 2
  - 32 have 3+

Legacy subject rows by subject:
- Mathematics: 782 Competitive + 67 Study
- Economics: 324 Competitive + 80 Study
- Informatics: 279 Competitive + 67 Study
- Biology: 204 Competitive + 37 Study
- Chemistry: 164 Competitive + 40 Study

## Why automatic Free assignment would be unsafe

If legacy user_subjects rows were incorrectly treated as tariff access:
- 643 existing users have more than one row and would appear above the proposed Free one-subject limit.
- 559 existing users currently have two Competitive rows and would appear above the proposed Free one-Competitive limit.
- 10 users have more than three legacy rows and would appear above the proposed Plus three-subject limit.

Those numbers are **not** a valid reason to remove access, because user_subjects is not the complete current access contract. In particular, 124 non-school users have zero rows while current app logic still lets non-school learners study/practice active subjects.

Therefore there is no safe deterministic rule such as:
- “take the first row”;
- “keep the pinned row”;
- “keep the most recent row”;
- “keep Mathematics”;
- “convert every current user to Free and trim extras”.

Any such rule would silently change existing product behavior.

## Cutover rule confirmed by the data

Existing users must be grandfathered as **legacy_preserved**.

For those users:
1. current active-subject access continues unchanged;
2. no legacy row is deleted or downgraded;
3. no Practice/Tour/Exam Prep/recommendation/certificate/history data is changed;
4. tariff subject limits begin only after an explicit learner selection/confirmation flow;
5. Pro can move directly to all-active-subject commercial access because it has no study-subject count cap;
6. Free/Plus finite slots require explicit subject selection before migration_state becomes migrated.

## Rollout order

Safe order:
1. deploy dormant lifecycle/access schema;
2. keep subject_limits_mode=off;
3. enable shadow mode only for controlled migration preparation;
4. capture one versioned grandfather baseline;
5. verify snapshot counts and preservation digest;
6. expose subject-choice UX without blocking legacy users;
7. observe shadow outcomes and edge cases;
8. only after explicit approval consider enforced mode for migrated users;
9. never auto-enforce finite subject limits on legacy_preserved users.

This snapshot is evidence for architecture/QA only and contains no learner-identifying data.
