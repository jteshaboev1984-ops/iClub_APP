# iClub AI Layer §117 — 89 production metadata columns, two independent synthetic owners

**Дата:** 2026-10-15. **Технический итог:** GREEN только для одноразового локального PostgreSQL 16. **Product release:** Global AI OFF / NO-GO.

## Проверенные результаты

Использован датированный **read-only** metadata snapshot 89 столбцов десяти учебных/системных таблиц (не строки учеников). `qa/sql_drafts/iclub_ai_v21_89_column_overlay_LOCAL_ONLY.psql` воспроизводит 49 недостающих определений поверх §116 minimal fixture и проверяет **89/89** названий, PostgreSQL-типы и nullable-флаги. Для `public.tours.is_active` приведена к метаданным единственная существующая в fixture колонка `SET NOT NULL`. `FULL_SHAPE_89_GREEN` подтверждён фактическим SQL.

Девять оригинальных `*_UNAPPLIED.sql` установлены совместно в одной временной транзакции; **23/23 RPC**, role grants, Global AI kill-switch и исходная v1 foundation проверены. Отдельный `qa/sql_drafts/iclub_ai_v21_two_owner_proof_LOCAL_ONLY.psql` проверяет владельцев **Synthetic A и Synthetic B**: разные Practice, собственные RLS SELECT для user_subjects и tour_attempts, отказ чужому context bearer / attempt, повторное подтверждение после изменения статуса Practice, protected assessment, удаление enrolment, независимость второго владельца, отзыв bearer и автоматический rollback неудачного повторного INSERT учебного ответа. После полного `ROLLBACK` девять новых SQL-объектов исчезают, исходная v1 foundation остаётся AI-OFF.

**CI-доказательство:** [GitHub Actions #343](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38702394334) — completed / success, **666/666 Node**, **15/15 PostgreSQL scratch suites**, native Chromium RU/UZ/EN, Deno, независимые серверные гонки и проверка неизменности protected files. Точные строки: `FULL_SHAPE_89_GREEN`, `INTEGRATED_NINE_DRAFTS_GREEN`, `TWO_OWNER_RLS_GREEN`, `TWO_OWNER_SCOPE_GREEN`, `INTEGRATED_NINE_ROLLBACK_GREEN`. Run #342 до исправления правильно обнаружил отсутствие NOT NULL у `tours.is_active` в тестовом каркасе; production не затрагивался.

## Не доказано и не разрешено

- Это синтетическая схема с **точными полями, типами и nullable**, но не копия production constraints, indexes, full policy expressions, triggers, extensions, версии PostgREST или всех миграций.
- Локальная `auth.uid()` получает синтетический claim из settings; **не** проверяет подпись Supabase JWT. Owner separation через RLS и SECURITY DEFINER в этом стенде не равнозначна security approval реального Edge.
- Positive protected context checks выполнялись после **временного включения локального** kill-switch внутри rollback-транзакции. На настоящем проекте Global AI остаётся OFF.
- Не выполнялись настоящие model/provider calls, live reads школьников, live DB SQL writes, Supabase branch, Vercel preview/deploy, изменение тарифов, Mathematics Tutor или активного приложения.
- Существующие 23 SQL-черновика по-прежнему *UNAPPLIED* в Supabase. Не проводить их применение без независимого security review, редакционно утверждённых источников, budget approval, protected integrated Preview, parity Core AI OFF и отдельного GO владельца.

**Следующая крупная зависимость:** сформировать isolation proof для реального Supabase Auth и перечень production constraints/triggers из метаданных, затем — защищённый Preview по отдельному разрешению архитектора. До этого глобальный выпуск — **NO-GO**.
