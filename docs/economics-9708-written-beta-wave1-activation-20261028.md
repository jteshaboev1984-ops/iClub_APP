# Economics 9708 P2/P4 — controlled written beta activation
Date: 28 October 2026. State: INVITATIONS LIVE; NO AUTOMATIC LEARNER ASSIGNMENT.

## Deployment
- Production PR #378 merged to main, SHA 86fe01bef40f34f2d939dcf41e3d13f110c1e318; Vercel READY before invitation activation.
- Isolated GitHub Actions Economics Written Consent Beta Isolated Gate passed, run 40634784039.
- Applied migration ledger 20261028045112, iclub_econ_written_consent_beta_wave1_off_v1, matching source in supabase/migrations/.
- Applied with invitations OFF, then enabled only the singleton control after production readiness and approval preflight.

## Who can join
Exact active Maths beta canary cohort of three learners with existing generic beta consent, Economics selected among their subjects, and completed Economics P1 entry diagnostic. Maths beta consent by itself does NOT enrol them: each must press the separate explicit Economics consent button. 1 currently meets the diagnostic prerequisite; the others can finish it before joining.
Server enforces a capacity of three, serialised joins, owner-bound access, a 28-day entitlement, and one 12-step plan per consenting learner. Repeated join is idempotent. No new registration or activation is created by the administrator.

## Content
iClub editorial v3 candidate has 22 reviewed EN/RU/UZ tasks, P2 14 and P4 8. First wave: 12 release-eligible and 10 held OFF. Two versioned fictional source cards Isara and Nerava and 10 immutable source bindings. Older 22 drafts remain unchanged and unavailable. Learner practice tasks are P2.A.a–f, P2.B1.a, P2.C1.a, P4.A.a, P4.A.c, P4.B1 and P4.C1.
Writing is performed independently without fake auto-grading, mastery or mentor queue. Sources visible only on assigned, approved authenticated task; answer requirements remain optional.

## Tested
PostgreSQL fully rolled-back simulated joining and leaving: OFF default, missing consent denied, matching eligibility, 12 tasks, double-join replay, owner-only P2 Isara and P4 Nerava, real sequential progression, criteria by separate call, cross-user denial, leave revokes access without erasing advanced steps. After live invitation enable: eligible status true for exactly one currently qualified account, anonymous status not_authorized. All checks were rollback-only and no simulated student persisted.
Live after enable: 0 voluntary opt-ins, 0 written access, 0 written plans/items; active Math version intact. This is expected until a user explicitly opts in. Do not claim live student browser E2E before an actual voluntary enrolment.

## Reversal
To pause NEW joins: update the private singleton beta control enabled to false; this retains user progress and does not retroactively revoke existing entitlements. Existing plans can be individually revoked through approved operations when necessary. No changes to Math/Practice/Tours/localStorage.
Keep the three-seat limit until architect approves expansion. Keep the 10 held-back candidate tasks OFF until separately validated.
