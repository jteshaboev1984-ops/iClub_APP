# §116 — Единый автономный PostgreSQL-контроль 9 SQL-черновиков AI v2.1

**Scope:** Disposable localhost PostgreSQL only; **NO-GO** for Supabase/Edge/production.

Тест `qa/sql_drafts/iclub_ai_v21_nine_drafts_integrated_local_pg.psql` подготавливает минимальный синтетический академический каркас и настоящую сохранённую v1 tariff foundation migration, затем **в одной транзакции** загружает девять существующих `*_UNAPPLIED.sql` строго по графу зависимостей. Проверяет наличие 23 server RPC, запрет выполнения от anon/authenticated, server-only grants, запрет прямого изменения защищённых приватных таблиц, глобальный kill switch, release OFF, закрытый navigation source, невозможность provider spend без разрешения. Наконец выполняет `ROLLBACK` и удостоверяется, что все новые объекты исчезли, а исходная v1 foundation сохранилась с AI=OFF.

**Важно:** это НЕ точный клон текущей Supabase: несколько v1 security/subject сервисов в стенде — намеренно всегда отказывающие синтетические заглушки; недостающее `global_ai_rollout_mode` в v1 foundation введено только в одноразовом стенде. Проверка выполняется как новый 15-й независимый PostgreSQL-набор в привычной GitHub Actions, без Vercel, provider, Supabase branches. До реального выпуска требуется реальный integrated protected Preview и независимый аудит RLS/transaction/concurrency и editorial rights.

**CI:** pending until independent run completed. До реального одобрения Global AI OFF / NO-GO.
