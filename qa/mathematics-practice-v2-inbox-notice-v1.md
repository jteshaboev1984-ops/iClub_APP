# Mathematics Practice v2 — уведомление внутри iClub (подготовлено, без отправки)

**Статус:** QA-кандидат. Не отправлять до окончательного разрешения на рассылку.

**Кому:** пользователям, у которых в `public.user_subjects` выбран предмет `mathematics` и существует профиль `public.users`. Проверка 9 октября: **854** подходящих адресата. Всем аккаунтам подряд уведомление не нужно. Аудитория динамическая — перед отправкой перепроверить.

**Зачем:** банк Mathematics Practice v2 опубликован 8 октября 2026 года, прежние результаты Practice очищены в момент перехода. 495 новых вопросов доступны. Tours, сертификаты и Exam Prep не затрагивались. **Повторно не публиковать банк и не очищать данные.**

## Утверждаемые пользовательские тексты

### RU
**Заголовок:** Практика по математике обновлена

**Сообщение:** В Практике по математике теперь 495 вопросов нового банка. Результаты прежней версии были очищены при обновлении. Начните новую попытку во вкладке «По турам» или «По темам». Результаты туров, сертификаты и прогресс Exam Prep сохранены.

### UZ
**Sarlavha:** Matematika amaliyoti yangilandi

**Xabar:** Matematika amaliyotida endi yangi bankning 495 ta savoli mavjud. Oldingi versiya natijalari yangilanish vaqtida tozalangan. «Turlar bo‘yicha» yoki «Mavzular bo‘yicha» bo‘limida yangi urinishni boshlang. Turlar natijalari, sertifikatlar va Exam Prep’dagi natijalaringiz saqlangan.

### EN
**Title:** Mathematics Practice updated

**Message:** Mathematics Practice now has 495 questions in the new bank. Results from the previous version were cleared during the update. Start a new attempt in “By tour” or “By topic”. Your Tours results, certificates and Exam Prep progress are preserved.

## Проверено в действующей базе (только чтение)

- `auth.users` 1845; `public.users` 1447; выбор Mathematics + профиль `public.users` — 854.
- Кампания `math_practice_v2_notice_20261009_v1` не существует, назначений пользователям — 0.
- Уже имеющиеся таблицы `notifications` и `user_notifications` поддерживают эти тексты и RU/UZ/EN.
- Уникальность пары `(notification_id,user_id)` защищает от повторных назначений.
- Для **только внутреннего сообщения** необходимо сразу ставить `delivery_status='skipped'`, чтобы Telegram-отправка не активировалась. Текущий триггер не пропускает обычный `manual` автоматически.

## Как выпускать

1. На одобренной версии приложения выполнить `qa/math-practice-v2-notice-preflight.sql` (без записей в БД). Сверить количество получателей, отсутствие кампании и сохранность данных.
2. Получить подтверждение аудитории и текста. Отдельно разрешить отправку, поскольку она создаёт строки для реальных пользователей.
3. Выполнить **один раз** `qa/math-practice-v2-notice-SEND-HOLD.sql` после удаления намеренной блокировки в первой команде. Скрипт создаёт ровно одну кампанию и выдаёт её всем пользователям выбранного предмета в одной транзакции. Повторный запуск запрещён.
4. Проверить русский/узбекский/английский текст на разрешённом аккаунте, что `delivery_status='skipped'`, Telegram-очередь не создана, а badge обновляется. Результаты и сертификаты при этом не изменяются.

Не отправлять сообщение в Telegram. Не добавлять новые системы уведомлений.
