# iClub APP — Mathematics Practice v2 notification (HOLD)

Prepared 2026-10-09. **DRAFT ONLY. No insert, delivery, or production authorization.**

## Russian
**Title:** Mathematics Practice обновлена

**Body:** Мы обновили банк Mathematics Practice — теперь в нём 495 вопросов. При переходе на новый банк прежние результаты Mathematics Practice были очищены. Начните новую попытку в разделе «По турам» или «По темам». Результаты Tours, сертификаты и прогресс Exam Prep сохранены.

## Uzbek
**Title:** Mathematics Practice yangilandi

**Body:** Mathematics Practice savollar banki yangilandi — endi unda 495 ta savol bor. Yangi bankka o‘tishda Mathematics Practice bo‘yicha oldingi natijalar tozalandi. «Turlar bo‘yicha» yoki «Mavzular bo‘yicha» bo‘limida yangi urinishni boshlang. Tours natijalari, sertifikatlar va Exam Prep’dagi yutuqlaringiz saqlangan.

## English
**Title:** Mathematics Practice has been updated

**Body:** The Mathematics Practice question bank now has 495 questions. Previous Mathematics Practice results were cleared during the switch to the new bank. Start a new attempt in “By Tours” or “By Topics”. Your Tours results, certificates, and Exam Prep progress have been preserved.

## Safe delivery contract (NOT YET AUTHORIZED)

- Use the **existing** `public.notifications` and `public.user_notifications`; do not build another inbox.
- Notification `kind='manual'`; all six `title_ru/uz/en` and `body_ru/uz/en` fields mandatory.
- Stable deduplication tag: `meta.campaign_code='math_practice_v2_notice_20261009_v1'`. Read-only campaign lookup must be empty immediately before insert; after a successful insert, reruns must reuse the same notification ID.
- **IN-APP ONLY.** Every `public.user_notifications` assignment must explicitly use `delivery_status='skipped'` (not `pending`) and a clear `delivery_error='in_app_only: user-facing app notice, no Telegram'`. Do not call the Telegram delivery worker. The existing `trg_set_app_only_notification_delivery_status` only auto-skips a few special notification types, **not** ordinary manual campaigns.
- `user_notifications` has unique `(notification_id,user_id)` and `(user_id,notification_id)`; use these for exactly-once recipient assignment; never recreate an already assigned campaign.
- Do not send until final cohort confirmed. Baseline SELECT on 2026-10-09: `auth.users=1845`, `public.users=1447` (valid inbox-FK population). These are different populations. The exact audience is pending architect approval; never assume all auth users are app inbox accounts.
- Query target recipients **read-only**, exclude already delivered notice IDs, and verify target count before inserting. Avoid including the same user twice.
- Check `refreshNotificationsBadge` and inbox rendering for RU/UZ/EN with a controlled test account before general delivery.
- The Mathematics bank was already published on 2026-10-08. Never run its publication/reset SQL again. This message is about an already completed update.
- Preserve Tours, certificates, Exam Prep and all new post-publication Mathematics Practice records.
- If cohort/delivery-status requirements cannot be proven: **HOLD**. No bulk distribution.

## Release checks
1. Architect signs off recipient scope and final language copy.
2. Confirm campaign does not already exist and baseline counts remain healthy.
3. Stage one isolated in-app-only test notice with explicit authorization; prove no Telegram message was queued or sent.
4. Once release is approved, one idempotent campaign insert + recipients, audit row counts and in-app visibility, stop on anomalies.
