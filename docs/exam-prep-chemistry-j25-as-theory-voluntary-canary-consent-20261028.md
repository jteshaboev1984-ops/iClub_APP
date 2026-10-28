# Chemistry 9701 — J25 AS Theory voluntary beta consent (staged, not published)
Date: 2026-10-28. Release state: **CLOSED**. No invitations, enrolled learners, or owner approvals have been created by this change.

## Scope and user flow
- Mathematics Exam Prep Beta membership is a prerequisite, **not consent**.
- Chemistry Paper 1 consent v1 is **not treated as consent to AS Theory**.
- Only a specifically invited existing eligible learner may submit a J25 AS Theory consent; no automatic membership.
- Submit consent in the learner's chosen language (RU/UZ/EN), record exact copy version `j25_as_theory_20261028_v1`. Consent submission leaves access OFF, pending separate owner approval.
- First phase: one owner-designated consenting canary, no other active learner. Expanded phase requires a separate owner decision. J24 academic, rights, 91-source manifest, protected-exam and membership guards remain mandatory.
- Consent can be revoked independently of Mathematics, including after a Mathematics eligibility change. Withdrawal immediately fails future server authorization and does not erase learning history.
- No new Exam Prep scores, mastery, tests or user browser storage are written by this theory consent flow.
- A screenshot or simulated database test is not evidence that a real learner granted consent.

## Proposed learner-facing copy — RU
**Приглашение: теория Chemistry AS Level**

Вас приглашают добровольно протестировать учебные материалы по теории Chemistry AS Level. Это не экзамен, не официальный сервис Cambridge и не AI Tutor. В материалах могут встречаться ошибки. Ваши результаты по Mathematics и другим предметам останутся без изменений. Вы сможете отозвать согласие в любой момент. Доступ откроется только после отдельного одобрения и может быть предоставлен позднее.

Checkbox: **Я прочитал(а) информацию и добровольно соглашаюсь на тестирование теории Chemistry AS Level.**

Pending: **Согласие сохранено. Доступ пока не открыт.**

Withdraw: **Отозвать согласие на Chemistry**

## Proposed learner-facing copy — UZ
**Taklif: Chemistry AS Level nazariyasi**

Siz Chemistry AS Level nazariyasi bo‘yicha o‘quv materiallarini ixtiyoriy ravishda sinab ko‘rishga taklif etildingiz. Bu imtihon ham, Cambridge’ning rasmiy xizmati ham, AI Tutor ham emas. Materiallarda xatolar uchrashi mumkin. Mathematics va boshqa fanlardagi natijalaringiz o‘zgarmaydi. Roziligingizni istalgan vaqtda qaytarib olishingiz mumkin. Kirish faqat alohida tasdiqdan keyin ochiladi va keyinroq taqdim etilishi mumkin.

Checkbox: **Ma’lumotlarni o‘qidim va Chemistry AS Level nazariyasini ixtiyoriy sinab ko‘rishga roziman.**

Pending: **Roziligingiz saqlandi. Kirish hali ochilmagan.**

Withdraw: **Chemistry bo‘yicha rozilikni qaytarib olish**

## Proposed learner-facing copy — EN
**Invitation: Chemistry AS Level theory**

You are invited to voluntarily test Chemistry AS Level theory lessons. This is not an examination, an official Cambridge service, or an AI Tutor. The materials may contain errors. Your Mathematics and other subject results will remain unchanged. You can withdraw your consent at any time. Access requires separate approval and may become available later.

Checkbox: **I have read the information and voluntarily agree to test Chemistry AS Level theory.**

Pending: **Consent saved. Access is not open yet.**

Withdraw: **Withdraw Chemistry consent**

## Technical contract
- `private.iclub_exam_chemistry_j25_as_theory_control_v1` defaults to `closed`.
- `private.iclub_exam_chemistry_j25_as_theory_optins_v1` defaults to no rows. Only invited rows may opt in; the grant RPC cannot create an invitation or approve a user.
- `public.iclub_exam_chemistry_j25_theory_consent_status_v1` reads only the calling user's scope.
- `public.iclub_exam_chemistry_j25_grant_theory_consent_v1` uses explicit acknowledgement and is idempotent.
- `public.iclub_exam_chemistry_j25_revoke_theory_consent_v1` is independently revocable.
- J24 authorizer must check this J25 consent, owner approval, and closed/canary/expanded phase; never substitute old P1 consent.
- Student-facing copy is a draft for J25 UI integration. **No consent has been solicited and no production browser interface has been released by this document.**

## Release hold
J23 full 91-item scientific and EN/RU/UZ semantic review, source signoff, J24 actual protected browser QA, independent consent UX, real voluntary canary, and owner-approved per-component release remain open. Do not activate `release_phase` or J24 gate merely because migration or synthetic tests succeed.
