# iClub APP — Chemistry 9701 Paper 1: closed native server connection (J-01)

**Date:** 2026-10-26.  
**Mode:** SERVICE-ONLY, synthetic QA, **no learner release**.  
**Branch:** `work/chemistry-9701-native-p1-closed-20261026` (based on current `main` snapshot `396938ca22d4ff18895fdb91f6f8a4cc053ff526`).  
**Canonical host:** `exam-prep/exam-prep-host.js` and `exam-prep/exam-prep-api.js`; no change to them in this stage.

## What is actually wired now

The private Chemistry Paper 1 editorial form of **40 original MCQs plus four reserves** is connected to an independently gated **server-side native session contract**, without using or modifying existing Mathematics or Economics session tables:

1. `private.iclub_exam_chemistry_p1_shadow_start_v1(owner,client_key)` — verifies closed program status, official Paper 1 structural metadata (AS/40 MCQ/4500 seconds), exact source hashes and seven internal AI QA gates on each of the 40 selected questions, then creates an isolated QA session with server-side shuffled choices and stored source snapshot. A retry resumes the same session; concurrent start attempts are serialized using a transaction-scoped advisory lock.
2. `private.iclub_exam_chemistry_p1_shadow_get_v1(owner,session,language)` — returns EN/RU/UZ questions/options and previously saved choices. **Never returns keys, correct choice or explanations before finalisation.**
3. `private.iclub_exam_chemistry_p1_shadow_answer_v1(owner,session,order,choice)` — saves a choice atomically and idempotently, supports corrections before completion, preserves the first-answer timestamp, rejects invalid, expired or completed submissions.
4. `private.iclub_exam_chemistry_p1_shadow_finish_v1(owner,session)` — server computes 0–40 correct, marks missing answers as zero, returns an idempotent final result, then the read endpoint may expose correct indexes and explanations. **No mastery, certificate, profile progress, rating or user-record mutation.**

The session storage is `private.iclub_exam_chemistry_p1_shadow_sessions_v1`. A table-level CHECK **permits only fixed synthetic QA owner** `00000000-0000-4000-8000-000000009701`. All four RPCs exist only in the **private schema**, require the server-side `service_role`, and are denied to `anon` and `authenticated`. Secrets/service-role credentials are not shipped to browsers. Forced RLS is enabled. The QA-only functions also require Chemistry to remain `status=draft / launch_enabled=false` — they intentionally **stop** if the program goes live.

This is a **closed integration and technical proving harness**, not real student-facing Chemistry Exam Prep. It is NOT safe to tell learners that they can already use it.

## Verified scenarios (transactions ROLLBACK)

- Begin 40-question 75-minute P1 and fetch the same session on replay; exact 40 item and 22-topic authoring source.
- Fetch EN/RU/UZ, preserving position and answer when switching languages.
- No student-visible correct index, answer key or explanation during an active attempt.
- Save and retry same choice, revise a previous answer before deadline.
- Server finish: one saved response, replay unchanged; and **40/40** when 40 correct responses were submitted in an internal synthetic test.
- Expired attempt rejects new answers but can be finalised; finish replay does not regrade; finalised attempt cannot accept new answers.
- Wrong QA owner and NULL choice/order/language requests fail closed.
- **Every synthetic test used ROLLBACK**. Verified **zero persisted QA sessions** and no live learner history rows touched.
- Read-only production regression `scripts/qa-chemistry-9701-native-shadow-production-readonly.sql`: **21/21 PASS**.
- Security advisor: one INFO `rls_enabled_no_policy` on this new private table — deliberate closed-access design with `FORCE RLS` and all student table privileges revoked. The advisor did **not** flag the four new private functions as anonymously or authenticated-callable; unrelated existing database security notices are not resolved by this work.

## Strict release boundaries

- Chemistry program `draft`, `launch_enabled=false`, subject Theory/Tutor library hidden, native preflight `blocked`.
- Main `main` branch, production Vercel, Mathematics legacy adapter, Economics current user-facing native RPCs and data, public.questions, Tours and Practice unchanged.
- Previously authored 26 original variants remain safely preserved, with no evidence of any actual third-party viewing.
- Existing written P2/P4/P5 and real laboratory P3 remain separate and not graded by this P1 MCQ contract.
- The current 44 original P1 AI-reviewed questions remain **internal AI-reviewed**, not independently human approved; source draft release flags remain OFF.

## What's *not* connected yet — do not misstate

There is currently **no authenticated learner-facing Chemistry RPC** and no Chemistry renderer mounted in the shared `#exam-prep-host-root`. Current `exam-prep-host.js` properly keeps Chemistry in the *in development* state. The browser **must never** be given the `service_role` key or permission to call the synthetic service-only harness.

The next bridge is a distinct, owner-approved, authenticated student API (subject selection + release gate + per-user ownership + consent + authorization) and a reusable native shared-host renderer/adapter reusing Mathematics/Economics look and navigation. Only after end-to-end QA (desktop/mobile, retries, cross-user denial, no key leak, all three languages, accessibility and rollback) may Chemistry be considered for separate controlled beta GO.

**Do not repurpose the QA-only synthetic table/functions for real learners.** Build a separate versioned production transport with true user IDs and permissions, and preserve all historical progress.
