# iClub AI v2.1 — First governed Practice-error source intake and canonical release contract

**Date:** 16 October 2026  
**Status:** QA ONLY — EDITORIAL SOURCE **NOT APPROVED** / RUNTIME **OFF**  
**Existing branch:** `qa/iclub-ai-layer-v21-20261012`  
**Existing protected Preview:** kept unchanged; approved AI Tutor Option A mark retained.

## 1. Problem found and corrected in QA contracts

In the previous *synthetic* Practice answer test, the scoped context used
`practice_result / error_explanation / q202`. Those identifiers **do not match**
the existing source/editorial admission contracts:

- `qa/sql_drafts/iclub_ai_scoped_context_v21_UNAPPLIED.sql` allows canonical
  `surface_code=practice`, `feature_code=answer_explanation`.
- `qa/sql_drafts/iclub_ai_practice_exact_source_v21_UNAPPLIED.sql` checks
  `card_type='answer_explanation'` for the **exact owned question** and locale.
- `qa/ai-layer-v21-editorial-evidence.cjs` accepts publication evidence only for
  `surface=practice`, `feature=answer_explanation`, topic `question_<positive-ID>`.
- The visible product label **«Объяснить ошибку»** and the client prompt key
  `practice_error` are **not** source-table or release-authority identifiers.

The synthetic source-governed Practice E2E fixture was corrected to use
`practice / answer_explanation / question_202`, and a regression check now
compares that exact key across fixture, SQL and editorial evidence. These are
**QA test identifier corrections**, not changes to production screens or the
existing Practice data.

## 2. Content source policy grounded in project governance

The existing `04_Content_Governance_Model_P1_P5_v1.1` source establishes:
original iClub learner-facing questions, a copyright/provenance firewall,
separate reviewer and publisher approval, three-language equivalence,
independent mathematical review and preservation of historical learner results.
Its P1/P5-specific requirements are **not** silently transplanted to all Study
subjects; this pilot retains the applicable safety/provenance principles.
Neither an uploaded copyrighted Cambridge textbook nor an official syllabus
provides permission to republish question text or a mark scheme. The official
syllabus is a *scope/reference authority*, not a publication license.

Existing `qa/ai-layer-v21-content-handoff-gate.cjs` and
`qa/ai-layer-v21-editorial-evidence.cjs` remain the independent runtime and
review-signature gates. A local candidate is not an authorization event.

## 3. Concrete deliverables — QA only

- `qa/ai-v21-practice-editorial-candidate.UNAPPROVED.json`: empty, non-personal
  intake form for one future server-verified Practice question. No actual
  question ID, answer, copied textbook material, user identity or rights claim.
  All release gates `false`, `releaseAllowed=false`.
- `qa/ai-v21-practice-editorial-intake.cjs`: read-only, strict schema helper
  for server-proved question selectors, exactly one canonical source key, a
  complete independently versioned RU/UZ/EN set, original-iClub source
  provenance and unchanged source SHA. The returned candidate is always
  `ready=false, releaseAllowed=false`, even if technical checks pass.
- `qa/ai-v21-practice-editorial-intake.test.cjs`: negative tests for browser
  evidence, wrong question/subject, undefined rights or provenance, forged
  publication flags, missing locale, wrong hash/version, duplicate locale
  variants and missing editorial signatures. A candidate cannot make the
  `ContentHandoffGate` ready; only independent governed publication can do so.
- `qa/ai-v21-practice-source-governed-error-e2e.test.cjs`: updated canonical
  source identity in the *synthetic* E2E test, preserving its original
  completed-session/auth/source/provider-zero assertions.
- Existing protected GitHub workflow now executes the new editorial tests
  before any browser QA acceptance.

## 4. Human editorial tasks still required for first real explanation

1. Choose one **existing, finalizable and server-verifiable** Practice question
   from the real source-of-truth; record only its verified content ID and
   subject, not learner answers or personal progress in the content ticket.
2. Obtain an independently authored original iClub source/explanation and a
   provenance record (author, creation date, source version, rights evidence).
3. Independently check mathematical/scientific correctness and language
   fidelity for **each** of `ru`, `uz`, `en`; do not substitute machine
   translations as reviewed content.
4. Review exact-question correctness and active-assessment restrictions.
   Avoid revealing answers while Practice is active, irrespective of client UI.
5. Obtain three **independently trusted** content/rights/technical reviewer
   signatures using the existing editorial evidence contract. Do not place
   private signing keys in GitHub, Vercel or a client file.
6. Only after a separate explicit product release decision and server-gated
   publication, test a real signed-JWT protected Preview against a
   non-production academic backend. No additional paid Supabase branch is
   authorized by the present work.

## 5. Stop conditions

**No** Supabase migration, Edge deployment, role grant, product tariff,
production release, AI provider call, textbook reproduction, academic write,
student history modification, protected Practice solution disclosure,
Mathematics Tutor change or logo redesign has been made.

The current offline Vercel Preview continues to display the approved Option A
AI mark and *synthetic navigation guidance only*. Its READY status must not be
presented as a real source-backed tutoring beta.

**Next safe work item:** once a real original-iClub question source is selected
and independently reviewed, attach its provenance and language checks to this
intake package and validate signed editorial handoff against disposable QA.
