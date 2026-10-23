# iClub APP — Economics 9708 Stage 5A Content Gate and Dry-Run Audit

**Дата:** 23.10.2026. **Режим:** READ-ONLY audit + local planner smoke. Economics remains NO-GO.

## Актуальная проверка кандидатов

Read-only Supabase query по `private.iclub_exam_core_question_candidates_v1` с join на `private.iclub_exam_core_skills_v1` и `public.questions`:

| Показатель | P1 | P3 |
|---|---:|---:|
| Кандидатные прямые MCQ mappings | 16 | **0** |
| Уникальные связанные навыки | 15 | **0** |
| AS mappings / A mappings | 16 / 0 | 0 / 0 |
| Утверждённые mappings | 0 | 0 |
| Legacy source опубликован и активен | 16 | 0 |
| Вопросы с текстом EN/RU/UZ | 16 | 0 |
| Варианты ответов EN/RU/UZ | 16 | 0 |
| `qa_scope_status=pending` | 16 | 0 |
| `qa_academic_status=pending` | 16 | 0 |
| `qa_language_status=pending` | 16 | 0 |
| `qa_format_status=pending` | 16 | 0 |

Существующий trilingual текст != языковое академическое утверждение. Статус опубликованного legacy question != выпуск его в Cambridge Exam Prep. 498 skill candidates не равны утверждённой образовательной программе; 200 AS + 298 A, при этом `approved=0`. В P1/P2 links все 200 direct AS skills и P3/P4 связаны с 498 включая prerequisite AS, но ни один paper-skill status пока не approved.

**Приоритет содержания:** академический QA P1, подготовка независимого оригинального P3 MCQ pilot с прямыми A Level навыками, P2/P4 оригинальный source-response/эссе с реальными критериями, версионированием источника, проверкой и тремя языками. Недопустимо автоматически переводить P1 AS вопросы в P3 A Level. Проверка правильности вариантов ответа и содержания не проводилась в данном шаге; этот отчёт не утверждает 16 вопросов.

## Live dry-run Stage 5A

Вызван `buildPlan` из актуального GitHub файла `exam-prep/runtime/native-weekly-plan-core-v1.js` с тестовым профилем `linear`, P1–P4, Stage 0, временем 180/600 минут и пустым каталогом одобренного контента (в live базе одобренных заданий 0).

Результат: `state=no_approved_study_steps`, `steps=0`, для P1, P2, P3, P4 — `approved_content_missing`, `release_authorized=false`. **Ни «completed», ни «ready», ни баллы, ни прогресс не формируются**. Это проверка fail-closed состояния, не реальный пользовательский учебный план.

Автономные учебные фикстуры в отдельном тесте: **20 PASS** на точном содержимом GitHub-файлов при выполнении в изолированном JavaScript движке; это не Node CI и не browser E2E.

## Следующий реализационный шаг

1. QA-approved source metadata: syllabus skill ↔ original Theory/MCQ/Written ↔ source versions ↔ RU/UZ/EN; канонический admission gate для live planner. Нельзя доверять присланному с клиента `catalog`.
2. Secure server-authenticated план/следующий шаг, с версионированием и сохранением без дублирования старых Math runtime/таблиц.
3. E2E с истинными JWT / активным тестовым пользователем только после академического approval; test denial, replay, revocation, offline, switch paper/subject and local storage preservation.
4. Подключать через прежний `exam-prep-host` после отдельного QA; Economics пока `draft/off`.

Документы: `docs/exam-prep-economics-stage5-native-weekly-plan-v1.md` и `docs/exam-prep-written-stage4-private-ordering-v1.md`.

**Без изменений:** legacy Mathematics/Practice/Tours, current user records, history, localStorage, exams, releases, tariffs и feature flags.
