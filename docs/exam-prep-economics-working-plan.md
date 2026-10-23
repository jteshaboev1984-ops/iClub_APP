# iClub APP — Economics 9708 Exam Prep: ЖИВОЙ РАБОЧИЙ ПЛАН / HANDOFF

**Версия:** WORKING v0.1 · **дата:** 23.10.2026 · **статус:** действующий план, обновлять по факту, а не переписывать историю.
**Назначение:** точка восстановления между чатами. Сначала читать этот файл, затем актуальные GitHub/Supabase, сверить даты и коммиты; если отличаются — приоритет у текущих проверенных фактов, исправить план. Этот документ — не разрешение открывать функцию ученикам.
**Канонический репозиторий:** `jteshaboev1984-ops/iClub_APP`, ветка `main`. **Supabase:** `mmmduffgpvwjdpruzikw`. **Предмет:** `economics_9708`, программа `economics_2026_2028_v1` (Cambridge 9708 2026–2028, версия 2). В репозитории: `docs/exam-prep-economics-working-plan.md`. Сохранять копию в личной Library, поскольку чат имеет лимит.

## 1. Цель и неприкосновенные решения

Полный Exam Prep Economics AS/A Level P1–P4: настройка → диагностика по компонентам → честный результат → личный недельный план → Theory/Tutor → MCQ и самостоятельная письменная практика → разбор ошибок → отложенный retest → смешанная практика → timed Paper → реальная подтверждённая готовность, с корректным различием AO1/AO2/AO3.

- **Сохранить production:** Mathematics Exam Prep, Practice, Tours, авторизацию, прогресс, ответы, оценки, localStorage и историю версий. Все изменения аддитивные, отдельный feature gate, без сбросов, без новых веток и без переноса Math evidence.
- **Единый интерфейс:** использовать существующий Mathematics Exam Prep Host и красивую, симметричную многоязычную RU/UZ/EN визуальную систему. Не создавать чужеродный Economics UI и не показывать школьнику внутренние термины.
- **Core отдельно от AI и Mentor:** ученик может учиться без AI/Mentor. Они не имеют права выставлять достоверные баллы вместо сервера. Ученик самостоятельно решает письменное задание вне приложения; опционально видит критерии; `Далее` = навигация, НЕ правильность, mastery или verified progress. Полный timed P2/P4 требует самостоятельного утверждённого правила проверки и не получает выдуманной итоговой оценки.
- **Оценивание:** P1 — 30 MCQ/60 мин; P2 — письменный 120 мин/60 marks A20 B20 C20; P3 — 30 MCQ/75 мин; P4 — письменный 120 мин/60 marks A20 B20 C20. AS = 200 навыков (прямо P1/P2), A = 298 навыков (прямо P3/P4). AS prerequisite в P3/P4 НЕ эквивалентен прямому A-level вопросу. Syllabus/официальный exam blueprint важнее расположения в книге и семи Tour.
- **NO-GO:** `status=draft`, `launch_enabled=false`; не подключать в `index.html`, не выдавать задания ученикам до academic/security/browser acceptance и решения архитектора. `Vercel READY` ≠ E2E PASS.

## 2. На чём остановились (проверено 23.10.2026)

- Subject library Economics: 498 Theory + 1494 Tutor RU/UZ/EN, `economics9708_20261021_p62` validated; *не означает approval в Exam Prep*.
- Exam Core: 498 skills (200 AS, 298 A); 996 direct Paper–skill candidate links плюс 400 prerequisite AS links для P3/P4; `reviewed/approved` необходимых связей 0 на проверенной базе.
- MCQ legacy bank: опубликованных активных MCQ ~1644, но **Exam Prep mappings только 16 P1** (15 уникальных навыков, все syllabus Unit 2), `candidate` и 4 QA pending; **P3 0**. Трёхъязычный текст есть у 16; перевод/ключи ещё не утверждены. Не считать весь legacy bank готовым к Exam Prep. 39 input и 19 выключенных draft MCQ не использовать как полноценные MCQ.
- Written: 14 P2 + 8 P4 черновиков, 22 всего; исходники P2/P4 Section A синтетические, EN-only, `release_enabled=false`. Нужны предметные mark requirements, источник/права, RU/UZ/EN и paper/skill mapping.
- Stage 3/4: закрытые private written tables + канонические `plan_next_v1/open_v1/criteria_v1/advance_v1/status_v1`. Дубликаты прошлых миграций уже согласованы; **не повторять**. Нет learner access/plans/items.
- Stage 5A: закрытый JS selector `exam-prep/runtime/native-weekly-plan-core-v1.js`; `scripts/qa-native-weekly-plan-core-v1.cjs`: 20 fixture PASS; план не подключён к действующему хосту и ничего не записывает.
- Stage 5B.1: функция `private.iclub_exam_core_native_plan_preflight_v1(text,text)` установлена с миграциями `20261023070416` + `20261023070534`, service_role ONLY, read-only, всегда `can_issue_learner_plan=false`, сообщает реальные блокировки. `scripts/qa-exam-core-stage5b-native-preflight-readonly.sql`: 25/25 PASS. Это не персональный план.
- Последняя контрольная выборка: Mathematics sessions=543, responses=1976; Practice attempts=502, answers=4816; user_subjects=2098; Economics access/plans/items=0. Это сравнение количеств, **не** checksum и не браузерный QA; при следующей работе записать свежий baseline, если активность пользователей изменилась.

