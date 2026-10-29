# iClub AI — Edge route inventory and source-of-truth contract v1

> **Status:** verification work in progress (documentation only).
> **Observed:** 2026-10-29, production web deployment and Supabase Edge Function metadata.
> **Tracker:** [Temporary master plan and progress — issue #412](https://github.com/jteshaboev1984-ops/iClub_APP/issues/412).
> **Scope:** documentation of existing routes; no change to frontend, database, auth, budgets, or provider settings.

## Product contract

There is **one learner-facing iClub AI Tutor**, not separate competing chat windows.
A click can use (a) a reviewed provider-free prepared answer, (b) a deterministic, server-owned learning context, or (c) a narrowly authorized provider call for explicit learner-written follow-up.
Academic evidence, marks, certificate eligibility, assessment status, progression, and leaderboards remain exclusively server-owned. Protected active assessments and unavailable review content must be fail-closed.

A route being deployed does **not** imply it is accessible to learners or approved for general release. An Edge gateway setting does **not** by itself establish authentication: assess the complete handler, delegated RPC permissions, and current database capabilities.

## Deployed route inventory (operator-verified snapshot)

| Edge route | Intended responsibility | GitHub source available? | Comparison to deployed source |
| --- | --- | --- | --- |
| `exam-prep-ai` | Governed Exam Prep AI assistance and server-context narration | Yes | **Exact match** |
| `practice-ai` | Governed Practice AI explanation | Yes | **Exact match** |
| `iclub-ai-practice-prepared` | Provider-free, authorized Practice explanation bridge | Yes | **Exact match** |
| `iclub-ai-practice-freeform` | Budgeted learner follow-up after Practice | Yes | **Exact match**, including auxiliary module |
| `iclub-ai-v21-prepared` | Provider-free general/product guidance and guarded academic delivery | **No** | Await repository traceability |
| `iclub-ai-v21-freeform-beta` | Limited source-grounded General Help follow-up | **No** | Await repository traceability |
| `iclub-ai-paid-canary` | Restricted operator validation of paid-provider path | **No** | Await repository traceability |
| `iclub-ai-qa-global` | Restricted QA-only assistance path | **No** | Await repository traceability |

**Verification method:** compare each checked-in file with the actual source files returned by Supabase for the corresponding deployed Edge function, byte for byte. Four deployed routes passed; in the multi-file Practice Freeform route, both files passed. This is source parity evidence, **not** proof of runtime functional safety.

**Legacy clarification:** `supabase/functions/global-ai/index.ts` exists in GitHub, but `global-ai` was not present in the deployed function inventory at this snapshot. The current `index.html` loads `iclub-ai-v21-ui.js`, not the historical `global-ai-ui.js`. Do not assume a non-deployed legacy route is a current learner outage without verifying the actual loaded shell.

## Release and reconciliation requirements

1. **Traceability.** Privately review the four deployed-only function sources, then commit reviewed source (or a suitably access-controlled source repository) with corresponding deploy provenance. Do **not** blindly publish privileged code or secrets into this public repository. The complete deployed-to-source mapping and checksums belong in access-controlled operator evidence until reviewed for disclosure.
2. **Identity and least privilege.** Verify the real request's authenticated identity, entitlement, capability, ownership, active-assessment restrictions, and server-side source rights. Browser origin/CORS checks are not a substitute for authorization.
3. **Source governance.** Cite only reviewed current source keys, versions and exact relevant skill/topic. No inference of unwatched video contents, private answer keys or inaccessible user history. RU/UZ/EN must preserve the same academic content.
4. **Cost and failure control.** Prepared help must avoid paid model calls. Every generation route requires enforced request allowance, total spend ceiling, idempotency/receipt handling, provider timeout, accounting and independent stop control. Do not silently assume all routes share one budget ledger.
5. **Core isolation.** AI OFF or provider failure must not change Practice/Tour/Exam Prep scoring, evidence, progress, ratings, certificates or persisted local state.
6. **QA and release.** Compare current `main` and production SHA at the moment of release; run route-level isolated tests, dedicated browser/RU-UZ-EN tests, budget and replay tests, and existing Core regression. Investigate CI failures before merge. Release is per capability/route, not a blanket enable.
7. **Security hold.** A separate protected-content access investigation remains **unresolved**. Its private reproduction and remediation details must not be placed in public issues, docs or pull requests. No speculative broad privilege changes, reset, or new learner capability rollout while the relevant release gate is unresolved.


## Verified release-control and content snapshot (2026-10-29)

This is **live-state observation**, not authorization to switch on a new route:

| Capability / content collection | Evidence | Release position |
| --- | --- | --- |
| General prepared help | 13 reviewed keys × 3 locales = **39** rows. All have nonempty text, content/rights/locale-review flags, approval timestamp, source hash and current published/not-revoked state. | **Existing approved help only.** Reuse without provider calls. This checks publication *metadata* and language completeness; not independent semantic translation validation. |
| Chemistry post-Practice error explanations | 68 contexts × RU/UZ/EN = **204** rows. No content, rights, locale or academic QA flags; no approvals; no published rows. | **DRAFT / DO NOT PUBLISH.** |
| Economics post-Practice error explanations | 39 contexts × RU/UZ/EN = **117** rows with the same missing review/publication gates. | **DRAFT / DO NOT PUBLISH.** |
| Mathematics Exam Prep prepared Tutor | 45 P1 + 36 P5 skill keys, RU/UZ/EN = **243** approved, runtime-allowed rows. All have content hashes, approval timestamps and four explanation variants. | **Content attribution gate remains open:** reviewer ID absent in all these records. The missing field does **not** prove no human review happened; recover external signed audit evidence before extending visibility. |
| Mathematics Tutor historical versions | Retired, runtime-disallowed records coexist with the 243 active cards; never count all historical rows as learner-available content. | **Keep retired rows untouched.** |

### Financial authorization evidence (non-invasive)

- Checked public provider reservation/settlement/dispatch functions for the current AI routes: the relevant cost-sensitive service RPCs are not executable by `anon` or `authenticated`; `service_role` can invoke them as required for server-side admission. This **does not establish that budgets are globally shared**.
- Provider-free general prepared help and subject-specific provider-backed calls have different authorization, budgets and switches. A route's deployment state, a published card, and an "enabled" budget control are separate conditions; never infer learner entitlement from one flag.
- The existing general Tutor generation switch was OFF at this snapshot; prepared help was ON. Other sub-route controls are independent and require their own authorization and replay audits. Do not flip any switches while these checks are pending.
- Paid canary remains disabled by its database control. Do not switch it on merely to test a student-facing feature.
- No direct user or anonymous right to invoke the reviewed budget-reservation/settlement RPCs was found in the production permission query. This does **not** replace testing the external HTTP entrypoints and service-account isolation.

### Required next nonpaid checks

1. Confirm the *effective combined daily/lifetime limit* across Exam Prep AI, Practice AI, general Freeform and QA/canary services. Distinguish total-provider spend accounting from independent route quotas; avoid duplicating ledgers with a destructive migration.
2. Verify each server route denies unauthorized users and subjects, expired/locked assessments, missing consent **where actually legally required**, and repeated/replayed requests. Use disposable offline PostgreSQL/browser/HTTP tests, not actual learner accounts.
3. Recover four deployed-only source versions into a controlled source registry with reviewed access policy; compare **all** source files and hashes, not only `index.ts`.
4. Collect independently attributable academic content sign-off for the 243 Mathematics Tutor cards, and complete rights/content/locale/academic QA for any future Chemistry/Economics draft cards before publishing.
5. Keep legacy security-release hold separate from a safe documentation/UI rollout. No production mutation or developer-environment expenditure was undertaken to produce this evidence.

## Current decisions / non-decisions

- **DONE:** Four existing repo-backed deployed Edge entrypoints (and the auxiliary module) matched the production source exactly.
- **PENDING:** Securely reconcile four deployed-only routes, verify global budget behavior across independent routes, and complete end-to-end authorized-access tests.
- **NOT DONE:** Deployment of any new Edge function, authorization changes, database migrations, paid QA environment, or learner-wide AI expansion.
- **NO NEW COST:** No paid Supabase development branch; the architect explicitly declined that option on 2026-10-29. Keep the blocked security release separate and proceed only with independently safe, testable tasks.

This document is a **versioned release reference**, not an instruction to activate anything. Amend it with evidence on each new release. The temporary execution tracker (#412) may later be closed and cleaned once the project is complete; keep durable, reviewed technical architecture documentation.
