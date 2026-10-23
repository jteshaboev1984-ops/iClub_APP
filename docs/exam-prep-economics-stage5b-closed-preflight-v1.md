# iClub APP — Economics Stage 5B / Closed Native Plan Preflight

**Дата:** 23.10.2026  
**Состояние:** Stage 5B.1 INSTALLED + QA VERIFIED; learner weekly plan **NOT** implemented; Economics NO-GO.
**Среда:** действующий production Supabase + тот же GitHub `main`, без веток и без изменения интерфейса.

## Назначение

Stage 5A создал автономный `buildPlan(input)`, но не серверный источник истинных `paper_state`, `catalog`, `focus`, `corrections`, `retests` и time budget. Каталог Economics не утверждён для нового Exam Prep. Перед созданием настоящих индивидуальных планов требуется серверная объективная проверка академической готовности.

Сейчас реализована **первая серверная часть** этого механизма — `private.iclub_exam_core_native_plan_preflight_v1(program_key, version_key)`.

Функция:
- Имеет `SECURITY INVOKER`, `STABLE`, `search_path=''`; выбирает данные только из внутреннего реестра и старого банка без их изменения.
- Находит точную версию зарегистрированной native-программы и все её Paper, не подменяя её версией другого предмета.
- Подсчитывает прямые навыки, reviewed direct mappings, reviewed AS prerequisites, MCQ candidate links, MCQ links с академическими QA pass, written drafts и QA-released written metadata.
- Возвращает по каждому Paper и программе явные причины блокировки.
- **Всегда** возвращает `can_issue_learner_plan=false`, `is_learner_specific=false`, `has_auth_evidence=false`, `can_issue_tasks=false`, пока нет отдельного проверенного персонального source/assessment runtime.
- Не выдаёт тексты заданий, ключи ответов, идентификаторы учащихся или оценки; не создаёт план, entitlement или попытку.

**Никакой пользовательский интерфейс и публичный API к этой функции не подключены.** `anon` и `authenticated` не имеют EXECUTE; `service_role` имеет доступ только к закрытому read-only preflight.

## Важные несовпадения реальных статусов

| Домен | Фактические статусы в Supabase | Статус, необходимый для следующего шага |
|---|---|---|
| Economics Core skills | `candidate/reviewed/blocked` | `reviewed` + академическая проверка |
| Paper/skill associations | `candidate/approved/blocked` | `approved`, только `direct` для прямой проверки |
| MCQ candidates | `candidate/approved/rejected` + 4 отдельных QA | `approved` и `pass` по всем QA |
| Written tasks | `draft/review/approved/retired` и QA flags | `approved`, три QA approved и release enabled |
| Subject library release | `validated` для Economics | независимая проверка связи к Exam Prep; validated библиотеки не значит approved exam |
| Program/Papers | `draft` сейчас | только после всех release gates `published` |

**Нельзя** сравнивать `private.iclub_exam_core_skills_v1.status='approved'`: такого значения нет в CHECK constraint. Stage 5A `catalog.status='approved'` — лишь унифицированный выходной статус адаптера, который впоследствии должен формироваться из подлинных раздельных серверных фактов и никогда не из поля legacy напрямую.

## Живой результат на 23.10.2026

| Paper | Прямых syllabus связей | Reviewed direct | MCQ candidates | MCQ QA-pass | Written drafts | Written released |
|---|---:|---:|---:|---:|---:|---:|
| P1 | 200 | 0 | 16 | 0 | 0 | 0 |
| P2 | 200 | 0 | 0 | 0 | 14 | 0 |
| P3 | 298 | 0 | 0 | 0 | 0 | 0 |
| P4 | 298 | 0 | 0 | 0 | 8 | 0 |

P3/P4 дополнительно имеют AS prerequisite associations, которые **не считаются прямым A Level exam evidence**. Это очень важно и должно сохраняться при формировании динамического плана.

