# iClub AI Layer v2.1 — аудит 23 RPC SQL черновиков и live RLS метаданных

**15 октября 2026. QA ONLY. Release: NO-GO.**

Проверены фактические 23 RPC из `qa/edge_v21/supabase_services.ts`: **все 23 уже определены** в 9 существующих `qa/sql_drafts/*_UNAPPLIED.sql`. Дополнительных фиктивных SQL-функций не создавали. Машинный манифест `qa/ai-layer-v21-p9-rpc-draft-manifest.json` фиксирует для каждого имя, аргументы, исходный SQL и граф зависимостей. `qa/ai-layer-v21-p9-draft-contract-gate.cjs` проверяет совпадение с Edge-кодом, точные SQL сигнатуры, `SECURITY DEFINER`, `search_path=''`, `REVOKE ALL` для PUBLIC/anon/authenticated, `GRANT EXECUTE` только service_role, scratch-name guard перед SQL DDL и порядок файлов. Отрицательные тесты намеренно повреждают контракты. Скрипт только ЧИТАЕТ сохранённые QA-файлы, не обращается к БД/провайдеру.

Прочитаны только `pg_catalog.pg_policy` (не данные учеников): 7 правил. `subjects_public_read` разрешает каталог; `tour_attempts_select_own` и все 5 `user_subjects_*_own` используют `user_id = auth.uid()`. MD5 отпечатки выражений хранятся в `qa/ai-layer-v21-p9-policy-fingerprint-snapshot.json` как датированный baseline. Это НЕ proof возможности доступа через SECURITY DEFINER и НЕ live мониторинг — требуется актуальная RLS проверка на отдельной защищённой среде перед релизом.

**Нельзя применять эти девять SQL файлов к production.** Каждый содержит guard для disposable scratch, а не одобренную обратимую миграцию. Отдельные SQL проверялись ранее в 14 PostgreSQL-наборах; полная production-like схема и все 23 функции вместе ещё не прошли независимую проверку идентичности контрактов, tenant isolation, transactional rollback и релиз. Live v2.1 RPC по последнему metadata-only аудиту: **0/23**. Следующие зависимости: reviewed atomic server auth/permissions, editorial source rights, интегрированный защищённый Preview, Core/Mathematics parity, beta/provider price approval. До отдельного GO Global AI OFF.

Пакет добавлен в один QA commit с offline runner и CI. Нет Vercel deployment, новой ветки Supabase, user writes, production файла, token spend или изменения Math Tutor.
