# iClub AI Layer v2.1 — §118: 24 серверных контракта, ограничения базы и граница Supabase Auth

**Дата:** 15 октября 2026. **Технический статус:** GREEN (изолированный QA). **Релизный статус:** OFF / NO-GO.

## Фактический результат

Выполнен повторный аудит серверного интерфейса `qa/edge_v21/supabase_services.ts` совместно с `qa/edge_v21/screen_proof_services.ts`. Предыдущий реестр **23/23 был неполным**: косвенный вызов `get_iclub_ai_v21_screen_evidence_service` был пропущен регулярной проверкой, хотя соответствующий SQL-файл `iclub_ai_v21_real_schema_screen_proof_UNAPPLIED.sql` уже существовал.

Теперь реестр требует **24 RPC и 10 существующих UNAPPLIED SQL-файлов**. Новый контракт проверяется так же, как остальные: точная восьмипараметрическая сигнатура, `SECURITY DEFINER`, фиксированный `search_path`, запрет вызовов `PUBLIC/anon/authenticated`, `service_role`-only execute. Единый PostgreSQL-стенд устанавливает все 10 SQL-файлов в **одной временной транзакции**, проверяет ответ для собственного завершённого Practice, запрет чужого owner ID и повторный отказ после отмены финализации. Полный `ROLLBACK` проверяет исчезновение нового доказательного RPC наряду с исходными объектами.

Проверочный suite по историческим причинам по-прежнему называется `iclub_ai_v21_nine_drafts_integrated_local_pg.psql`; фактически после §118 он загружает **10** черновиков. Старое имя `INTEGRATED_NINE_ROLLBACK_GREEN` также сохранено для совместимости логов, однако rollback-check дополнен проверкой `get_iclub_ai_v21_screen_evidence_service`.

## Production metadata — без чтения данных учеников

С помощью исключительно read-only `pg_catalog` получены для десяти критических таблиц:

| Метаданные | Обнаружено |
|---|---:|
| Ограничения PK / FK / CHECK / UNIQUE | 48 |
| Индексы | 43 |
| Пользовательские триггеры | 4 |
| Политики RLS | 13 |

Датированная копия результатов: `qa/ai-layer-v21-p9-auth-constraints-readonly.json`. Среди особенно значимых зависимостей: `public.users.id` связан внешним ключом с `auth.users.id`; Practice требует допустимых статусов, ответов с неотрицательным временем и ограниченной длины `question_ids`; закрытый Tour имеет строгие ограничения статуса, срока и длины массива из **20** вопросов.

Четыре пользовательских триггера: `practice_stamp_bank_generation_v1`, `trg_enforce_competitive_limit`, `trg_auto_notify_welcome_after_registration`, `trg_sync_telegram_link_from_users`. Особенно связанные с приветственными уведомлениями и Telegram триггеры **не исполнялись** в искусственном тесте.

В новом `qa/sql_drafts/iclub_ai_v21_critical_constraints_LOCAL_ONLY.psql` моделируются **23 безопасно воспроизводимых** ограничения CHECK/FK/UNIQUE — это не все 48. Их проверяют восемь отрицательных случаев: недопустимые статусы Practice/Tour, режим предмета, отрицательное время ответа, Tour не с 20 вопросами, ссылки на несуществующие учебные записи и повторную подписку. В каждом случае ожидается отказ; исходные искусственные учебные записи остаются неизменными.

## Граница Auth и перечень оставшихся рисков

Существующий QA Edge adapter вызывает `/auth/v1/user` с пользовательским Bearer, получает `userId` из ответа Auth и только затем передаёт его в серверные RPC через доверенный `service_role`. В Deno имеются отрицательные mock-тесты подмены `userId`, токена и учебного объекта. **Однако это не реальное end-to-end подтверждение Supabase JWT:** настоящие действующие токены и данные пользователей не читались. `service_role` может обходить RLS; все будущие учебные API обязаны самостоятельно проверять владельца и актуальные права на каждом чтении.

Текущий синтетический стенд не воспроизводит `auth.users`, все производственные таблицы вопросов, полную схему Practice pools/seasons, все 48 ограничений, 43 индекса и четыре пользовательских триггера. Иначе под видом QA легко создать побочные действия или ошибочно заявить production parity.

## Проверка GitHub Actions

[GitHub Actions #346](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38710680225) — **SUCCESS**, 671/671 Node, 15/15 независимых PostgreSQL наборов; native Chromium RU/UZ/EN, Deno и гонка двух PostgreSQL исполнителей. Подтверждено: `INTEGRATED_TEN_DRAFTS_GREEN`, `HIGH_RISK_CONSTRAINTS_GREEN`, `CONSTRAINT_NEGATIVE_GREEN`, `FULL_SHAPE_89_GREEN`, `TWO_OWNER_SCOPE_GREEN`, `TWO_OWNER_RLS_GREEN`, rollback v1 AI-OFF, защита production файлов.

Два предыдущих прогона (Actions #344/#345) обнаружили неточности в новых отрицательных тестах, они исправлены. Ни один не внедрял SQL в действующую Supabase.

**Отдельно:** ветка `main`, Vercel domains/deployments, реальные миграции, текущие тарифы, Mathematics Exam Prep, данные учеников, localStorage и поставщики AI не изменялись. Новая Supabase branch не создавалась, платных AI-вызовов нет.

## Следующий большой выпускной барьер

Полный security-review реального Auth/owner proof, утверждение source rights, безопасное развёртывание ten reviewed server contracts лишь в отдельно разрешённой интеграционной среде, проверка полного защищённого end-to-end Preview с учётом RLS/триггеров, Core AI OFF parity, rollback и конкретного owner-approved beta/spend. До отдельного разрешения **Global AI OFF / NO-GO**.
