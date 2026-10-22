# iClub Exam Prep — Stage 2 / письменные задания Economics, закрытый этап

**Дата:** 22.10.2026 · **Версия:** Stage 2 v1 · **Статус:** partial implementation / draft / NO-GO.  
**Основной договор:** `docs/exam-prep-written-learning-contract-v1.md`.

## 1. Согласованная логика

Письменная практика: **условие → самостоятельная работа вне приложения → «Критерии / Требования» по желанию → «Далее»**.
Не нужны essay submission, отметка «понял», self-mark, проверка ИИ или ментор для перехода. Core не оценивает непроверенную работу. AI только объясняет учебный материал и не выполняет проверку ментора.

## 2. Закрытая реализация

| Артефакт | Состояние |
|---|---|
| `exam-prep/runtime/written-core-controller-v1.js` | Headless-контроллер, не подгруженный `index.html`; ожидает серверный open/criteria/advance/status API |
| `scripts/qa-written-core-controller-v1.cjs` | 8 smoke-checks; расширенные локальные тесты 19 PASS (не production QA) |
| `exam-prep/academic/economics-9708-P2-written-requirements-EN-DRAFT.json` | 14 уникальных письменных подпунктов/вариантов P2, EN, INTERNAL DRAFT |
| `exam-prep/academic/economics-9708-P4-written-requirements-EN-DRAFT.json` | 8 уникальных письменных подпунктов/вариантов P4, EN, INTERNAL DRAFT |
| `exam-prep/academic/economics-9708-written-requirements-P4B1-DRAFT.json` | Ранний RU/UZ/EN P4 B1-пилот, ещё не утверждён |

## 3. Академическая проверка структуры

Официальный документ Cambridge 9708 2026–2028, версия 2: https://www.cambridgeinternational.org/Images/697423-2026-2028-syllabus.pdf (Assessment overview; Details of assessment).

P2: 6 частей A на 20 баллов; 2 структурированных выбора B и 2 выбора C. Две части каждого эссе в черновике iClub распределены по 8+12, **это не подтверждённая официальная схема для конкретного задания**.
P4: 4 части A на 20; 2 неструктурированных вопроса B и 2 вопроса C.
Каждый файл содержит **требования к ответу**, а не completed solution, Cambridge mark scheme или оценку ученика. `runtime_enabled=false`, EN academic review pending, RU/UZ localisation pending.

## 4. Технический аудит интеграции

1. Существующие `private.exam_prep_weekly_plans` и `private.exam_prep_weekly_plan_items` привязаны к Mathematics legacy `program_version_id`, компонентам P1/P5, priority order и action_code. Прямое использование для Economics не утверждено.
2. Mathematics `exam-prep/exam-prep-live.js` для written требует заполненный `textarea`; менять его или отправлять фиктивный текст недопустимо.
3. В Economics `private.iclub_exam_core_*` пока есть программа, skills, papers, mapping/review-queue, но отсутствует полнофункциональный native learner plan/step service. Сначала нужен авторизованный план, только затем истинный серверный `Next`.
4. `next()` будущего API должен атомарно проверять `auth.uid()`, разрешение Core, program/version launch policy, план ученика, `plan_item_id`, `task_key` и `task_version`; повтор с новым/старым ключом должен возвращать один результат на этот же пункт. Время сервера — источник события; потери ACK → чтение статуса, не слепой повтор.
5. Серверные `criteria()` возвращают только одобренные локализованные требования, привязанные к версии задания; в timed Paper — только после финализации попытки. Черновики не доступны.
6. Вызов `next()` не записывает marks, mastery, evidence correctness, не создаёт mentor queue, AI audit или AI вызов; только факт прохождения шага.

## 5. QA и безопасность

- GitHub: изменения этапа 2 относительно `fe8357163bd7bc5ac9c0d17dcbfca7ff249517de` — только 4 **новых** файла; ни один текущий JS/CSS/SQL не редактировался.
- GitHub `index.html` НЕ содержит ссылку на `written-core-controller-v1.js`; новые assets не влияют на learner UI.
- Vercel сообщает READY по коммитам закрытых файлов. READY не доказывает browser QA.
- Supabase проверен READ ONLY; `economics_9708` всё ещё `draft`, `launch_enabled=false`. Никаких новых таблиц/миграций и изменений пользовательских строк.
- Stage 2 **NO-GO**: нет сервера плана/письменных шагов, нет завершённой академической/языковой проверки и браузерного QA.

## 6. Следующий план реализации

**Шаг A (server/plan):** определить native plan contract для Economics; затем изолированное защищённое хранение только `opened_at/advanced_at` и idempotency; без хранения сочинений. Сначала тестовая реализация/регрессия в закрытом контуре. Не мигрировать Mathematics.

**Шаг B (academic):** syllabus/skills/source-QA всех 22 пунктов; требовательная EN проверка, затем RU/UZ и обратная языковая проверка. Только одобренный контент доступен серверу.

**Шаг C (UI):** интегрировать в существующий Exam Prep Host после серверных проверок, обеспечить визуальную паритетность Mathematics, три языка и mobile/tablet/desktop. Сначала closed QA, затем контролируемая beta и разрешение архитектора.

**Не путать:** `advanced_in_plan_only` — прогресс по маршруту, не подтверждение знаний, не оценка экзамена и не результат ментора.
