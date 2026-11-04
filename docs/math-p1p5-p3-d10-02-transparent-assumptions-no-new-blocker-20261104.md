# D10-02 — transparent Mathematics time assumptions, no new learner blocker

**Issue #450 · 2026-11-04 · DRAFT / NO_GO · source: preceding exact-HEAD 70/70 PASS PR #483.**

## Architect direction: no unapproved blocker

The architect explicitly directed that **new blockers must not be introduced without prior agreement**. Accordingly, D10-01 [PR #484](https://github.com/jteshaboev1984-ops/iClub_APP/pull/484), which would have suppressed existing time-choice recommendations and refused their owner-authorized server calls, was **closed unmerged**. Its tests and history are retained for possible discussion, but its proposed new restriction is **NOT** part of the current release candidate.

This D10-02 branch instead makes the already existing voluntary iClub estimation method comprehensible to learners, while preserving **all three architect-approved choices**, the original existing owner-authenticated RPCs and no automatic schedule change. **This is NOT an academic approval of personal time norms and creates NO new GO/NO_GO condition.**

## What the old estimate actually means

In the current draft `20261103041000_exam_prep_simple_cambridge_source_time_estimate_v1.sql`, the source is **historical Cambridge 9709 Schemes of Work (from 2020)**, providing suggested *topic-guided teaching hours*, P1 eight topics **10+10+10+4+14+10+16+16 = 90 h** and P5 five topics **14+4+12+8+12 = 50 h**. These are NOT independent self-study durations and are not the 2026–27 Cambridge whole-AS guidance of approximately 180 guided hours. Therefore dividing them among the 81 iClub skill codes cannot establish validated personal skill minutes.

The iClub approximation distributes topic teaching hours equally over canonical skills in each topic and applies explicitly unmeasured remaining-work factors: **1.00 unobserved**, **0.80 observed with unresolved correction**, **0.60 observed but unconfirmed without correction**, **0.00 confirmed objective coverage**. Reported low/high sensitivity values use **0.75× / 1.25×** the resulting point estimate; this is a scenario range, **not** a statistically validated confidence interval. The estimator is useful only as an optional rough planning aid. It does **not** certify advanced written/method mastery, account for all timed/full-paper or revision logistics, measure home-study minutes or predict a Cambridge grade.

Accepted academic reality remains separate: independently recorded P1 45 / P5 36 skill evidence, exact own exam dates, and one shared learner-chosen Mathematics budget. Existing D09-05 weekly feedback advises next actions from actual skill evidence. The user may study **more** than planned; no lesson access is capped. Only an explicit user action can save a new schedule or budget. Old user results, academic evidence, practice and tours are never rewritten.

## Implemented in this draft

- RU/UZ/EN timeline footnote now **explicitly names 2020 historical teaching-hour provenance**, explains that this is **not a measured independent-study requirement or readiness guarantee**, and confirms that the learner alone changes the time.
- The three approved choices remain available when the existing source-based estimate reports a shortfall: **Оставить моё время / Принять рекомендуемое / Указать другое время**, with original authenticated owner controls, optimistic profile revision and total-budget checks unchanged.
- No new migration, RPC, RLS policy, access flag, content publication restriction, calendar limit, AI dependency, grade/score/attempt change or alternative learning plan. This is a narrow copy-and-regression draft, not a secret change to academic policy.
- Additional source-aware RU/UZ/EN unit assertion verifies the 2020 provenance and confirms the three study-time actions are not suppressed.

## Outstanding research without an imposed stopper

Original 81 skill independent learning/revision intervals remain unmeasured and should be researched further; the next method should separate observable task phases, time in a lesson vs outside learning, and genuine objective vs written evidence. This academic inquiry proceeds without adding an unsupported GO/NO_GO gate here.

The architect's original 12 Extra Hard (six P1 and six P5) are retained as a product decision. A review of GitHub PR #474 commit `34621e1a595c6bb0a06afb17e87168c6f4d0c315`, previous candidate branches and conversation summaries establishes their previous exploratory existence but **not** their exact EN/RU/UZ problem statements and solutions. No replacements or fake restored payload have been introduced; the protected task bank stays disabled/empty as before.

**Preservation:** main, production Supabase, live Vercel, localStorage, protected answer keys, profiles, legacy Practice/Tours, rating/certificates, other subjects, and student progress untouched. No merge/deploy/reset/public release authorized. Existing public release status remains NO_GO, without a new release prerequisite being created by this change.
