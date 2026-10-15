# iClub AI Layer v2.1 — интеграционная сверка P0–P9 и фактический release gap

**Дата:** 2026-10-15. **Состояние:** техническая подготовка продолжается строго в QA; **Global AI OFF / NO-GO**. Отдельный production GO не выдавался.

## Метод и граница

Источники: актуальный `docs/iclub-ai-layer-master-plan-v2.1.md` (§§0–113), сохранённая ветка `qa/iclub-ai-layer-v21-20261012`, Green Actions #333, **свежий read-only запрос** к `pg_catalog.pg_proc`, `pg_catalog.pg_class/pg_policy`, `information_schema.columns` действующего Supabase и read-only список активных Edge Functions. Ни пользовательские таблицы, ни записи учеников, ни production localStorage не читались; запросы не имели DDL/DML. Новая Supabase branch/project не создавалась.

### Статус основных этапов

| Этап | Технические доказательства | Не выполнено до полного GO |
|---|---|---|
| P0 | Аудит схемы, кода, инвариантов, границ; 15 Oct live metadata recheck | Новый baseline непосредственно перед релизом |
| P1 | Защищённый статический синтетический Preview и localhost Chromium | Защищённый *интегрированный* Preview с настоящим Edge и read-only разрешёнными источниками |
| P2 | Автономный readiness router, контекст, fail-closed guard, UI transport | Реальный authenticated server issuance и независимо доказанные production read RPC |
| P3 | QA RU/UZ/EN, 320/390/desktop, в том числе Home → Study → Home | Final brand AI mark и реальная единая панель/скрытие AI во всех действующих экранах |
| P4 | Frozen 243 Mathematics cards / P1-P5 firewall и Math Tutor regression | Проверенный реальный cutover/parity и один коммерческий учёт без двойных списаний |
| P5 | Завершённая Practice / открытый Tour archive — синтетическая owner-bound проверка | Настоящий gated server data API и integration parity с legacy |
| P6 | Home/Profile/subject adapters, 18 QA navigation strings, подписанный Home, одноразовый claim, 3 учебных направления | Редакционная правовая публикация, source versioning и реальный release |
| P7 | QA free/plus/pro смешанный учёт, резервирование, лимиты, конкуренция, денежные caps | Утверждённые тарифные значения и live privacy/budget/security authorization |
| P8 | 649/649 Node, 14/14 scratch PostgreSQL, Chromium RU/UZ/EN, Deno, two-worker race, protected-file gates | Полный live RLS/auth/owner/source/UX/rollback audit на интегрированном Preview |
| P9 | GO/NO-GO процесс, отдельное право архитектора определены | Фактическое одобрение cohort/provider/spend, release, beta и публичного UI |

**Значение QA GREEN:** все покрытые автономные тесты прошли; *не* означает, что P0–P9 завершены как production-ready.

## Production-контракты, проверенные 2026-10-15

Проверка точного списка строковых вызовов `rpc(...)` в `qa/edge_v21/supabase_services.ts` выявила **23 контрактных имени** Global AI v2.1 (включая scoped context, publication, tenant security, quota, delivery, provider budget). Метаданный каталог действующей Supabase не содержит ни одного из этих **23** контрактов. Настоящий v2.1 Edge endpoint также не установлен. Это обязательный **STOP** для реальной интеграции, а не повод использовать существующий v1 как fallback.

**Два действующих коммерческих контракта** по `pg_get_functiondef()` повторно совпали с утверждёнными MD5:
- `get_iclub_subject_access_guard_service_v1` — `bb0c27de3665e5c6e16810044b1316a5`;
- `get_iclub_subscription_capabilities_service_v1` — `58bfe7eaf0c54a8e74d50bbf79416684`.

Для этих `SECURITY DEFINER` функций метаданные подтвердили `service_role EXECUTE=true`, `anon/authenticated EXECUTE=false`. Это **не** доказательство остальных полномочий/транзакций.

Все восемь критических таблиц (subjects, user_subjects, Practice sessions+answers, Tour attempts+runtime и две private коммерческие таблицы) имеют `RLS=true`. Для `practice_sessions_v4`, `practice_session_answers_v4`, `tour_session_runtime_v4` и private selections/config direct SELECT для `anon/authenticated` не разрешён; новый AI должен использовать отдельно подтверждённый trusted service path, не читая напрямую из браузера. `user_subjects` имеет grant на SELECT и пять RLS policy: **проверить policy expressions и права владельца**, одного факта RLS недостаточно. `tour_attempts` имеет собственную selection policy — требуется owner-bound verification при реальном endpoint.

В read-only списке Edge Functions `exam-prep-ai` ACTIVE v16, `practice-ai` ACTIVE v4, обе `verify_jwt=true`. Это не даёт права изменять их или подменять будущим Global AI.

## Теперь зафиксированный автоматический STOP

Добавлены:
- `qa/ai-layer-v21-p9-live-metadata-readonly-snapshot.json`: версия исходного публичного API + список 23 требуемых RPC; метаданные функций, грантов и RLS, no learner data;
- `qa/ai-layer-v21-p9-live-integration-preflight.cjs`: независимая сверка ожидаемых RPC с точным QA-адаптером, существующими коммерческими MD5 и role grants, RLS/таблицами, активными legacy Edge, source publication и integrated Preview. Любой недостаток записывается как явная блокировка; **никогда не возвращается production GO**;
- `qa/ai-layer-v21-p9-live-integration-preflight.test.cjs`: изменённый adapter, подменённые RPC, коммерческие hashes/role grants, RLS, случайное подключение QA к production UI, заведомо ложное «все функции уже готовы» — результат NO-GO;
- `qa/sql_drafts/iclub_ai_v21_p9_catalog_READ_ONLY.sql`: точный воспроизводимый метаданный аудит, без чтения user/student rows и без SQL мутаций;
- контроль включён в основной `qa/run-ai-layer-v21-offline.cjs` и `iclub-ai-v21-offline-qa.yml`.

**Внимание:** snapshot — подтверждение конкретного момента, **не** автоматически обновляемый production мониторинг и не доверенная подпись. Перед будущим GO обязательно новое реальное read-only сравнение, independent code/security review, APPROVED editorial rights, owner/beta/provider approval. Синтетический набор функций не может автоматически создать одобрение от имени архитектора.

## Ближайшая крупная следующая работа (одно интеграционное решение)

1. Сверить все 23 контракта с реальными таблицами, RLS и доверенными владельцами; подготовить обратимые проектные миграции **не применять** без разрешения; не копировать полные учебные ответы или live записи в QA.
2. Подтвердить права использования, редакционный источник, signature/locale/version, коммерческие owner+subject+intent proof, и подлинное право включить новый AI.
3. Подготовить отдельный integrated protected Preview с реальным trusted endpoint, без production writes и без создания реальных тестовых учеников; проверить end-to-end, client identity, storage/privacy, rollback и Core AI OFF parity.
4. Лишь после независимой проверки представить владельцу точный ограниченный beta proposal с ценой, рисками, схемой отката, размером когорты и отдельным решением GO/NO-GO.

**НЕ делать:** `main` merge, production migration, live Edge deployment, payment, AI provider call, создание платной Supabase branch, изменение Exam Prep Tutor, реальных учебных данных, тарифных экранов, сертификатов, сохранённого прогресса или `localStorage`.

**Окончательный release status: OFF / NO-GO.**
