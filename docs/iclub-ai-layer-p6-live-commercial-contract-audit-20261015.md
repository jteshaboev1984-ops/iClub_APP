# iClub AI Layer — §100–§102: фактический коммерческий контракт Home (READ-ONLY audit)
Дата: 2026-10-15. Область: `qa/iclub-ai-layer-v21-20261012` **без новой Supabase-ветки**.

## Подтверждённый существующий серверный контракт

Метаданные и определения функций действующей Supabase просмотрены строго через запросы к `pg_proc`/`pg_get_functiondef` и `information_schema.columns`. Не выполнялись запросы к таблицам реальных учеников, записи, миграции и изменения прав.

### 1. `public.get_iclub_subject_access_guard_service_v1(uuid,text,text)`
- Допустимые intent исходной функции: `open`, `select_study`, `select_competitive`.
- При `subject_limits_mode=off` возможно `allowed=true,mode=legacy_passthrough`.
- При незавершённом grandfather snapshot на enforced возможно `allowed=true,mode=legacy_passthrough`.
- В режиме `shadow` возможно `allowed=true,mode=shadow`, включая невыбранные предметы.
- `grandfathered` при прежнем `legacy_preserved` относится к существующему доступу, но не означает одобрение нового Global AI.
- `open` может выдать `commercial,reason=subject_selected` или `commercial,reason=plan_all_subjects`.
- `select_competitive` проверяет наличие места, но НЕ устанавливает, что предмет реально выбран. Для архива Tour нужен независимый `competitive_selected`.

### 2. `public.get_iclub_subscription_capabilities_service_v1(uuid)`
- Реально возвращает `resolved`, `plan_code`, `plan_source`, `study_subject_limit`, `all_available_subjects`, `competitive_subject_limit`, `ai_generation_entitled`, `ai_usage_policy_code`, `priority_support`, `early_access_entitled`.
- `ai_generation_entitled=true` даёт лишь право тарифа, **не** открывает выключенную новую функцию Global AI: нужен отдельный server-controlled rollout/owner GO.
- Источники тарифа включают `explicit_entitlement`, `canary_override`, `default_free`. Само имя источника тарифа не считается отдельным разрешением AI.

### 3. Фактические таблицы подтверждения
- `private.iclub_commercial_access_config.subject_limits_mode, grandfather_snapshot_completed_at, policy_version, updated_at`.
- `private.iclub_subject_slot_selections.user_id,subject_key,study_selected,competitive_selected,updated_at`.
- `public.user_subjects.user_id,subject_id,mode,created_at`.
- `public.subjects.id,subject_key,type,is_active`.

## QA реализация без production

- `qa/ai-layer-v21-p6-commercial-contract-adapter.cjs` преобразует только ответ доверенного сервера в узкий owner+subject+intent-proof. Запрещает `shadow`, `legacy_passthrough`, `grandfathered`, слот-доступ без уже сделанного выбора, неверного владельца, неподтверждённую подписку, закрытый предмет и отсутствие `ai_generation_entitled` или дополнительного QA-only feature gate. В любое время `productionAllowed=false` и `providerAllowed=false`.
- `qa/sql_drafts/iclub_ai_v21_commercial_contract_fixture_local_pg.psql` создаёт в **одноразовой локальной** PostgreSQL только совместимые по форме таблицы, функцию `open` и synthetic product capabilities. Это тестовый дубль, не реальная серверная база и не авторизованная запись в Supabase.
- SQL Home перечисляет предметы только после фактически сохранённых `study_selected` и (для Tour) `competitive_selected`. Поэтому неподтверждённый предмет не скрывает другой доступный шаг.
- `qa/ai-layer-v21-p6-home-pg-http-gateway.cjs` теперь получает commercial proof через тот же серверный snapshot, а не через зашитый `allowed:true`.
- Отрицательные тесты отключают `ai_generation_entitled`, отдельный QA-gate, `study_selected`, `competitive_selected`, переключают shadow/off, подменяют владельца и отзывают права. Ни один реальный тариф/подписка не меняется.

## Контур выпуска: всё ещё NO-GO

Реальная независимая публикация и юридические права на учебные источники не утверждены. В QA source releases остаются **синтетическими**. Реальной авторизации и выдачи Home пользователю в Supabase/Edge нет, продовая функция не изменена. Учитывая запрет на новую Supabase ветку, возможно доказать локальный PostgreSQL/HTTP/Chromium контракт, но не полную реальную интеграцию с Supabase. Статический защищённый Vercel Preview не заменяет настоящий integrated Preview. `main`, данные учеников, localStorage, Mathematics Tutor и платные вызовы не трогать.

Проверка CI нового §100–§102: **результат фиксируется только после фактического полного workflow**; никаких авансовых PASS.