Программа `economics_9708/economics_2026_2028_v1`: `draft / launch_enabled=false`. Все Paper также `draft`. Preflight возвращает `state=blocked` и численные/логические причины. Он не назначает студенту план и не выдумывает завершённую диагностику.

## Изменения в GitHub / Supabase

- Supabase migration `20261023070416_iclub_exam_core_stage5b_readonly_catalog_preflight_v1`: создать закрытый серверный read-only preflight.
- Supabase migration `20261023070534_iclub_exam_core_stage5b_preflight_clean_blockers_v1`: атомарно нормализовать JSON-массивы причин (удалить нерелевантные null).
- Те же SQL файлы сохранены в `supabase/migrations/` под точными версиями Supabase; не применять повторно.
- `scripts/qa-exam-core-stage5b-native-preflight-readonly.sql`: **25/25 PASS** при выполнении в живой базе (metadata/read-only).
- `index.html` не импортирует Stage 5A/5B JS, существующий Mathematics Host не заменён.

Проверки включают: закрытые grants; точную версию; 4 Economics Paper; 5 Chemistry Paper в состоянии blocked, legacy Mathematics как unsupported native; отсутствие null в причинах; подсчёт 16 P1, 0 P3, 14 P2/8 P4; отсутствие learner plan authority, оценок и персональных данных в DTO.

### Legacy count regression

| Объект | Перед | После |
|---|---:|---:|
| Mathematics Exam Prep sessions | 543 | 543 |
| Mathematics Exam Prep responses | 1 976 | 1 976 |
| Practice attempts | 502 | 502 |
| Practice answers | 4 816 | 4 816 |
| User subjects | 2 098 | 2 098 |
| Economics written plans / steps / access | 0 / 0 / 0 | 0 / 0 / 0 |

Это сравнение только контрольных количеств, не 100% hash audit строк. LocalStorage не меняли и в этом этапе не тестировали пользовательский браузер.

Supabase security advisor запускался. Он сообщает среди прежних INFO замечаний `rls_enabled_no_policy` для private таблиц. Эти замечания не считаем устранёнными или новой готовностью для публичного API: https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy

## Что **не** готово (не переносить из Stage 5A в prod автоматически)

1. Реальная личная настройка exam route, часов, target Paper, автентифицированная динамическая диагностика и ее независимые evidence per Paper.
2. Серверное сопоставление каждой Theory, MCQ, Written item с reviewed skill, approved paper role, QA state, версиями, локалями и source integrity. Для 22 written нет полноценной approved схемы source+skill mapping.
3. Оригинальные проверенные 30+ независимых MCQ на соответствующий экзаменационный набор, source snapshot integrity и полностью закрытый серверный grading.
4. Native weekly plan creation/resume/idempotent transitions. Stage4 `plan_next/open/criteria/advance/status` управляет только письменными шагами, **не** общим планом с Theory/MCQ.
5. Реальный тест положительного/отрицательного JWT, multi-user BOLA, offline recover, route-switch и browser/mobile QA.
6. Отдельное одобрение запуска Economics. Смешивать legacy Mathematics с этой новой моделью нельзя.

**Следующая Stage 5B.2:** серверная *read-only* выдача допускаемых материалов (Theory/MCQ/Written) с полной академической проверкой, без знания о персональной успеваемости. Затем Stage 5B.3 — отдельные authenticated assessment/evidence/profile источники, объединение с детерминированным Stage5A plan builder, без пользовательских активаций. Для MCQ/Essay критический blocker: академическая база все еще в статусе candidate/draft; не подменять это случайным рабочим контентом.

## Rollback boundary

Новые функции ни на что не подключены. Для немедленной остановки внутреннего доступа достаточно отозвать EXECUTE у service role; исторические миграции и пользовательские записи не удалять. Дальнейшее включение — только после комплексного QA и решения архитектора.

**Вывод:** Stage5B.1 завершён как закрытая verified preflight проверка. **Stage 5B в целом и Economics Exam Prep не готовы к beta.**
