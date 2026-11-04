# Issue #450 — P0-15 release-epoch write coverage: actual PostgreSQL RPC source graph

**4 November 2026 | verified Supabase SELECT-only metadata | NOT a production release or user-data operation.**

## Verified production-shaped surface (source-text model)

Read-only [reproducible PostgreSQL catalog query](../supabase/tests/p1p5_v2_package0_rpc_write_graph_readonly.sql) starts at `public.*exam_prep*` functions with `authenticated` EXECUTE, recursively follows textual `private.exam_prep_*()` and `public.exam_prep_*()` references to depth five, detects direct DML *textual candidates* and reports caller/guard status. This inspects **function definitions and ACLs only**, no users, answers, marks or private runtime secrets.

| Scope | Observed 2026-11-04 | Meaning |
| --- | ---: | --- |
| Authenticated-callable public named Exam Prep RPC roots | **98** | Role-executable endpoints; include learner, mentor/beta/consent |
| Roots reaching a *parsed candidate* Exam Prep DML statement | **37** | Potential mutation reachability, not proven exhaustive |
| Of those, direct DML in the public root | **25** | Must review exact source-specific write gate |
| Of those, only indirectly reachable DML through helpers | **12** | Missing from naive direct regex; need entrypoint and callee check |
| Roots with no parsed Exam Prep DML | **61** | Not proven read-only; may use dynamic/unqualified/other-schema writes |
| Potentially writing routes without textual Core guard in their parsed chain | **7** | Mostly governance/mentor/beta/consent; **do not apply Core entitlement blindly** |
| Potentially writing routes with a release-epoch marker | **0** | The currently published named source has no explicit post-reset epoch check |

Graph depth is bounded to 5, overloads are conservatively name-joined, source comments/quoted text can cause false positives, and dynamic/unqualified calls and external module calls can cause **false negatives**. This is a **prioritisation inventory** and cannot certify that all user writes are fenced.

## Minimum implementation matrix before real release

| Group | Representative routes | Required invariant |
| --- | --- | --- |
| Diagnosis/session issuance | start_next_diagnostic, start_session, plan/timed/mixed/correction/retest authorization | Owner + single current program + server-issued current learning epoch + content version; old frozen authorizations cannot be revived |
| Answer/evidence and result finalization | submit_response, finalize_session, finalize_timed, written_next and integrity records | Owner + immutable session epoch checked atomically with the write, even on retry and before any evidence mutation |
| Weekly adaptation | generate_weekly_plan v1/v2/v3, ensure_balanced_plan, goal authorization, reviews and due retests | No stale plan/goal reappearance from prelaunch, no cross-paper mastery transfer, no change to protected Practice/Tours |
| Student profile and exam planning | save_exam_profile v1/v2, save appointment, schedule, learner-chosen P1/P5 dates, weekly/monthly report claims | Explicit authorized learner action, enrolled Math, epoch/diagnostic-cycle source, no resurrection of old personal beta plan |
| Mentor/consent/AI/operations | mentor assignment/review, beta seat and consent, limited AI | Separate governed authority/retention. Do **not** transform these into ordinary Core learner writers or delete protected audit/consent history |

A single central `private.exam_prep_require_core_access_v1()` check is useful for entitlement and rollout but does **not** prove an old valid signed JWT is acting in a new learning epoch. The [P0-13/14 genuine signed local JWT/PG17 fixture](math-p1p5-p0-13-p0-14-signed-epoch-and-concurrency-20261104.md) proves the **required pattern**, not implementation coverage of the live 37+ mutation candidates. A proper release design must bind authorization issuance to a server-side immutable epoch and assert it inside every mutation or common write helper; avoid trusting a client-supplied epoch number.

## Next exact technical work

1. Build an independently reviewed **exhaustive write-entrypoint allowlist / nested helper map**, including non-`exam_prep` wrappers, Edge Functions, developer/mentor RPCs and old mobile bundles. Treat any unclassified path as a launch blocker.
2. Prepare a **versioned, additive and disabled-by-default** maintenance/academic-epoch service in a disposable branch, without production DELETE permissions, and evaluate its integration with existing responses, profile writes and correction/retest/plan helpers.
3. Re-run full signed JWT/PostgREST/PG17 P1/P5 + two-connection old-client races, mixed/timed/retest/AI/mentor denies and restored protective fingerprints after final combined PR #469/#470/#471 migration order.
4. Review receipt retention and two newly proposed learner-state tables from P0-08/11; independently prove an encrypted PRODUCTION backup restore only when separately authorized. Obtain explicit architect final release SHA, allowlist, timing and GO.

**Status:** source graph and isolated epoch model only. Main, live Supabase, Vercel, all real user/Tours/Practice/certificate/AI data unchanged. **Public NO_GO.**
