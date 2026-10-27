# iClub AI Tutor — Mathematics Practice error sources (candidate bridge v1)
**27 October 2026 · DESIGN / ISOLATED TEST ONLY · production OFF**

## Decision

The existing Mathematics **Exam Prep** Tutor Card corpus is an approved topic-level teaching resource, **not** an approved mapping of legacy **main Practice** question errors. These are different evidence scopes.

Repository evidence:
- `docs/exam-prep-tutor-243-approval-runtime-ready-v1.md` records 243 / 243 reviewed `tutor_v2_learner_first` cards: 45 P1 skills × 3 locales, 36 P5 skills × 3 locales.
- `private.exam_prep_ai_tutor_cards` records component, canonical skill, locale, source-card key, content version, approval and runtime flags. Its service-role lookup is scoped to an **exact skill**, not to a main Practice question.
- `docs/exam-prep-tutor-provider-free-canary-v1.md` governs provider-free **Exam Prep topic explanations**. It does not authorize answering a particular legacy Practice mistake.
- `04_Content_Governance_Model_P1_P5_v1.1` and the 81-skill canonical source map require exact academic scope, original material, EN/RU/UZ mathematical equivalence, versioned mapping and preservation of questions with user history.

**Therefore:** reuse the approved topic explanation as a *review reference* where relevant; never simply replace `question_123` with a guessed P1/P5 skill or copy a Tutor Card into the legacy question-specific source registry. Nothing in this PR publishes or inserts any Mathematics Practice error source.

## Required evidence for one Practice question-specific source

Before a candidate is allowed into `private.iclub_ai_v21_academic_sources`, a separate, versioned approval package must contain:

1. The **current, owned, finalized main Practice** question ID, exact question-content/version fingerprint, and published-question status. Review state is not inferred from an old subject/topic string, and raw historical answers are never rewritten.
2. A teacher-reviewed **primary canonical skill** and component: `P1` or `P5` only, from the established 45 + 36 catalog. Prerequisite/enrichment labels cannot create mastery. Where the legacy item is outside year-one scope, source publishing is blocked rather than force-mapped.
3. A review of the actual **answer/error path**. A topic card may explain the governing principle, but cannot claim that this learner made a particular misconception unless the server has a verified diagnostic mapping. Do not disclose active assessment keys.
4. An original, copyright-cleared explanatory source; official syllabus determines scope, coursebooks provide secondary teaching reference, and protected question text/solutions/diagrams cannot be reproduced.
5. **All three** approved EN/RU/UZ variants, each with its own audited text hash, same `source_version`, `practice_error` surface, `mathematics` subject, `question_<id>` context key and same current target fingerprint. Mathematical meaning, restrictions, units, answer space and difficulty must agree.
6. Real review evidence, version/change log and an explicit publication decision. No fabricated approver identifier and no review claim based only on an automated checksum.
7. Independent service-side authorization: one correct learner, finished attempt, wrong answered question, source admission, protected-assessment blackout, and active consent/entitlement. No release by merely setting a frontend flag.

## Candidate fail-closed gate now in PR #366

`supabase/candidates/iclub_ai_practice_context_v1_dormant.sql` performs fresh owner/finalization/incorrectness checks and calls the existing source admission + question fingerprint functions. The candidate now additionally requires all **EN, RU and UZ** to be admitted under the **same source version and target fingerprint**, with each `body_text` matching its own SHA-256 content hash. A single translated card is insufficient.

`supabase/tests/iclub_ai_practice_prepared_isolated.sql` exercises the actual candidate SQL in disposable PostgreSQL using **synthetic** admitted/denied sources. It deliberately mutates one locale's hash, version and target fingerprint, confirms each variant fails closed, and verifies correct and unrelated wrong questions cannot inherit an approved source. This test validates the local gate **only**; it does not certify any real academic card, original source rights, or the existing deployed `deliver_iclub_ai_v21_academic_service` implementation.

## Still required before the first real source publication

- Read-only inventory of the Mathematics main Practice question/version/answer-path population. Identify safe, original, not-yet-mapped candidate questions; do not relabel 645 historical questions in place.
- Author/QA the exact question-specific 3-language source pack and sign off its component/skill/question-version binding. The 243 Exam Prep skill cards may help the reviewer teach the concept but **are not** the proof of question mapping.
- Review the **full** downstream source-delivery RPC and learner UI (including any alternative academic button route). The context preflight alone must never be treated as a complete publication guard.
- Create a separate, reviewed, additive production migration only after explicit architectural approval; first release may contain a tiny governed slice. No new paid provider call is needed for prepared explanation.
- Run negative cases against the actual released endpoints, with emergency OFF, retired source, version change, active quiz, cross-account and revoked consent. Keep Core learning available if the source or AI is OFF.

**Operational status:** zero main Practice Mathematics error cards have been approved or published *by this PR*. Existing Exam Prep Tutor Card content remains untouched. The candidate SQL and CI are OFF and isolated; no production data, progress, localStorage, spending or original questions change.
