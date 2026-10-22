# iClub Exam Prep — Stage 3: закрытая серверная основа письменной подготовки

**Дата:** 22.10.2026  
**Статус:** CLOSED BACKEND FOUNDATION VERIFIED / ECONOMICS NO-GO.  
**Действующий продукт:** Mathematics, Practice, Tours — не редактировались.  
**Согласованный маршрут:** Задание → самостоятельная работа → Критерии по желанию → Далее. AI не оценивает эссе; Mentor Care отдельно.

## 1. Изменено фактически

В Supabase **применены две аддитивные миграции**:

| Версия применённой миграции | Источник GitHub |
|---|---|
| `20261022144653` | `supabase/migrations/20261022144653_iclub_exam_core_written_native_isolated_v1.sql` |
| `20261022144945` | `supabase/migrations/20261022144945_iclub_exam_core_written_native_read_contract_v1.sql` |

Сопоставлены с `list_migrations`. Имена исходников исправлены под фактические версии без повторного применения SQL. Созданы только следующие новые приватные таблицы:

- `private.iclub_exam_core_written_tasks_v1` — версия вопроса, вопросы по языкам, требования по языкам, академические/языковые/source-флаги, запрет публикации по умолчанию.
- `private.iclub_exam_core_written_access_v1` — отдельное право конкретного ученика на конкретную программу и версию, изначально неактивное.
- `private.iclub_exam_core_written_plans_v1` — планы по ученику и версии программы, изначально draft.
- `private.iclub_exam_core_written_plan_items_v1` — письменные шаги плана, токен, состояние `pending/advanced`, времена, nonce, FK и уникальность шагов/повторных действий.

Созданы только закрытые серверные операции в `private`:
`iclub_exam_core_written_open_v1`,
`iclub_exam_core_written_criteria_v1`,
`iclub_exam_core_written_advance_v1`,
`iclub_exam_core_written_status_v1`.

**Ни у anon, ни у authenticated нет прямых прав EXECUTE на эти функции или SELECT/INSERT на новые таблицы.** Рабочие публичные RPC-обёртки не создавались. Функции недоступны ученикам даже через UI.

### Свойства закрытых операций

- Права определяются по `auth.uid()` и отдельному `written_access`, не по названию тарифа.
- Проверяется включённая `native` программа с `published/launch_enabled=true`, живой план, предметная версия, task ID/version/token, одобренные и опубликованные требования.
- `open` только для practice, возвращает текст конкретной утверждённой локали и фиксирует `opened_at`, не выставляя оценку.
- `criteria` читает исключительно требования утверждённого задания. Для timed режима закрыто, чтобы не раскрывать ожидаемый ответ до завершения экзамена.
- `advance` атомарно переводит один step в `advanced`, сохраняет nonce и метку времени, возвращает `replayed=true` при повторе. Не записывает баллы/mastery, не создаёт AI/mentor события.
- `status` даёт восстановить подтверждение сохранения шага по learner/task/token при сбое связи.
- Ни одна новая таблица не содержит эссе, фотографий или оценок.

## 2. Материалы Economics

**22 EN-only DRAFT задания** помещены только в закрытый каталог:
- P2 — 14 элементов;
- P4 — 8 элементов.

Каждая запись имеет `status='draft'`, `academic_review='pending'`,
`language_review='pending'`, `source_review='pending'`, `release_enabled=false`.

Воспроизводимый источник без перезаписи академических правок:
`supabase/seeds/economics_9708_P2_P4_22_written_requirements_EN_DRAFT.sql`.
Это **черновики оригинальных заданий iClub**, не официальный Cambridge mark scheme и не готовые работы для учеников. Нужна академическая/языковая проверка RU/UZ/EN, правильное отображение материала-источника для Section A и проверка нормативных частей/баллов. Черновое деление 8+12 для P2 не считать официальным.

## 3. Проверки

- RLS активен для **4/4** новых private-таблиц; anon/authenticated SELECT/INSERT: **0**.
- Обычный authenticated / anon EXECUTE четырёх private-функций: **0**; service_role EXECUTE: разрешён только для закрытой интеграции.
- Анонимный вызов `advance` без `auth.uid()` получил ожидаемый отказ `42501 written_access_denied`.
- Все 22 записи: pending/draft, 0 released/approved.
- 0 записей `written_access`, 0 learner plans, 0 learner plan_items.
- Economics `status=draft`, `launch_enabled=false`.
- Контрольные количества старых записей до и после: Math sessions **543**, Math responses **1976**, Practice attempts **502**, Practice answers **4816**, user_subjects **2098**.
- Supabase security advisors: на новых private-таблицах INFO `rls_enabled_no_policy` — ожидаемое состояние в закрытой модели без прямых прав пользователей. Имеющиеся другие замечания проекта **не объявляем исправленными**: [linter RLS no policy](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy).
- GitHub source и Supabase migration-history синхронизированы именно для двух новых миграций.

**Ограничение QA:** тестированы фактическая схема, роли, состояние программы, черновики и отказ без пользователя. Успешный проход `open → criteria → advance → status` с реальной авторизацией не тестировался: нет активного Economics-программы, утверждённых заданий и назначенных учеников. Нельзя утверждать полноценный E2E PASS. Count baseline не является полной hash-проверкой пользовательских строк.

## 4. Следующие задачи

1. Академически проверить и локализовать 22 задания (EN/RU/UZ), проверить графики/источники и связь с навыками syllabus; не менять `release_enabled` до утверждения.
2. Подготовить защищённую публичную обёртку с авторизацией для соответствующего типа пользователя; проверить её только в закрытой тестовой среде, не открывая Economics в production.
3. Создать native-генератор плана Economics, корректный порядок заданий и точное следующее действие; без копирования `exam_prep_weekly_plan_items` Mathematics.
4. Провести mock/server E2E с тестовыми доступами, идемпотентностью, межпользовательской изоляцией, лимитами и откатом; затем browser desktop/mobile RU/UZ/EN в общем Exam Prep Host.
5. Только после QA и решения архитектора переключать Economics с `draft/off` на контролируемую beta.

**Решение по запуску:** NO-GO. Не включать ученический путь до выполнения всех пунктов.
