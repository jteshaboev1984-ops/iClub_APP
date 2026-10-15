# iClub AI Layer v2.1 — §119. Trust boundary и запуск только локального QA

**15 октября 2026. Технический итог GREEN; live Global AI OFF / NO-GO.**

QA Edge `qa/edge_v21/index.ts` теперь запускается только при explicit flag `isolated-preview-only`, HTTPS origin и локальном backend (`127.0.0.1` или `localhost`). Любой remote Supabase URL отвергается даже при флаге; для будущего интегрированного Preview необходимо отдельное ревью и разрешение архитектора.

Server adapter проверяет корневой URL, запрет неподходящего порта, различие anon/service-role ключей и отказ при явно привилегированной роли из Auth ответа. P9 preflight отдельно отслеживает сохранность этих барьеров.

**Тесты:** изолированный HTTP -> `/auth/v1/user` -> server RPC путь двух искусственных учеников, отдельно подтверждённые владельцы двух Practice-сессий, отказ чужому объекту/токену/контексту, поддельным role/plan/userId, отозванному JWT, недоступному Auth, чужому origin и неправильному UUID. Проверено, что JWT ученика отправляется только на Auth с anon key, service_role используется только для привилегированного RPC, секреты не попадают в ответы.

[GitHub Actions #347](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38712200049) — SUCCESS на commit `3e705142dcacb1f33a1afa3255d30e8c29174df0`: **672/672 Node; 15/15 scratch PostgreSQL; все 5 новых Deno тестов** и старые Deno/browser/двухпроцессные races. Protected app/Math/tariffs unchanged.

После QA дополнительно выполнен **только SELECT по pg_catalog.pg_proc** в живой Supabase по точному перечню 24 новых RPC: **0/24 установлены**. Read-only инвентаризация Edge: `exam-prep-ai` и `practice-ai` остаются ACTIVE с `verify_jwt=true`, отдельный Global AI v2.1 не развернут.

**Ограничение:** настоящая подпись JWT, реальная связка Supabase Auth -> remote Edge -> владелец в БД, production ограничения/триггеры, опубликованные редакцией источники и разрешённый budget/provider до сих пор не испытаны. Обязательный следующий шаг — security review и отдельная разрешённая integration environment, затем защищённый Preview и GO архитектора.

Никаких production/main, Vercel, Supabase branch, real user data, student progress, localStorage, Mathematics Tutor, tariff changes и платных AI вызовов. **Global AI OFF / NO-GO**.