## 3. Банк вопросов: как делить, чтобы не терять качество

Работаем по **пяти крупным предметным пакетам**, а внутри каждого — **одна осмысленная партия 24–36 кандидатных MCQ за проход**. Ни 1644 сразу, ни отдельные микропакеты по 2–3 вопроса. Партия закончена только если по каждому кандидату готов полный QA-dossier + повторный независимый выборочный аудит; иначе не расширять объём. Размер может уменьшиться, если обнаружена массовая ошибка — качество важнее числа.

| Пакет | Экзамен | Учебная область | Приоритет |
|---|---|---|---|
| **AS-1** | P1 | Syllabus Units 1–2: базовые понятия, спрос/предложение/эластичность; перепроверить 16 старых кандидатов | Дать эталонный академический QA и не дублировать Unit 2 |
| **AS-2** | P1 | Units 3–4: intervention, inequality, макроиндикаторы, AD/AS | Закрыть серьёзную дыру P1 |
| **AS-3** | P1 | Units 5–6: макрополитика, торговля, курс, current account | Завершить первичное покрытие AS |
| **A-1** | P3 | Units 7–8: consumer choice, firm, market failure, labour market | Начать отдельный прямой A-depth, не использовать AS как P3 |
| **A-2** | P3 | Units 9–11: advanced macro, policies, international/development | Закрыть первичное покрытие P3 |

**Каждая партия проходит одинаковые 4 крупных шага, не дробить до микрозадач:**

1. **Сначала audit/blueprint:** сверить Cambridge syllabus (level/unit/learning objective/AO), книгу и Tour Map как вспомогательный порядок, выгрузить read-only инвентарь legacy для указанной области, определить пробелы и непригодные вопросы. Проверять также диаграммы/числовые данные/типы MCQ и 3 языка. Не полагаться на `topic` как единственный источник уровня.
2. **Сформировать целую кандидатку 24–36:** отбор достойных legacy или создание оригинальных вопросов (не переписывать copyrighted Cambridge items); для каждого immutable source-id/hash, skill exact, paper direct vs prerequisite, 4 опции, 1 однозначный ключ, reasoning, distractor rationale, AO, difficulty, locale EN/RU/UZ. Исходные `public.questions` без нужды не менять. Если языки/контент не проверены — draft или candidate, не published.
3. **Два слоя QA:** детерминированный (структура, 4 опции, 1 ключ, checksum, дубликаты/permutation, локали, формулы, paper version, запрет пересечения с оценочными/mock pools), затем академический (сyllabus, правильность, ambiguity, уровень, формулировка, язык, diagrams, bias). QA status `pending` до реальной проверки; не ставить `pass` массово или по одному факту наличия текста. Отдельно сохранить найденные ошибки и судьбу каждого вопроса: accept candidate / revise / reject.
4. **Закрыть пакет артефактами:** версионированный JSON/CSV/MD в `exam-prep/academic/economics-9708-mcq/`, QA-report + источник/решение, контроль дублей/покрытия и resume checkpoint. Только после PASS двигаться к следующей партии, отмечать реальный прогресс здесь и в таблицах кандидатов через аддитивные миграции, не в legacy History.

**Сначала все пять пакетов по одному проходу**, затем повторять только нужные области новыми партиями. Не концентрировать выпуск на одном Unit 2. Рубеж «можно пробовать полный Paper»: как минимум *три независимых набора по 30 проверенных MCQ на каждый P1/P3* + отдельный достаточный диагностический/практический резерв, корректные веса и покрытие Units, отсутствие раскрытия ключей, verified server attempts/resume. Это **внутренний минимальный ориентир**, а не требование Cambridge и не гарантия готовности; конечные объёмы утверждать после анализа повторов и blueprint.

**Письменный банк — отдельно:** после MCQ baseline блок P2 и блок P4 (по 10–14 осмысленно связанных заданий/подвопросов с исходным source и индивидуальными criteria), каждый QA по AO1/AO2/AO3, source correctness, mark allocation, графикам/расчётам, оценке альтернатив, 3 языкам. Не считать 22 EN-only draft готовым банком, не смешивать обычный `Next` с оценкой пробного Paper.

**Важно про семь Tours:** Tour Map Economics предназначен для учебного маршрута Theory/Practice. Tour question pools, Practice pools и Exam Prep question sets должны оставаться разделены; дубликаты и пересечения по `question_id`/снимкам проверять по назначению. Учебная группировка Tours 1–3 соответствует AS Units 1–6, Tours 4–7 — A Units 7–11, но это **не** экзаменационная схема выбора Paper.

## 4. Технический маршрут, связанный с контентом (не стройка вслепую)

