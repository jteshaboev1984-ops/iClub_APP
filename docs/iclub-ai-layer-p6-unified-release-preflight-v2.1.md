# iClub AI Layer v2.1 — §75 Unified P6 release preflight after trilingual and accessibility audit

**Date:** 2026-10-14. **Branch:** `qa/iclub-ai-layer-v21-20261012`. **Status:** NO-GO.

## Engineering findings (QA only)

The existing `qa/ai-layer-v21-p6-release-preflight.cjs` now checks the real six-route, 18-reply trilingual editorial candidate against unchanged `index.html`, `app.js`, `i18n.js`. It independently runs the in-memory four-button accessibility transform and repeats the source-based semantic audit on the candidate. On the current source the result is:

| Check | Source-bound result | Release meaning |
|---|---|---|
| 6 existing navigation routes | 6 recognized | Routes only; no published navigation instructions |
| Draft instructions | 18/18 source-consistent | Editorial review and rights not approved |
| Current literal tab accessible names | 9 mismatched view × locale combinations | Accessibility remediation recommended |
| QA candidate's four tab labels | 0 static caption conflicts | Candidate only; native Chrome/assistive review still required |
| Bottom landmark | Hard-coded `Bottom navigation` | RU/UZ localization/landmark policy not approved |
| Home next actions | No authoritative cross-subject planner | BLOCKED |
| Live P6 source/RPC, beta cohort and paid provider | Not approved/installed by this QA | BLOCKED |

The preflight has **no** `deploy`, `publish`, `applyMigration` or `enableGlobalAi` action. It reports `NO_GO` in all circumstances and is explicitly not a substitute for sign-off. It also rejects missing/altered editor packets, changed routes, malformed copied text, unexpected locale mix and a broken accessible-name preview contract.

The updated `qa/ai-layer-v21-p6-release-preflight.test.cjs` checks each blocker, including `navigationLandmark: UNTRANSLATED_REVIEW_REQUIRED` and `chromeAssistiveTechSignoff: NOT_GIVEN`. Existing offline CI includes these tests.

## What can happen next without production authority

- Independently review the 18 RU/UZ/EN instructions, publish only after authored rights and content sign-off.
- Approve accessible landmark labels and execute a real screen-reader verification on an authorized protected Preview.
- Decide the academic meaning, allowed action types, prioritization and tie-breaking rules for cross-subject Home next-actions; then create a server-owned planner with owner-bound academic evidence and fresh entitlement checks.
- Verify current production security, billing policy, active assessment blackout, server source publication, cohort entitlement and preserved Mathematics Tutor parity against the then-current deployment.
- Await the **complete** relevant CI execution (Node, Deno, scratch Postgres, Chrome, integrity freeze) and obtain explicit architect release authorization. A passing QA test never authorizes production itself.

## Conservation statement

Changes are confined to QA tooling, regression tests, review documents and QA workflow. No active app `index.html/app.js/i18n.js` changes, no Supabase migration, no history/certificate/progress rewrites, no new real accounts, no Vercel Preview or production deployments, and no paid AI calls. **Global AI OFF / NO-GO.**
