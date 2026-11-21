# iClub AI Tutor — Exam Prep meaning: RU/UZ/EN product-help copy proposal

**STATUS: DRAFT ONLY — NOT REVIEWED / NOT APPROVED / NOT PUBLISHED.**
**Workstream:** AI Tutor [Issue #412](https://github.com/jteshaboev1984-ops/iClub_APP/issues/412), S2.
**Prepared:** 2026-11-21, following owner-authorized Practice-help release (merged #636 / #627).
**Purpose:** Give an accurate, short answer to the user's question "Экзам преп Нима ва у нимага кк" from any eligible iClub screen, without treating the question as academic assistance, inventing learner data, making a provider call, or mixing Exam Prep with Practice or competitive Tours.

This document is **source-copy review material only**. It does not create a published help key, change the Tutor, authorize an API route, constitute independent RU/UZ/EN/rights approval, or permit a live Supabase write.

## 1. Candidate product-help key (NOT yet present in published source)

Suggested *future* key: `exam_prep_meaning` — **candidate name, not an existing approved product source**.

| Locale | Candidate learner-facing text — original editorial copy, review required |
| --- | --- |
| `ru` | **Exam Prep** — раздел iClub для подготовки к Cambridge AS Mathematics (компоненты P1 и P5). Он помогает начать с диагностики, изучать темы по личному плану и закреплять знания в доступных учебных заданиях и повторных проверках. Это подготовка, а не соревновательный Tour; доступные этапы зависят от прав доступа и текущего состояния раздела. AI не выставляет оценки и не меняет учебные результаты. |
| `uz` | **Exam Prep** — iClub’ning Cambridge AS Mathematics (P1 va P5) imtihonlariga tayyorgarlik bo‘limi. Unda boshlang‘ich tekshiruvdan so‘ng mavzularni shaxsiy reja asosida o‘rganish, mavjud mashqlarni bajarish va bilimni qayta tekshirish mumkin. Bu musobaqa Tour emas; ko‘rsatiladigan bosqichlar joriy kirish huquqingiz va modul holatiga bog‘liq. AI ball qo‘ymaydi yoki o‘quv natijalarini o‘zgartirmaydi. |
| `en` | **Exam Prep** is iClub's preparation section for Cambridge AS Mathematics components P1 and P5. It helps you start with a diagnostic, study topics through your personal plan, and reinforce learning with available activities and later checks. This is preparation, not a competitive Tour; the stages you see depend on your access and what is currently available. AI does not award marks or change academic results. |

**Editorial scope:** This text explains **the Mathematics Exam Prep module currently implemented in controlled beta**, not a guaranteed Exam Prep capability for all subjects. It does not assert that full Papers, AI handwriting marking, mentoring, every study feature, or public access for all learners are available. It does not promise grades or exam success.

## 2. Specific factual grounds and limitations

1. Current shipped `exam-prep/exam-prep-live.js` titles its existing module "Cambridge AS Mathematics · Exam Prep", has separate P1/P5, a diagnostic/start, personal study plan, learning/correction/retest/mixed stages, and protected module access. **Source:** [current Exam Prep UI](https://github.com/jteshaboev1984-ops/iClub_APP/blob/e17f48d0bd1811b8490fa6ef0a9543daa57a402d/exam-prep/exam-prep-live.js).
2. Owner-approved product boundaries keep actual Paper, checked marks and written evidence separate; AI does not grant verified scores or automatically mark written work. **Source:** [P1/P5 hybrid full-Paper product decision](https://github.com/jteshaboev1984-ops/iClub_APP/blob/e17f48d0bd1811b8490fa6ef0a9543daa57a402d/docs/math-p1p5-v22-s4-hybrid-paper-product-decision-20261109.md), and [AI rollout canon](https://github.com/jteshaboev1984-ops/iClub_APP/blob/e17f48d0bd1811b8490fa6ef0a9543daa57a402d/docs/ai-rollout-working-canon.md).
3. **Read-only live metadata on 21 Nov 2026:** `private.exam_prep_feature_config` has `rollout_state=controlled_beta`, Core and ordinary controlled-beta AI on, Mentor Care off; do **not** describe the module as publicly available, a general all-subject feature, or an AI marking service. Existing product controls, not this source text, determine who may access each activity. This is a dated observation, not standing content.
4. Existing global Tutor [approved screen hybrid](https://github.com/jteshaboev1984-ops/iClub_APP/blob/e17f48d0bd1811b8490fa6ef0a9543daa57a402d/docs/ai/ai-tutor-screen-actions-hybrid-v1.md) permits existing published product help provider-free, but **no** independent published Exam Prep meaning card was available as of this proposal; `practice_rules` is a different scope.

## 3. QA/approval gates — **all pending**

- [ ] **Content/product owner:** ensure wording matches *currently* released Mathematics Exam Prep behavior, not future S3/S4 or tariff features; review potential implication of diagnostic and optional personal plan wording.
- [ ] **Independent RU/UZ/EN editorial reviewer(s):** verify semantic equivalence and natural language, including mixed Cyrillic and Latin user query; do not copy source paragraph from a textbook.
- [ ] **Rights/source owner:** review whether product copy and "Cambridge" naming are appropriate to publish; source provenance, rights and `source_version` established.
- [ ] **Security/QA:** ensure server-approved key is only delivered to eligible signed-in users on unprotected surfaces, no subject/task data or personal results in this static card, no paid fallback and no release of academic exam content.
- [ ] **Specific architect approval** for publication of this exact RU/UZ/EN wording and the versioned source/key; **NO implicit approval** from the permission to release #627/#636.
- [ ] **Future separate implementation PR** after approval: add verified key and triple-locale server-side rows through established governed publication/versioning path, update existing allowlists/matcher without modifying v6's four-field API or bypassing review, then check exact-head zero-provider tests, genuine authenticated routing and post-release readback. No DB call or migration in this document PR.
- [ ] **Original two user journeys** in a consented session: Practice must show `practice_rules` at zero paid cost; Exam Prep meaning must show this text **only after** all approval and release gates.

Until the above gates are met, the **currently published application intentionally returns a no-approved-source answer** for an Exam Prep meaning question, without a paid provider call. Do not add the candidate key to the live Tutor before the source and rights owner approves.