**T1: Stage 5B.2 — CLOSED allowlist**. Только private, `SECURITY INVOKER`, service-only; отбирать данные с точными program/version/paper/skill; для Theory — validated library + reviewed skill + approved paper link + 3 проверенные локали; для MCQ — approved candidate + все 4 QA pass + pinned hash + approved direct skill и approved paper link + опубликованная неповреждённая запись; для Written — approved source/task requirements + QA/3 локали + отдельная approved skill mapping (пока не существует, поэтому Written fail closed). Возвращать только безопасные метаданные без answer keys. При нынешнем банке ожидается пустая учебная allowlist. Test invalid version/math/chem/anon/auth/roles, regress user data; не разрешать learner access.

**T2: Stage 5B.3 — персональные доказательства**. Реальная auth/owner profile, экзаменационные компоненты, часы (без вымышленных квот), доказательства диагностики/ошибок/retest с отдельными версиями и paper, server-authoritative stage и signed session; после этого соединять закрытый планировщик с allowlist. Конкретное открытие learners только после E2E.

**T3: Backend E2E and Host**. Idempotent generation/resume/`Next`, locked keys, таймер и source-state, offline/replay, BOLA/cross-user, RU/UZ/EN и desktop/mobile, Math/Practice/Tours regression. Показать пользователю знакомый Mathematics Exam Prep Host только после подтверждённого QA.

**T4: small closed beta/GO**. Отдельное решение архитектора, наблюдение ошибок, простое OFF, журнал версий, rollback без удаления строк или local progress; затем перенести конструкцию на Chemistry/Biology/CS с их настоящими exam policies.

## 5. Работа в следующих чатах и правила остановки

1. В начале прочитать именно `docs/exam-prep-economics-working-plan.md` + актуальные Stage 5B docs + проверить последние коммиты/миграции/флаг/no-go/текущее число legacy rows. **Не спрашивать заново**, что такое проект и на чём остановились.
2. Отметить текущий пакет и T-этап, закончить его QA, обновить `Прогресс` и `Следующее действие` в конце этого плана. Не переходить к следующему пакету, если у текущего есть неразобранные существенные ошибки.
3. Предпочитать closed assets/source reviews и новые private функции; не менять существующий live frontend/legacy/public data без явной архитектурной причины и отдельной регрессии. Сначала минимальное изменение, потом QA и фиксация SHA.
4. Любая неопределённость academic accuracy, official answer, diagram, copyright, перевод или mapping => `pending/revise`, не автоматически `pass` или GO. `READY` deployment не считать проверкой.
5. Если в GitHub/Supabase уже появились параллельные изменения — прочитать их, не делать дублированные функции/индексы/миграции. Останавливаться только по реальному риску для production или архитектурному решению владельца.
6. Для ручных операций пользователя только точные места «предыдущий код / замена / следующий код»; лучше выполнять технические изменения в подключённых системах самим. Ученический UI — без терминов вроде «adapter» или «лесенка».

### Прогресс (заполнять после каждого содержательного блока)

- [x] Stage 5A: закрытый planner, 20 fixture PASS.
- [x] Stage 5B.1: закрытый catalog preflight, 25 read-only PASS, миграции сохранены в main.
- [x] Рабочий план сохранён и в личную ChatGPT Library (`/iClub APP/Exam Prep/`), и в репозиторий (`docs/exam-prep-economics-working-plan.md`).
- [x] Согласована размерность банка: 5 тематических блоков × партии 24–36, 4 уровня пакета/контроля.
- [x] **Stage 5B.2:** closed Theory/MCQ allowlist service-only; миграция `20261023072744`, 27/27 read-only QA PASS. Письменные закрыты до approved task/skill mapping; реальная выдача ученикам запрещена.
- [ ] **Активный пакет AS-1:** сформирован read-only shortlist **30 вопросов** (16 существующих P1 Unit 2 + 14 отобранных Unit 1 без активных Practice/Tours и без provenance Tour); 30/30 trilingual fields присутствуют, 4 старых P1 кандидата используются Practice: `8616, 8619, 8621, 8625`. Все 30 остаются академически `pending`, 14 новых **НЕ добавлены в Exam Prep candidate table**. Файл `exam-prep/academic/economics-9708-mcq/AS1-P1-Units1-2-30-question-review-shortlist-v0.1.json`. Unit1 methodology требует новых оригинальных вопросов.
- [ ] AS-2 / AS-3 / A-1 / A-2, по одному содержательному проходу, потом расширение по coverage.
- [ ] Письменный банк P2/P4, полный verified grade policy для mocks.
- [ ] Персональный auth/evidence план, Host, E2E и beta.

**Следующее действие:** провести ОДИН полноценный академический проход **AS-1 по 30 кандидатам** (точный Cambridge syllabus/skill mapping, EN/RU/UZ смысл, правильный ключ/дистракторы, подсчёты/графики, source integrity/права, дубли и 4 пересечения Practice) и подготовить оригинальные вопросы по Unit 1 Economic methodology, сохраняя `pending` до независимой приёмки. Затем переходить к AS-2 как к следующему содержательному пакету; параллельно проектировать только закрытые серверные evidence/auth источники Stage5B.3. Отчёт: `docs/exam-prep-economics-stage5b2-and-AS1-audit-v1.md`. Без GO, без правок legacy, без новой ветки.