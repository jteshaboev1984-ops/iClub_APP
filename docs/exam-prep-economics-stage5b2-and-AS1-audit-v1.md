# Stage 5B.2 + банк Economics AS-1 — закрытый результат и передача (23.10.2026)

**Экономика Exam Prep по-прежнему NO-GO, без видимого ученикам изменения.** Это отчет о технической изоляции и read-only инвентаризации, НЕ академическое утверждение вопросов.

## 1. Сделано

- Установлена `private.iclub_exam_core_native_content_allowlist_v1(text,text,text,integer)`, версия Supabase migration `20261023072744_iclub_exam_core_stage5b2_readonly_academic_allowlist_v1`, исходник в `supabase/migrations/` GitHub.
- **Закрытая и только для service_role:** `SECURITY INVOKER`, `STABLE`, фиксированный search_path, `anon/authenticated EXECUTE=false`, нет функций изменения состояния. Не подключена к frontend. Задача — выбрать *безопасные метаданные* кандидатов для будущего planner, **без текста вопроса, ответа, баллов, UID и оценки**.
- Theory: нужны `sk.status='reviewed'`, `paper_skill.status='approved'`, совпадение library hash и валидированной версии Theory, заполненные EN/RU/UZ title+explanation, прямое level соответствие или только разрешённое AS prerequisite для A Theory.
- MCQ: дополнительно `candidate.status='approved'`, все четыре QA `pass`, `direct`, verified skill & level, исходное опубликованное active MCQ, трёхъязычные текст/варианты/объяснение, однобуквенный ключ, и **md5 live snapshot = кандидатный md5 = private review snapshot**. Точный md5-алгоритм повторяет миграцию `20261021203000_iclub_exam_core_review_queue_and_shell_v1.sql`.
- Written: всегда пустая коллекция, пока отсутствует approved written-task-to-skill-to-source mapping; 22 EN-only draft не считаются готовыми.
- Весь DTO `can_issue_learner_task=false` всегда. Не создаёт personal plan, не выдаёт и не выставляет баллов.

## 2. Выполненное QA

`scripts/qa-exam-core-stage5b2-content-allowlist-readonly.sql`: **27/27 PASS** на текущей production базе. В частности:
- Четыре Economics Paper возвращают `closed_catalog_preview`, 0 approved Theory/MCQ/Written.
- Статусы программы `draft/off`, незнакомая версия и Paper fail closed, legacy Mathematics и невалидированная Chemistry не затронуты.
- EXECUTE: anon=false, authenticated=false, service_role=true.
- Никаких learner plans/steps. Контроль legacy numbers (нижние границы исторических выборок) соблюдён.
- **Не тестировался положительный путь с одобренными заданиями, потому что таких заданий нет**; перед любым learner GO нужен реальный тест полного allowlist->session->grading/resume и браузер.

Между предыдущим и нынешним SELECT старые контрольные значения: Math sessions 543, responses 1976, Practice attempts 502, answers 4816, user_subjects 2098. Контроль только счетчиков; не checksum.

## 3. Подготовлен первый академический пакет AS-1 / P1

Файл: `exam-prep/academic/economics-9708-mcq/AS1-P1-Units1-2-30-question-review-shortlist-v0.1.json`.

**30 без дублей:** 16 уже существующих P1 `candidate` Unit 2 + 14 read-only shortlist из Unit 1, который **не записывался в Core mapping**. Все 30 — опубликованные/активные legacy MCQ с заполненными вопросами/вариантами/объяснениями EN/RU/UZ. Наличие полей не означает качественно проверенного перевода.

Unit 1 (14) IDs:
`8608,8615,8633,8634` scarcity/choice;
`8609,8635,8641` factors;
`8610,8611,8651` goods;
`8630,8632,8663` PPC;
`8654` systems.

Среди 30: **0 active Tour intersections**; **4 active Practice intersections**: `8616,8619,8621,8625`, все из старых 16 P1; 14 новых не пересекаются с активными Practice/Tours и имеют provenance `-P-`, а не `-T-`.

**Критические недостающие части для качества:**
1. Unit 1 `Economic methodology`: в текущем legacy source нет свободного от активных Practice/Tours задания с корректным происхождением P-, потому необходимо создавать новые оригинальные вопросы, а не «переиспользовать как невидимые» чужие пулы.
2. Проверить прямой `syllabus_point` у `8618` и `8622` (сейчас связаны `2.4.3`), плюс остальным; текущее review только первичный смысловой просмотр, не external academic QA.
3. Четыре пересечения с Practice не должны попадать в **независимый timed mock** до решения о раздельных пулах. Старые наборы не изменять.
4. Для всех 30 нужно полноценное независимое QA EN/RU/UZ, вариантов/ключей, причин выбора и syllabus; не переводить `pending` в `pass` по одному наличию полей.
5. Ещё нет P1 Unit3–6 и ни одного P3 A-depth mapping; AS-1 не является полноценной входной диагностикой или Paper.

**Никакие старые вопросы, Practice/Tour назначение, release flags или данные учеников не переписывались.**

## 4. Что дальше — без дублирования и микрошагов

Продолжать по `docs/exam-prep-economics-working-plan.md`:
- **Крупный академический проход AS-1:** единое досье правильности и syllabus mappings для 30, дополнить оригинальными методологическими question(s) в отдельном closed draft, затем независимый QA ответов и RU/UZ. Не утверждать пока без сверки с syllabus.
- После AS-1 — AS-2 (3–4), AS-3 (5–6), A-1 (7–8), A-2 (9–11) партиями **24–36 за один проход**; новая партия только после исправления замечаний предыдущей.
- Существующую new allowlist **не открывать браузеру**; следом Stage5B.3 verified authenticated learner profile + диагностические факты и только потом native weekly plan integration.
- Отдельно P2/P4 written batches и правило достоверного timed essay grading.
- Прежний UI Mathematics, прогресс, Practice/Tours, localStorage остаются нетронутыми.

**При любом новом чате:** открыть основной working plan, этот отчет и живые Supabase/GitHub, проверить последние миграции и отсутствие других параллельных изменений. Ничего не включать без решения архитектора.
