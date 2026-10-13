# iClub AI Layer — Master Plan v2.1
**Дата:** 2026-10-12  
**Статус:** утверждены 44 решения раундов 1–8; дополнительно утверждён только **временный, тестовый** смешанный учёт AI 1:3. Итоговая тарифная модель НЕ утверждена.  
**Ветка реализации:** `qa/iclub-ai-layer-v21-20261012` (от production SHA `9afc7b44aead03b2a30544e6e7d4c4eb8670efbf`).  
**Приоритет:** защита действующей системы и настоящих учеников. Данный документ не разрешает изменение production, main или пользовательских данных.

## 0. Цель и инварианты

Один фирменный iClub AI должен быть доступен во всех разрешённых экранах и учебных направлениях приложения. Конкретные объяснения открываются только после проверки подготовленности экрана, функции, предмета, темы и языка; иначе ученик видит «В разработке» и доступные альтернативы. Ученик не выбирает «модель» или «тип биллинга»: маршрутизацию делает сервер.

Сохранять working Mathematics Exam Prep P1/P5 AI как успешный эталон; не заменять его маршрут до parity и QA. AI объясняет, но НИКОГДА не меняет mastery, readiness, marks, placement, progress, lesson state, рейтинг, сертификаты, Practice/Tours/Exam Prep evidence, права ментора, исторические записи или localStorage. Provider credentials — только сервер. Core работает при AI OFF. Видео AI не заявляет знание видео без утверждённых транскриптов и меток.

Обязательные запреты: никакого чтения чужих записей, закрытых ключей, активных/будущих Tour, неоткрытых архивов; никакой записи AI в академические таблицы; никакого публичного/платного rollout без отдельного решения владельца. События учета минимальны, постоянной сырой истории чата нет.

## 1. Все 44 зафиксированных продуктовых решения

| ID | Обязательное поведение |
|---|---|
| 1A | Один фирменный AI-значок в приложении и контекстные кнопки там, где функция готова. |
| 2A | Общий iClub AI остаётся доступным, если AI отдельного экрана «В разработке». |
| 3A | Готовые темы открываются, не дожидаясь всего предмета. |
| 4A | Сперва единый интерфейс, затем постепенное подключение функций. |
| 5A | AI автоматически определяет экран, предмет и тему. |
| 6A | Сохраняем работающий Mathematics Exam Prep Tutor; переход только через parity. |
| 7A | Только подтверждённые результаты, темы и ошибки; cross-subject анализ после защищённого контракта. |
| 8A | Сначала краткое объяснение; углубление и примеры — при готовом материале. |
| 9A | Переписка живёт только внутри текущей сессии. |
| 10B | Practice: AI-разбор только после окончания всей практики, не после каждого ответа. |
| 11A | Tours: отдельные ошибки и общий результат только после серверного открытия архива. |
| 12A | Неготовая тема — «В разработке» плюс готовые альтернативы/помощь по iClub. |
| 13A | Home объясняет следующие шаги, Profile — подтверждённый прогресс. |
| 14A | Не размещать «Скоро» на каждой кнопке; показывать статус при обращении. |
| 15C | Создать новую серию оригинальных AI-символов; выбор владельца отдельно. |
| 16A | Значок внизу справа с safe-area и учётом нижней навигации. |
| 17A | Мобильная панель ~70–80% высоты и раскрытие на весь экран. |
| 18A | «Объяснить» открывает единую панель с выбранным контекстом. |
| 19A | Учебный чат: короткие абзацы, формулы, шаги, подходящие уточнения. |
| 20A | При смене экрана панель сворачивается; переписка сессии остаётся, контекст обновляется. |
| 21A | Защищённый синтетический Preview → отдельная малая beta только с разрешения владельца → расширение. |
| 22B | В НОВОМ едином UI каждый успешно выданный ответ учитывается по тарифу, включая готовые карточки. |
| 23B | Первыми кандидатами на Global AI beta будут три текущих Exam Prep AI ученика после отдельного разрешения. |
| 24A | Сначала mock provider; реальные платные запросы — только после отдельного разрешения. |
| 25B | Free/Plus/Pro экраны готовим в Preview; реальных оплат и принудительных ограничений нет. |
| 26A | Перед первым использованием короткое объяснение возможностей AI и использования данных. |
| 27A | Сессионная память в пределах отдельного предметного чата; предметы не смешиваются. |
| 28A | Следующий шаг AI объясняет по серверному плану и подтверждённым ошибкам, не меняя маршрут. |
| 29B | Ученик оспаривает ошибочное объяснение в чате, без отдельной кнопки жалобы. |
| 30A | Готовность и QA отдельно по каждой теме и языку. |
| 31C | При техническом сбое — подходящий проверенный готовый ответ; иначе «AI временно недоступен». |
| 32C | Язык ответа определяется по языку вопроса, только при готовом источнике на этом языке. |
| 33B | При активной защищённой проверке AI-значок полностью скрыт; backend тоже блокирует все пути. |
| 34A | Только минимальный проверенный контекст, без answer keys и ненужных персональных данных. |
| 35A | Противоречие утверждённых источников → блокировка спорной темы до редакционной проверки. |
| 36C | Попытка обойти защиту → временная блокировка вопросов по защищённой теме до конца проверки. |
| 37A | Только минимальный технический журнал, без постоянной полной переписки. |
| 38C | После утверждения release-этапа готовые функции могут автоматически открываться после всех gates, только в разрешённом cohort. |
| 39A | Первоначальный Preview — исключительно синтетические данные, без production Supabase и реальных пользователей. |
| 40A | Readiness отдельно по экрану, предмету, функции, теме и языку. |
| 41A | Перед beta обязательный полный QA: пути, мобильность, RU/UZ/EN, экзамены, лимиты, prod unchanged, Exam Prep parity. |
| 42A | Управляемые сервером разрешения функций, не новая сборка на каждую тему. |
| 43A | Критическая ошибка отключает конкретную функцию; системная угроза — весь новый AI Layer. |
| 44A | Новая готовая функция становится доступной без навязчивых объявлений. |

## 2. Новое уточнение после раунда 8: СМЕШАННЫЙ СЧЁТЧИК — ВРЕМЕННО

**Статус: TEST-ONLY, НЕ окончательная коммерческая политика.** Следующая модель заменяет конфликтующий старый принцип «не поместился дорогой route → весь AI закрыт до reset».

- Один общий 5-часовой период; старт только после **первого успешного ответа**.
- ТЕСТОВЫЕ квоты: **Free=3, Plus=9, Pro=14** внутренних долей за 5 часов.
- **Prepared / approved contextual / safe exact cache = 1 доля; new generated answer = 3 доли.** Free generation запрещена.
- Сервер ДО вызова модели выбирает **точный семантически подходящий** prepared route или source-backed generated route. Нельзя выдавать неподходящую готовую карточку вместо сгенерированного ответа для экономии.
- СЕРВЕР проверяет остаток `available = allowance - committed - active_reserved` и **атомарно** резервирует `weight` на неизменяемый `request_id`.
- Если `available < weight`, отказать только **этому** маршруту: **не списывать, не ставить общий `exhausted=true`**, не вызывать модель, не закрывать более дешёвые пути. Повторить запрос другого маршрута разрешено.
- Пример: осталось 2 → generated за 3 отклонить, остаток **2** → prepared за 1 разрешить (1) → prepared за 1 разрешить (0) → после этого лимит исчерпан.
- Если уже есть параллельные резервы и кратковременно не хватает на запрос, вернуть `busy/retry` без глобальной блокировки; серверная транзакция или advisory lock предотвращает overspend.
- Успешный валидированный ответ → `finalize(completed)` однократно; отказ safety/no-source/timeout/provider failure/недоставка → `finalize(released)`. Требуется идемпотентный retrieval/retry при неясном статусе доставки.
- Сначала проверка protected assessment, readiness, entitlement и source; после ученической квоты отдельная проверка денежного бюджета провайдера. Никаких provider calls при отказе по квоте.
- Состояние «В разработке» и отказ по отсутствию источника **не списывают** лимит.
- Ученик **не видит** внутренние веса, стоимость модели, route type и счётчик; при полной исчерпанности — время восстановления и понятное сообщение. При дорогом недоступном маршруте допускается объяснить, что этот тип ответа временно недоступен, но готовые объяснения ещё доступны.
- Решение **22B** касается **новой** единой панели. Старый Exam Prep Tutor не получает скрытого дополнительного списания до проверенного перехода.
- **Экономика:** при весе 3 максимумы Plus=3 и Pro=4 generated replies за свежие 5 часов, что **вдвое или более** повышает worst-case нагрузку против прежних 1/2 generation при весе 5. Перед реальной монетизацией провести расчёт по действительным ценам/token usage, worst-case, провайдерному budget, практике ответов и злоупотреблениям. Только после тестов архитектор утвердит финальные доли, веса и ограничения.
- Ранее записанное правило `generated=5` и `v_period.exhausted=true` при недостатке лимита остаются ФАКТОМ нынешней схемы; их **нельзя изменять в production**. Исправление делать в изолированной тестовой схеме и после регрессии.

## 3. Целевая архитектура

`iClub AI UI` (General + раздельные предметные чаты, сессионно) → `server auth + current surface/subject + active-assessment guard` → `readiness registry(surface,subject,feature,topic,locale,source_version,QA_status)` → `domain adapter` → `exact prepared / approved deterministic / safe exact-cache / source-backed model` → `learner quota atomic reserve` → `optional provider cost reserve` → `output/source/locale validation` → `finalize or release` → `reply + minimal audit`.

Академическая истина принадлежит deterministic Core; наставник — отдельная человеческая проверка. Отсутствующий source/gate не обходит защиту через общий model fallback. Формальные контракты для cache и semantic exact matching нужны до публикации.

## 4. Экраны и готовность

| Экран/предмет | Утверждённый сценарий | Условие готовности |
|---|---|---|
| General iClub | Навигация и помощь по возможностям приложения | Проверенные инструкции; no invented capabilities |
| Home | Объяснить следующий шаг | Server-owned cross-subject next-actions |
| Profile | Объяснить подтверждённый прогресс | Minimum signed server aggregates |
| Mathematics Exam Prep P1/P5 | Сохранить действующего Tutor + позднее общий чат | Approved 243 Tutor Cards; per-component authority; parity |
| Practice | Разбор всего завершённого результата | Server finalization + approved result context |
| Tours | Общий итог/ошибки | Server-authorized **opened archive**, not merely submit |
| Lessons/topics | Точные объяснения по теме | Approved source/topic/locale |
| Economics / Chemistry | Сначала готовые source-backed темы | Content QA, diagnostic mapping, adapter and readiness |
| Biology / Informatics / Computer Science | По темам после контент-аудита | Approved governed sources and negative tests |
| English A1/A2/B1 / SAT / другие | Единая оболочка; неготовые функции «В разработке» | Отдельный реестр и контракты, без model guessing |
| Videos | AI не знает содержания конкретного ролика | Только будущий approved transcript + timestamps |

Подтверждённый read-only baseline 2026-10-12: `main` production SHA `9afc7b44...`, Supabase `mmmduffgpvwjdpruzikw`; Exam Prep core ON / AI ON для 3 beta entitlements / Mentor OFF; Exam Prep 243 Tutor v3 cards и 243 theory sources active; Practice AI OFF; Global AI UI/gateway/model OFF, kill switch ON; global subscriptions и usage=0. Practice approved source cards: Economics 81×3 языков, Chemistry 38×3 языков. Эти числа — датированный снимок, перед промоутом проверяются заново.

## 5. Этапы реализации P0–P9

| Этап | Работа | GO/NO-GO |
|---|---|---|
| **P0** read-only baseline | HEAD/production/flags, schema, README/docs, impact map, privacy and integrity invariants | Written evidence, no prod writes |
| **P1** существующий защищённый Vercel Preview | Использовать готовую ветку `qa/fix-exam-prep-subject-isolation-20261011` как UI QA-среду; добавлять только автономные QA-страницы, mock/fixtures и безопасные read-only обращения. Preview может быть связан с production Supabase; **новые AI-функции не пишут в эту базу**, регистрировать тестовые аккаунты ради AI запрещено | Проверка без AI DB writes, без новых аккаунтов и без переключения production; все UI-обращения проверены |
| **P2** readiness/router | Registry screen×subject×feature×topic×locale, exact response routes, no-source/blocked policies | All negative routes fail closed |
| **P3** unified UX | Фирменный знак для выбора; mobile sheet 70–80%, desktop panel, 3 языка, context and security blackout | 320/390/desktop QA; hide AI during exam |
| **P4** Math parity | Existing Tutor adapter + new UI, 243 cards and split P1/P5, one accounting path | Existing beta untouched; no double-charge |
| **P5** Practice/Tours | Practice only after full completion; Tours only open archive | No active/locked/foreign access |
| **P6** subjects/Home/Profile | Approved materials per topic/locale; server next-actions | Per-feature QA; unready says «В разработке» |
| **P7** tariff/safety Preview | **ТЕСТОВЫЕ 1:3, Free/Plus/Pro 3/9/14**, synthetic reserve/finalize/release, cost and concurrency gates | 2 leftover → generated3 denied → 2×prepared1 allowed; no doubles |
| **P8** full QA | Security/privacy/RLS, academic isolation, regressions, UX, provider mock, optional approved provider canary | All Sev0/Sev1 green |
| **P9** GO/NO-GO | Owner separately approves exact beta cohort/provider/live spend; current 3 beta students first candidates | No automatic production/public launch |

## 6. Расхождения в существующем коде (очередь на исправление)

- **G-01:** `global-ai-ui.js` muted exam mark; **33B** requires fully hidden.
- **G-02:** `practice-ai` post-answer route exists; **10B** allows learner AI only after completed session.
- **G-03:** Existing `iclub_ai_subject_readiness` is scope-based, not full screen/topic/locale registry.
- **G-04:** New UI 22B must not double-charge existing provider-free Math Tutor.
- **G-05:** Current Global AI model promotion limited to scoped Mathematics Exam Prep; no generic all-subject fallback.
- **G-06:** Current UI defaults to app locale; **32C** requires question locale + matching approved source.
- **G-07:** Session-only chat; no unintended raw transcript persistence.
- **G-08:** Automatic feature opening 38C only inside approved rollout cohorts 21A.
- **G-09:** Provider model, token pricing, dollar ceilings and real secret config must be reverified before funded calls.
- **G-10:** All RU/UZ/EN user text checked; never show internal labels.
- **G-11 (новое):** Current `reserve_iclub_ai_usage_service_v1` may mark the whole period exhausted when route too expensive; current `generation_weight=5`. **TEST-ONLY FIX:** generated=3, reject only expensive route, preserve remaining quota for prepared1 and rerun concurrency/idempotency tests; no production DB modification.

## 7. Минимальная обязательная тестовая матрица

1. `remaining=2`: generation3 denied, no provider call, `exhausted=false`; two prepared1 accepted, next denied.
2. Free: exactly three eligible prepared replies in a five-hour window, generation blocked, no usage charged on forbidden generation.
3. Plus/Pro: all ordered combinations of prepared1/generated3 whose sum ≤ current allowance succeed; next over-budget route rejected without losing residual.
4. First failed request does not start five-hour clock; first completed request starts exactly one period.
5. Double-click, same request_id replay, timeout/retry, two concurrent requests: atomic, no double-charge/negative balance.
6. Approved cached answer is exact and contextual; unsafe approximate cache or fabricated answer rejected.
7. Provider failure, output rejection, no-source, blocked assessment, billing failure: no learner units charged and no academic writes.
8. Protected diagnostic/retest/mixed/timed/paper and Tour: icon hidden; backend denies prepared, cache, model.
9. Practice incomplete: no AI; closed Tour archives: no AI; cross-user leakage: no AI.
10. Core with AI OFF still works; current Math Tutor beta entitlements/history and 243 cards unchanged.
11. RU/UZ/EN and 320/390/desktop; no UI internal accounting terms; keyboard/safe-area.
12. Separate provider budget exhaustion leaves valid prepared routes working; no provider call for blocked routes.
13. Auto-open only when full QA and authorized cohort; rollback capability per route and global kill switch.

## 8. Release and protection gates

- **Absolutely no main or production deployment**, migrations, new live accounts, writes to Supabase/localStorage, hidden student quota activation, subject access cutover, or payments until a separate explicitly approved release step.
- Рабочая AI-ветка `qa/iclub-ai-layer-v21-20261012` остаётся источником технического Master Plan и тестов. Для визуальной проверки **разрешено переиспользовать существующий защищённый Preview** `qa/fix-exam-prep-subject-isolation-20261011`. Коммит/деплой Preview не разрешает писать в production Supabase, менять права и задания, создавать тестовых учеников или включать платную AI-генерацию. Проверять защиту Vercel и маршруты до запуска каждого теста.
- No real provider requests in initial Preview; synthetic test fixtures only. **Не считать повторную регистрацию в Preview изоляцией базы** — Auth может создавать реальные записи, поэтому AI QA без новой регистрации.
- For new code never edit legacy lesson/Practice/Tours question IDs/history in place. Preserve all P1/P5 45+36 learning contracts.
- Do not delete old Tutor versions; preserve rollback.
- Final plan weights/allowances/price policy after tests + architect approval. More recent user instructions override conflicting earlier working-doc weights/exhaustion.
- Implementation evidence, test cases, hashes and GO/NO-GO are documented in this branch.

## 9. Referenced project implementation docs

`docs/ai-rollout-working-canon.md`, `docs/exam-prep-ai-curated-tutor-content-plan-v1.md`, `docs/exam-prep-tutor-content-v3-audit-repair.md`, `docs/global-ai-tariffs-v1-implementation-plan.md`, `docs/iclub-global-ai-controlled-canary-readiness-v1.md`, `docs/iclub-global-ai-generation-canary-v1.md`. The October 6 tariffs doc remains a historical **previous decision**, overridden here *only* for Preview weight (5→3) and route-specific shortfall. Project architecture documents 01/03/04/05/06/07/08/09 remain governing academic/safety sources.

**P0 implementation state:** QA branch created; the written baseline, mock UI и синтетический учёт уже реализованы. 2026-10-12 architect approved reuse of the existing protected Vercel Preview, even if its current app is linked to production Supabase, with **zero new AI writes to real DB and no test registrations**. Cloud test DB isn't required for UI QA; later SQL mutation tests may run only in temporary isolated local Postgres. This plan does not enable any AI function.

## 10. Preview infrastructure decision — 2026-10-12

- Владелец разрешил использовать уже действующий Vercel Preview из ветки `qa/fix-exam-prep-subject-isolation-20261011` для UI-разработки AI Layer независимо от того, подключён ли сам Preview к production Supabase. **Создание отдельного облачного проекта Supabase не требуется.**
- Тот факт, что пользовательский код Preview использует существующий Supabase, **не даёт разрешения на записи AI-функций** в рабочую БД. Для проверки счётчика, списания, генерации, диалогов и feature gates: только in-memory mock, безопасные локальные фикстуры или отдельно запущенная локальная БД, не связанная с production.
- До выполнения любого нового AI API-вызова подтверждаем, что он не пишет в auth, прогресс, AI usage, payment, рейтинг, сертификаты и историю. Server-side feature gates и database RLS сохраняются.
- Нельзя делать вывод, что Preview использует другую БД из-за повторной регистрации. Не создавать новых пользователей для QA AI; использовать существующую тестовую сессию для чтения только при явном понимании доступа.
- Проходить стандартные учебные сценарии допустимо как визуальный аудит, но **не отправлять реальные учебные ответы / оценочные попытки** под настоящей учетной записью при тестировании новых AI-функций. Все AI-тестовые ответы — искусственные.
- Если у функции появляется потребность проверить настоящую запись в БД, подготовить отдельный изолированный локальный тест, а не экспериментировать с рабочими таблицами.
- Состояние Preview/production проверить после каждого коммита; `main`/production/Supabase untouched.

## 11. Implementation checkpoint — 2026-10-12 (no Vercel deploy)

Owner instruction: **не расходовать Vercel deploy/build quota на каждый микрошаг**. Проводить локальные/репозиторные тесты и собирать полноценный пакет, а затем сделать один осознанный, защищённый Preview на уже существующей QA-среде. До этого не вызывать создание новых Vercel deployment.

### Completed on `qa/iclub-ai-layer-v21-20261012` (QA only)

- `qa/ai-layer-v21-preview-gateway.cjs` — полноценная автономная **учебная имитация контрактов** P2/P7: точная маршрутизация по surface×subject×feature×topic×locale, утверждённые источники и права, защита экзамена/Practice/Tour archive, готовая карточка 1 доля / mock generation 3 доли, Free/Plus/Pro test budget, резервирование/подтверждение/возврат, пять часов, дедупликация ID, запрет перерасхода, отдельный провайдерный бюджет, восстановление лимита после ошибки. **Ни Supabase, ни реальный провайдер не вызываются.**
- `qa/ai-layer-v21-preview-gateway.test.cjs` — **20/20** прошли при проверке сохранённого в GitHub кода изолированным JavaScript test runner; дополнительная локальная расширенная матрица **25/25**. Это не PostgreSQL / браузерное / production QA.
- `global-ai-ui.js` + `global-ai-ui.css` (только QA-ветка): требование **33B** — скрыть плавающий знак на активных защищённых оцениваниях, не просто приглушать. Добавлены нормальные сообщения RU/UZ/EN.
- `global-ai-ui.js` (только QA-ветка): отдельная реакция на `route_insufficient` без установки общего `usageExhausted`; дешёвые ответы остаются доступными. **Существующий v1 `usage_exhausted` временно не менялся** до окончательной серверной интеграции.
- `qa/ai-layer-v21-interface-guard.test.cjs`: семь автономных сценариев охраны интерфейса; дополнительные 10 прямых проверок извлечённого кода завершились GREEN.

### Explicitly not completed / remaining NO-GO

- Не подключены ни production Supabase, ни оплачиваемый провайдер. Эталонная клиентская/серверная идентификация ещё не интегрирована в новый router; mock `context/user` для QA — искусственный. **Запрещено использовать mock как доверенный production API.**
- Нет изолированной PostgreSQL-интеграции с реальными RPC и схемой; v1 SQL по-прежнему имеет generation weight 5 и старую блокировку всего периода. Исправления SQL только будущим новым обратимым миграционным шагом, старые миграции не переписывать.
- Автоматическое определение языка вопроса и его верификация по одобренным источникам, semantics-ready per-topic registry, actual provider output/source review — отдельные задачи.
- Отсутствует браузерная проверка нового UI на 320/390/desktop. Периодические автоматические Vercel-сборки из этой ветки не инициированы.
- Mathematics Exam Prep не перенесён под новую квоту и не изменён. Practice и Tour AI не активированы. Нет rollout или платы.

**Release gate:** продолжать staging/test work на QA-ветке; **не выкатывать Preview, пока не собран полноценный пакет** и владелец не дал разрешение на конкретный расход Vercel. Старый исправленный Preview использовать как рабочий ориентир, без AI-записей в общую базу.

## 12. Technical checkpoint — 2026-10-12: authoritative mock integration and unexecuted SQL v2

**All work is on QA branch only. No Vercel builds or changes to main, production, existing subscriptions, user histories or Supabase.**

### Source verification
The original project documents 06 AI Layer Safety Architecture v1.1, 04 Content Governance Model v1.1 and 03 Exam Prep Integration Architecture Audit v1.0 were read directly. They require server-derived academic context, protected exams, governed versioned sources and zero AI authority over learning evidence. The dormant edge code in supabase/functions/global-ai/index.ts currently accepts several UI hints; these must be reverified server-side before actual runtime integration.

### Completed QA-only work
- **Authority gate**: qa/ai-layer-v21-authority-gate.cjs + test (17/17 GREEN). Authentication/ownership mock, approved context, protected assessment, Practice completion, Tour archive opening, response language RU/UZ/EN and fail-closed ambiguity. It is *not* yet backed by production authentication.
- **Fine-grained readiness**: qa/ai-layer-v21-readiness-registry.cjs + test (12/12 GREEN). Per surface, subject, function, topic and locale; eight quality/safety gates; owner-approved cohort for beta; feature-specific/global emergency stops.
- **Shared quota pipeline**: qa/ai-layer-v21-synthetic-pipeline.cjs + test (13/13 GREEN). Checked Math+Economics both consume the same user's temporary 1:3 quota. Client-provided academic identity is ignored; provider spend approval comes from server services, not a request flag.
- **Existing mock gateway**: qa/ai-layer-v21-preview-gateway.cjs + test (20/20 GREEN). No real source retrieval/provider/DB calls.
- **SQL v2 draft ONLY**: qa/sql_drafts/iclub_ai_v21_meter_v2_UNAPPLIED.sql. New QA policy names, new versioned RPCs, request identity fingerprint, and route-specific shortfall without blanket exhaustion. Eight source-only contract checks (8/8 GREEN). **Not a real PostgreSQL run**, and NOT in the automatically applied migration folder.
- **Frontend work**: QA global-ai-ui.js and .css updates keep icon fully hidden during protected assessment and respond to route_insufficient without closing cheaper routes. Seven formal interface tests saved. Targeted extracted-source checks previously GREEN.
- **Offline runner**: node qa/run-ai-layer-v21-offline.cjs; six node:test files plus original synthetic smoke script; zero Vercel calls. Complete native Node runner remains to be executed in a checked-out source environment.

### Open implementation barriers (NO-GO for beta)
1. New SQL v2 needs disposable local PostgreSQL integration tests for concurrency, period expiry, replay identity, RLS and ownership. Do not execute draft against production Supabase.
2. Client timeouts with already-completed request IDs currently fail closed in draft SQL; to return the original answer without a second provider call, design a bounded, session-compatible ephemeral response receipt. Until then do not claim end-to-end idempotent delivery.
3. Current real Global AI Edge still calls v1 RPC, default client locale and existing subject/scope guard. A new adapter must derive actual topic/locale from authoritative server state, prevent spoofing, and re-check protected assessment immediately before provider invocation.
4. Provider budget/price caps and tariff values remain provisional. No real paid model calls. Existing Mathematics Exam Prep Tutor stays exactly as it is.
5. Need browser/e2e UI and safety regression on 320/390/desktop and all languages, with no real new AI writes to the existing Supabase.
6. Owner requested conserving Vercel quota: accumulate a full coherent package and run one protected Preview only when necessary.

**Scope statement:** The independent tests are offline behavioural/source contracts over GitHub code, NOT proof of real SQL/RLS or an approved production feature.


## 13. Continued offline build checkpoint — 2026-10-12

No Vercel builds/deployments were requested or created. Existing production, Supabase, Math Tutor and learner history have not been changed.

- Read-only source check of the latest Global AI SQL guard confirms active-assessment checks exist; future all-subject rollout still requires server-owned topic/screen/locale and a second protected-assessment guard immediately before model invocation and final response.
- QA-only router, authority, readiness and cross-subject integrated tests extended to catch **TOCTOU**: assessment starts after admission, protected content/source version is revoked mid-request, AI feature is emergency-disabled while processing, or a previously completed reply is replayed during a protected assessment.
- 80/80 independently executed saved-source behavioral and SQL **static** cases GREEN: Gateway 26, Authority 17, Readiness 12, Cross-subject 17, SQL draft static 8. Separate initial smoke and UI tests are not included in that total.
- The only SQL v2 remains an **unapplied draft** under `qa/sql_drafts/`, never in `supabase/migrations`; no trusted live edge function references it.
- Native PostgreSQL not installed in available sandbox, and offline package installation timed out; **real SQL execution, RLS and concurrency remain untested**. Do not release until local PostgreSQL test suite is truly run.
- Full server integration still requires auth-bound context minting, source rights/hash binding, request receipt replay with bounded retention and nonpersistent raw conversation, budget controls, protected-assessment guard inside a race-safe boundary and real response validation.

Next: package the v2 SQL tests for a local PostgreSQL runtime once available, refine verified Math P1/P5 adapter and in-browser AI interface. Do not pay Vercel build quota for microsteps. Preview only when the entire protected test candidate is ready and owner approves.

## 14. P4 Mathematics Exam Prep protection — baseline freeze (2026-10-12)

**Owner requirement:** never break the existing Math Exam Prep while adding Global AI. No silent quota cutover, no progress migration, no replacing existing AI Tutor routes.

### Five byte-identical protected production files
The following GitHub blob SHA-1 hashes were verified read-only on both production commit `9afc7b44aead03b2a30544e6e7d4c4eb8670efbf` and QA branch `qa/iclub-ai-layer-v21-20261012`:
- `exam-prep/exam-prep-live.js`: `4827d5d0aa101cabe88395403769c89017e892a9`
- `exam-prep/exam-prep-ai-ui.js`: `23feb4322840c94eea32c85f07891e78855bf0d3`
- `exam-prep/exam-prep.css`: `264d31a33ba34b926acd88265995e4b5fa5e8ae7`
- `supabase/functions/exam-prep-ai/index.ts`: `7484bc1ec4dae842c559e3c63c4b84935e5cf312`
- `scripts/exam-prep-subject-isolation-regression.cjs`: `8cd7b5aad83b6e7a52c28b1e5f8090a76a5f1514`

**Source of truth:** `qa/ai-layer-v21-math-frozen-baseline.json`. Any unapproved change must fail the baseline test, not automatically update its hashes. Reset the baseline only following an explicit architect decision AND proven equivalent Exam Prep UX/QA.

**Original Math Tutor behavior retained:** dedicated `exam-prep-ai` endpoint; P1/P5 component isolation; 5-step thread limit; two generated followups; prepared modes `main`, `simplify`, `rephrase`, `focus` from approved Math Tutor v3 cards; a student's original `question` follows legacy source-backed generation rules, not a fabricated prepared-card match. The source subject-isolation regression checks Economics, Informatics, Biology, Chemistry, English A1 and SAT do not query or open Math P1/P5.

**New QA-only read-only bridge:** `qa/ai-layer-v21-math-tutor-bridge.cjs` and `.test.cjs` (13/13 passed on committed source through V8 tests). Legacy Tutor entrypoint is **untouched, not routed through this module and charged 0 NEW unified quota units**. In future unified AI ONLY, an exact verified P1/P5 Tutor card and variant is admitted as `prepared=1` TEMPORARY unit, only after authoritative source-key/version/locale and exam safety checks. Unstructured questions remain separate generated routing; no implicit model call and no academic mutation in bridge.

**New pinned-compatibility suite:** `qa/ai-layer-v21-math-frozen-parity.test.cjs`, nine scenarios passed in V8 source-level testing; GitHub-verified SHA matches for all five files. The runner `qa/run-ai-layer-v21-offline.cjs` now invokes the existing subject-isolation Node regression as well as AI tests. Its full native Node execution remains a separate gate, not claimed here.

**Read-only Supabase recheck at 2026-10-12:** Exam Prep `core_enabled=true`, `ai_enabled=true`, `mentor_enabled=false`, `rollout_state=controlled_beta`; **3** `ai_assist=true` entitlements; Math v3 Tutor content **81 per en/ru/uz = 243** cards. New Global AI UI/gateway/generation/checkout are all disabled, `kill_switch=true`. Only SELECT queries were performed, without learner identity or answer retrieval.

**P4 release gate:** New Global AI may open in Math only after complete parity checks (P1 45 + P5 36, three languages, both types of Tutor responses, permissions, protected assessments, no regression in legacy usage) and explicit owner approval for changeover. Existing Math Tutor stays functional even if ALL NEW Global AI features are emergency disabled. No Vercel deployment in this iteration.



## 15. Math RPC and retry checkpoint — 2026-10-12

Scope: QA-only additive modules, no active Global AI integration.

- `qa/ai-layer-v21-reply-receipts.cjs`: 13/13 offline tests passed. Two-minute session-specific response cache, gated by fresh server authorization before replay.
- `qa/ai-layer-v21-request-delivery.cjs`: 13/13 offline tests passed. Completed requests cannot repeat generation when the response is lost, expired or a cache is unavailable.
- `qa/ai-layer-v21-math-source-rpc-bridge.cjs`: 18/18 offline tests passed. Uses the existing approved Math Tutor card and source RPC contract, requires a server-issued `routeAuthority=unified_ai` and refuses legacy Exam Prep entrypoints. Cross-subject, locale, exam and stale-content refusals tested.
- 44/44 new offline cases passed against the saved GitHub source in an isolated JS runner. No native database verification claimed.
- The local runner now includes these tests. Running `node qa/run-ai-layer-v21-offline.cjs` from a fully checked-out repository remains a separate validation gate.

Critical limitations: in-memory receipts are not sufficient across production Edge restarts; server-owned DB request idempotency and short-lived replay need review. The existing Math Tutor continues through its old endpoint and is not subject to the new mixed quota. Local PostgreSQL, native Node suite, browser regression and separate release authorization remain pending.

Zero additional Vercel deployments; no production or Supabase changes.

## 16. Offline SQL QA preparation — 2026-10-12

Added scratch-only PostgreSQL regression script and its local runner under qa/. They have not been executed because PostgreSQL is unavailable here. The static source checks pass 11/11. The QA-only request-delivery handler now limits memory usage and refuses new paid work before exceeding safe capacity; its 16/16 tests pass. The real Exam Prep is unchanged. No deployment or database write was performed. SQL, browser and distributed Edge verification remain pending.

## Checkpoint 17 — SQL v2 completion identity and expiry

2026-10-12, QA branch only. Progress by Master Plan: P0 baseline complete; P1 static UI prepared but no new Preview deployment; P2 authoritative mock contracts complete, real Edge integration pending; P3 UI partial; P4 legacy Mathematics Tutor frozen with five verified hashes, read-only Math adapter prepared; P5/P6 routing contracts only; P7 temporary 1:3 metering plus unapplied v2 SQL draft, actual PostgreSQL tests pending; P8 full acceptance not run; P9 owner-controlled beta not started.

Critical safety fix in qa/sql_drafts/iclub_ai_v21_meter_v2_UNAPPLIED.sql: v2 finalization now validates the exact request owner and SHA-256 fingerprint under the same per-user advisory transaction lock, denies completion after reservation TTL, and releases an expired hold through the unchanged v1 accounting helper. This avoids charging a learner for an already expired response. The entire v2 draft has an additional database-name/localhost guard, so it refuses direct execution on the production database.

Updated qa/sql_drafts/iclub_ai_v21_local_pg_regression.psql adds owner/fingerprint mismatch, late finalization, and a five-hour period rollover case. Its actual PostgreSQL execution has NOT happened; database binaries are unavailable here. Static SQL source checks: 16/16 GREEN.

Aggregate committed-source V8 QA runner: 173/173 checks across twelve test files (six suites 104, six suites 69). This is NOT a native Node, PostgreSQL, browser, integration or production success claim. The existing Mathematics Exam Prep files and live data are untouched; no Vercel deployment was initiated.

Remaining release gates: real scratch PostgreSQL/transaction and multi-session concurrency testing; server-minted learner/subject/assessment context and runtime Edge adapter; persistent minimal idempotency across Edge restarts; economics of tentative 1:3 billing; native Node full-suite execution; full mobile RU/UZ/EN and Math 81-skill parity; isolated Preview and explicit owner approval.

## 18. Existing production schema authority mapping — 2026-10-12

QA progress: P2/P5 now has a **read-only, production-schema-grounded server context resolver** in `qa/ai-layer-v21-server-context-existing-db.cjs`. It was built after READ-ONLY Supabase metadata/constraint checks: `private.exam_prep_sessions` (`status='finalized'`, `finalized_at`), `public.practice_sessions_v4` (`status='finalized'`, `finalized_at`), and Tour `public.tour_attempts` (`status in ('submitted','time_expired')`) joined to separately-finalized `public.tour_session_runtime_v4` and archive access. Importantly, Tour attempts have **no `finalized_at` column**. User, attempt, subject, active assessment and archive unlock are server-side evidence, not trustworthy browser claims.

Added `qa/ai-layer-v21-server-context-existing-db.test.cjs`: **21/21** standalone committed-source test scenarios PASS; real schema and implementation explained in `docs/iclub-ai-layer-existing-db-context-map-v2.1.md`. Rechecks catch subject access revoked during lookup, protected exam beginning mid-request and Tour runtime/permission changes. It exposes **only eligibility metadata** with `topic:null` and `sourceReady:false`; it cannot fetch model evidence or charge quota until the separate approved source-readiness layer passes.

The consolidated offline runner now includes this as its **13th** Node test suite. We have not yet run the full native Node suite in a checked-out repository: GitHub source access is available via connected tools but direct container git clone is blocked by DNS; actual local PostgreSQL binaries are also unavailable. Do not call this browser/Edge/PostgreSQL validation. No new Vercel builds or production/Supabase writes. The old Mathematics Exam Prep remains frozen and independent.

**Next implementation gate:** authenticated Edge service adapter reading these actual tables/RPCs without user-provided subject authority; exact P1/P5 skill evidence and source version binding; local PostgreSQL idempotency/concurrency; controlled single Preview and comprehensive beta tests only after release permission.


## 19. Unified vertical-slice QA integration — 2026-10-12

**One coherent milestone, not deployment:** joined verified existing-data context, precise source-evidence binding, per-screen/topic/locale release gates, temporary globally shared 1:3 metering, short-lived reply receipts, concurrent reservation admission, and mid-request safety rechecks. Files `qa/ai-layer-v21-unified-vertical-slice.cjs` and `qa/ai-layer-v21-unified-vertical-slice.test.cjs` are **QA-only and not imported by application or deployed Edge**.

- **26/26** standalone end-to-end synthetic scenarios GREEN on exact stored GitHub source, using V8 Node-core stubs. Included: finalized Math P1, finalized Practice Economics, server-unlocked Tour archive, active/unfinished assessment denies, unknown source/language denies, cross-subject source isolation, browser-flag spoofing, 2 remaining allows 2 prepared but rejects generated3, Free generation restriction, provider monetary budget, concurrent 4-generated requests at Plus9 (3 allowed, 4th denied), source revoked mid-provider, provider failure/output validation refund, same request ID same session replay without extra charge, stranger access denied. These are **not** native Node/Edge/PostgreSQL/browser results.
- This gate intentionally refuses to treat a finalized session as proof of a specific skill. `getTopicEvidence` and `getReviewedSource` are mocked **trusted-server-only** dependencies; real production mappings to owner-bound academic evidence and verified current source rows remain unimplemented. Academic statuses, price, topic and rights from browser payload are ignored.
- Mathematics governed source test uses metadata of 243 historical approved Tutor cards to guard P1/P5 key×locale, but the snapshot alone cannot authorize production replies; actual current approved source, entitlement, content version and rights must be verified server-side.
- Mock provider must never be mistaken for a generative model. All fake answers and quotas remain isolated from real learner data. New Global AI does not import or call working `exam-prep-ai`; legacy Tutor remains unchanged and outside new quota.
- `qa/run-ai-layer-v21-offline.cjs` includes the new 14th test suite. The attempted combined source-code test orchestration exceeded the connector tool-call limit; **full 14-suite native or V8 re-run NOT claimed**. Earlier suites were individually checked during prior milestones.
- PostgreSQL local real execution, Edge auth-bound source retrieval and race-safe persistent idempotency, browser UI parity, provider cost budget and owner-approved beta remain **NO-GO**. No Vercel builds, production changes, or Supabase writes.

**Next meaningful delivery gate:** build a read-only service adapter against authoritative session/evidence/source RPC and validate with actual local Node+Postgres, then package one protected Preview candidate. Do not begin student rollout or switch old Exam Prep routing until parity is proved and explicitly approved.


## 20. Server-only Math source admission — P2/P4 integration checkpoint (2026-10-12)

**Major deliverable:** first new Mathematics P1/P5 SQL admission proof tied to the **actual deployed database schema** and entirely isolated from active Exam Prep. This is a **scratch-guarded, unapplied SQL draft**, not a production migration. The code only authorizes *retrieval* of approved source metadata, never changes learner progress.

- Real schema verified by read-only SELECT metadata + aggregate queries: `exam_prep_sessions` + `exam_prep_session_items` + `exam_prep_evidence_events` + Tutor v3 cards + versioned rights-cleared source cards. Importantly, finalized session alone is not enough: session membership of the skill and matching `app_verified` evidence are both required.
- `qa/sql_drafts/iclub_ai_math_skill_context_v21_UNAPPLIED.sql` creates service-role-only `get_iclub_ai_math_skill_context_service_v2`, verifying correct learner/session/P1–P5/skill/language, current global-ai kill switch, existing protected-assessment guard, approved `tutor_v3_learner_first` card and `original_iclub` rights. It returns source hashes and binding metadata, **no answer text**. It cannot run on a non-scratch or remote database.
- `qa/ai-layer-v21-math-authority-service.cjs` is a future server-only contract requiring a verified bearer, a short-lived revision-bound session context and revalidation before response delivery. **19/19** tests PASS against committed GitHub JavaScript source in V8.
- `qa/ai-layer-v21-math-authority-sql.test.cjs`: **14/14** static checks PASS for SQL authorization, source/rights/evidence gating and scratch test security.
- `qa/sql_drafts/iclub_ai_math_authority_local_pg.psql`: local PostgreSQL fixture covers gateway-disabled, foreign user, wrong skill, incomplete exam, unverified evidence, retired Tutor, rights blocked and protected assessment. All synthetic fixtures enclosed in a transaction that rolls back; this fixture is **PREPARED, NOT RUN** because PostgreSQL is still unavailable here.
- `qa/run-ai-layer-v21-postgres-local.sh` now chooses `meter` or `math`, ONLY on a new empty localhost scratch database. The consolidated Node runner now contains **16 suites**, but native full Node run remains not completed. See `docs/iclub-ai-layer-math-authority-handoff-v2.1.md` for exact handoff.

**Safety/rollback rule:** SQL draft is under `qa/sql_drafts` rather than `supabase/migrations`; no active Global AI Edge function or original Math `exam-prep-ai` imports it. Student beta permissions, completed assessments, Practice/Tours, Tutor texts and local progress are unchanged. No Vercel builds. No student rollout. Existing P1/P5 learning works even with new Global AI entirely disabled.

**Remaining GO gates:** actual local PostgreSQL compile/execution and concurrency; integration of the service-only SQL RPC into a *new* authenticated Edge pathway with entitlement/release checks and source-hash parity; actual per-topic and per-locale source QA; real provider cost budget and double-charge-safe idempotency across Edge instances; protected Preview/browser test and explicit architect approval. Current 1:3 rates are temporary.


## 21. P5–P6 multi-subject delivery checkpoint — 2026-10-12

**Scope:** User-directed app-wide AI Layer, **not only Mathematics**. This single QA milestone covers the active Mathematics, Biology, Chemistry, Economics and Informatics courses, inactive English A1/A2/B1/SAT/IELTS, Practice, Tours, General Help, Home, Profile, Lessons and future Videos. No live feature was enabled.

**Verified read-only Supabase snapshot:**
- Existing subject registry: five active core subjects (Biology, Chemistry, Mathematics, Informatics, Economics). English A1/A2/B1, SAT and IELTS exist but are currently inactive.
- Existing global AI readiness: Mathematics Exam Prep full/adapter Math v1; global Mathematics/Biology/Chemistry/Economics/Informatics only basic with no academic adapter; general help basic with app_help_v1. New Global AI UI/gateway/generation all OFF and kill switch ON.
- Practice source cards approved/runtime/rights original: **Economics 81 per locale** (80 answer_explanation + 1 result_context; **4 exact question IDs**, 76 topic-only answer cards); **Chemistry 38 per locale** (33 exact IDs, 5 topic-only). All three RU/UZ/EN locales have these counts. **357 approved cards = 111 exact-question rows + 246 generic/topic/result rows across locales**. The count measures published rows, **not** substantive editorial QA completion or readiness for the new AI. No overlapping currently approved source records for an exact question+locale were found at the time of audit.
- Practice completion evidence: `public.practice_sessions_v4` (owner, subject, finalized status, finalized_at, question_ids) and `public.practice_session_answers_v4` (session_id, question_id). A topic-only source with `question_id=NULL` **must never** substitute for a specific answered-question explanation. Protected Tours still require independently opened archive and approved source.

**New QA artifacts:**
1. `qa/ai-layer-v21-subject-readiness-inventory.snapshot.json`: aggregated metadata only; every subject/feature marked not released for NEW AI.
2. `qa/ai-layer-v21-cross-subject-admission.cjs` and `.test.cjs`: an authenticated, read-only, fail-closed multi-subject gate for Practice and archive Tours. It requires actual completed resource, owner, subject, exact topic/question evidence, current rights-cleared and versioned source, RU/UZ/EN, independent eight QA gates, cohort, protected-exam guard and rechecks after async work. It never charges, generates or mutates student data. **26/26** isolated committed-source JS cases GREEN (not native Node).
3. `qa/sql_drafts/iclub_ai_practice_exact_source_v21_UNAPPLIED.sql`: scratch-only service_role RPC for a **finalized, answered, EXACT question** in Economics/Chemistry. Rejects unknown/foreign/unfinished question, wrong subject/locale, source with denied rights, ambiguous approved versions and global AI disabled. No generic card fallback, no answer text and no academic writes. **Unapplied, not in Supabase migrations.**
4. `qa/sql_drafts/iclub_ai_practice_exact_source_local_pg.psql`: rollback-only synthetic SQL fixtures for both subjects, protected assessment and all negative cases. **PREPARED, NOT RUN in PostgreSQL**.
5. `qa/ai-layer-v21-cross-subject-sql.test.cjs`: **14/14** static SQL and policy checks GREEN. Local scratch runner now allowlists meter/math/practice.
6. `docs/iclub-ai-layer-p5-p6-multisubject-readiness-v2.1.md`: actual readiness/coverage, prioritization and content/editorial NO-GO rules.

The consolidated `qa/run-ai-layer-v21-offline.cjs` now lists **18** test suites; full native Node/PostgreSQL/Edge/browser acceptance is NOT claimed. **40/40 newly introduced P5/P6 tests** passed by executing the exact GitHub sources in an isolated JS/V8 test harness.

**Product-level decisions preserved:**
- Mathematics Exam Prep P1/P5 continues on legacy endpoint and quotas with no changes.
- Practice errors are explained only after the full session and only for the same exact question with verified approved source. Economics/Chemistry topic-level sources require a different governed explanation feature; cannot masquerade as exact errors.
- Biology/Informatics future topics open only after source mapping, rights, correctness, all eight gates, cohort/locale. English/SAT/IELTS remain inactive; no AI merely because the app supports English UI.
- Tours have zero new archival AI answers until server-unlocked archive and exact source approval. General Help is a separate verified fallback only if itself ready; Home/Profile require signed minimal progress/next-action data. Video without approved transcript stays blocked.

**Release blockers:** real isolated PostgreSQL and concurrency test; trustworthy production-backed per-topic mapping and source QA; stable server-owned context/auth and idempotency across Edge workers; economics of temporary 1:3; native Node and mobile/browser RU/UZ/EN regression; one protected synthetic Preview at justified time; explicit architect beta approval. No direct production writes or Vercel builds in this checkpoint.


**P5/P6 follow-up QA refinement:** 2026-10-12 — frozen audit subject statuses were removed as runtime authority: live server `subjects.is_active` plus source/QA gates controls future releases (Master decisions 38C and 42A). Inactive current courses remain blocked. One further regression verified future subject activation cannot bypass missing approved content. New P5/P6 tests now **40/40** in isolated committed-source execution; no production rollout.


## 22. Editorial content produced separately — AI technical publication interface (2026-10-13)

**Architect clarification (binding):** THIS chat implements **only** the technical iClub AI Layer. Cards, academic questions, theory, explanations and substantive editorial content are made and approved in **another chat/workstream**. AI engineering must NOT author dummy academic cards or repurpose generic topic content as exact question answers. Its duty is a safe, universal receiver for independently published content.

**Expected behavior after approved release:** The technical system reads server-owned canonical subject / screen / function / topic / locale, verifies current editorial publication + source version/hash/rights + all eight QA gates + release authorization for this learner/cohort + protected-assessment guard. A newly published topic becomes available automatically in an **already owner-approved rollout** without changing app code or rebuilding Vercel for that topic. Revoking publication, source rights, locale approval or source hash closes that single path. New subject content alone does not approve public/beta rollout.

**Expected behavior when unready:** Child sees an attractive, proofread RU/UZ/EN title (**«В разработке»** / **«Ishlab chiqilmoqda»** / **“In development”**) and one concise explanation. General iClub help is suggested only if **it independently passes live readiness and permissions**. Do NOT charge quota, call a provider or invent an explanation. Protected active assessment hides the AI surface completely; system-wide AI OFF has a separate temporary-unavailable state. No internal terms (“units”, “лесенка”, provider, SQL, routes) in learner-facing text.

**Completed QA technical deliverable (not deployed):**
- `qa/sql_drafts/iclub_ai_topic_release_gate_v21_UNAPPLIED.sql`: scratch-only private server-governed publication metadata table and service_role SELECT RPC keyed by **surface × subject × feature × topic × locale**, source version/hash and publication revision, all eight editorial/technical gates default FALSE, default draft and disabled. No content/questions or academic writes.
- `qa/ai-layer-v21-content-handoff-gate.cjs`: server-only dynamic live availability adapter with JWT-bound scoped context contract, trusted server clock, current feature/source/rollout, two-phase revocation checking and proofread three-language unavailable responses. General Help offered only after own source gates.
- `qa/ai-layer-v21-content-handoff-gate.test.cjs`: **32/32** synthetic behavior tests passed. `qa/ai-layer-v21-content-handoff-sql.test.cjs`: **13/13** static SQL tests passed. Combined **45/45** against GitHub source in isolated JS/V8. **NOT** real PostgreSQL or native Node/Edge/browser signoff.
- `qa/sql_drafts/iclub_ai_topic_release_local_pg.psql`: rollback-only synthetic local publication lifecycle fixture; NOT EXECUTED. Scratch runner allowlists `ICLUB_PGTEST_SUITE=release`. Offline runner now registers **20** separate suites.
- Complete source/publisher contract in `docs/iclub-ai-layer-content-technical-handoff-v2.1.md`.

**Still NO-GO before live users:** actual local PostgreSQL execution, authenticated server adapter to new publication RPC, verified source proof for each specific domain/screen and independent owner/cohort release, security/limits under concurrent Edge instances, UI wiring and mobile RU/UZ/EN Preview, broad academic regression and explicit owner approval. A published content card/row **by itself** does not activate a beta; the approved publication workflow is not yet implemented or deployed. Keep working Mathematics Exam Prep entirely separate.

**Production / Vercel / Supabase effect of this milestone:** none; QA branch only.


## 23. Native Node + PostgreSQL QA gate (2026-10-13)

**Milestone:** A new, dedicated **QA-branch-only** GitHub Actions workflow `.github/workflows/iclub-ai-v21-offline-qa.yml` runs with read-only repository permissions, no application secrets, no production Supabase connection and no Vercel deployment. The completed [verified run](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38346873724) is **SUCCESS**, Git commit `ec955ee8528bb23acf127f35a5c2be1db23d01d2`.

**Actual native runtime gates, not simulated:**
- Native Node 22: **338/338 tests PASS**, plus **8/8** synthetic metering smoke checks. Subject isolation across six non-Math subjects, existing Math beta and six late-response races PASS.
- Actual ephemeral PostgreSQL 16: **4/4** scratch-only suites PASS (`meter`, `math`, `practice`, `release`). Test DBs are uniquely named `iclub_ai_v21_scratch_ci_*`, empty before use and dropped after the test. Cross-subject catalog checks, 1:3 plus cheap remainder, one-request idempotence, expired reservation release, 5h period rollover, session/evidence/approved source, generic-vs-exact Practice, owner/rights, per-topic/per-locale publication and revocation are exercised.
- No application user data used, no real Supabase DML/DDL, no academic state mutation. CI verified original `exam-prep/`, `supabase/functions/exam-prep-ai/`, `supabase/migrations/`, `index.html`, `app.js` untouched versus production SHA `9afc7b44aead03b2a30544e6e7d4c4eb8670efbf`.
- The local empty-Postgres checks were upgraded to permit **tagged local Docker bridge IP** while still refusing untagged/private remote hosts and non-scratch DB names. Test-only SQL remains under `qa/sql_drafts/` and is **UNAPPLIED**.
- P3 global AI QA UI now translates any source-unready denial into a user-friendly **«В разработке» / «Ishlab chiqilmoqda» / “In development”** notice, with no quota exhaustion. Added two interface source tests; this final UI change followed the successful run, so the latest snapshot needs one final native CI verification.

**Do not overstate this gate:** actual deployed authenticated Edge route, automatic editor-to-publisher workflow, cross-Edge-instance request idempotency, provider budget integration and mobile/browser end-to-end Preview remain **NOT DONE**. The working legacy Exam Prep is not migrated. Content/questions/cards are produced elsewhere; this thread delivers only the technical contract. No student rollout/paid plan changes approved.

See `docs/iclub-ai-layer-native-qa-checkpoint-2026-10-13.md` for the exact run and limitations.


## 24. Final green native QA — 2026-10-13

**Verified authoritative run for latest tested QA snapshot:** [GitHub Actions 38347173145](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38347173145), SHA `e514cde3f72141cc9a89874410c64754dc1a0605`, **SUCCESS**.

- Native Node.js 22: **340/340** tests PASS, including P3 ready/unready RU/UZ/EN UI, older Math compatibility, full cross-subject gates, payment-safe retry, 1:3 synthetic model routing and all previous safety contracts.
- Additional synthetic tariff smoke tests: **8/8 PASS**. Legacy Math Exam Prep isolation and late-response regression: PASS.
- Native PostgreSQL 16 disposable QA service: **4/4 full scratch SQL suites PASS**, actual compile/execution and transaction assertions for meter, Math authority, Practice exact sources and per-topic publication. Uses no real Supabase/learner rows; synthetic DB dropped after test.
- Protected Exam Prep backend and frontend files, deployed migration directory and app entrypoints: baseline diff check PASS. No production/main or Vercel deployment.
- **P3**: QA Global AI UI maps missing unpublished source/subject to friendly localized **«В разработке»** notice, distinct from true usage exhaustion; server-only technical publication interface remains under review and unconnected to production.
- The automated workflow triggers by an intentional QA workflow-file change only (not on each QA file micro-update); all steps run without application secrets or any production API access.

**Honest boundaries:** Green local PostgreSQL is NOT full production RLS, Edge multi-instance concurrency or live provider integration. New AI remains uninstalled in production. Independent content publishing chat remains the sole owner of academic cards/questions. Required before beta: server-minted scoped context, actual service-role publication adapter, live source hash checks, cross-Edge idempotency and atomic reserve/complete, provider cost safeguards, one protected Preview browser QA and explicit owner approval. Existing Mathematics Exam Prep continues independently.

See `docs/iclub-ai-layer-native-qa-checkpoint-2026-10-13.md` for the detailed verification log and limitations.


## 25. P7 cross-worker claim and atomic quota/delivery (2026-10-13)

**Large technical completion:** new **QA-only SQL** `qa/sql_drafts/iclub_ai_delivery_claim_v21_UNAPPLIED.sql` adds durable request tombstones containing only user UUID, request UUID, server-session/request SHA-256 fingerprints, route class and status/TTL (**NO prompts, questions, model replies or academic results**). It binds an authorized request to the existing temporary v2 quota reservation, allows exactly one successful claim across PostgreSQL connections, and rejects completed/released/expired reused IDs without invoking the provider. Service role only; never reroutes existing `exam-prep-ai`.

**Safety fix:** delivery completion is now **one PostgreSQL transaction with v2 metering finalization**; injecting a failure after quota finalization automatically rolls back the learner charge and delivery status together. Prepared and generated routes use the existing temporary 1:3 weights; failed/released delivery commits zero units. Claiming cannot precede the matching reserved quota row. Retention/deletion of durable tombstones is deliberately NOT implemented until replay/retention is formally designed and approved.

**Real execution evidence:** [GitHub Actions #38348691615](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38348691615), SUCCESS. **Native Node.js 22: 352/352** tests PASS across 21 suites; 8/8 synthetic smoke passes and legacy subject-isolation regression GREEN. **Real isolated PostgreSQL 16: six scratch suites PASS** (`meter`, `math`, `practice`, `release`, `claim`, `atomic`). Additional two **concurrent database connections** race for one UUID: exactly one claim and one denial, no double provider permission. Forced transaction failure and rollback across the actual v1+v2 usage functions PASS. Disposable databases deleted; NO production Supabase, Vercel or learner data used.

**Not yet a deployed AI:** this is persistent SQL proof and a technical handoff. Need server-owned JWT context, new Edge integration, approved source publication, privacy-reviewed short-lived reply recovery, actual multi-Edge instance testing, output/provider budget quality checks, mobile/browser Preview and separate owner approval for beta and tariff finalization. A lost HTTP response after successful database completion cannot be recovered from this metadata-only ledger; retry correctly fails closed instead of calling the model again. Avoid claiming perfect network delivery. Content/card production remains in the other chat.

See `docs/iclub-ai-layer-p7-distributed-delivery-handoff-v2.1.md`. Current work stays on QA branch; protected Math production files, migrations, existing progress/localStorage are not changed.


## 26. P2/P3 unified server request candidate and late-revocation hardening (2026-10-13)

**Scope:** New **QA-only** `qa/ai-layer-v21-edge-request.cjs` composes the approved-source/content handoff gate, JWT principal dependency, expiring server-owned context, per-topic/locale availability, server-selected Free/Plus/Pro policy, exact prepared or approved source-backed generated path, monetary budget, SHA-256 source/route/session request identity, P7 atomic usage reservation, durable one-worker delivery claim and atomic settlement/refund. It is NOT imported by deployed `global-ai` or the existing Mathematics `exam-prep-ai`.

**User experience contract:** A missing/unapproved Biology, Chemistry, Economics, Informatics or other lesson topic returns **«В разработке»** (RU), **«Ishlab chiqilmoqda»** (UZ), **“In development”** (EN); no allowance reserved and no model used. A protected assessment hides the AI function. Published content can be picked up automatically in a previously approved cohort without rebuilding the application. Cards, questions and explanations are authored only in the *other* workstream; this technical chat creates no subject materials.

**Technical improvements:** Client is prohibited from providing authoritative subject, skill, plan, entitlement, quota or source identity. The current JWT is revalidated before and after provider use; current plan, monetary budget, published source hash/revision, rights, active exam/screen/cohort are checked again. The content handoff gate revalidates even after its second asynchronous source lookup, denying an exam starting or topic revision changing in that final window. Approved source bundle must carry independently verified integrity and QA readiness rather than rely on source identifiers alone. HTTP response never exposes learner progress, source hash or quota weights.

**Real successful native verification:** [QA run 38350530047](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38350530047), SHA `3daf24e60379c1837f77be53e11a554c811931b0`: **382/382 Node.js 22 tests** PASS across 22 test suites; **8/8** extra synthetic metering smoke; Maths subject isolation and late-response regression PASS. **6/6 real ephemeral PostgreSQL 16 scratch suites** PASS, plus two-connection durable claim race and forced mid-finalization rollback. No Vercel Preview or working Supabase modifications. All original Math Exam Prep files, active migrations and app entrypoints still match protected production baseline.

**What is NOT done:** `qa/ai-layer-v21-edge-request.cjs` is a platform-independent Node/CommonJS candidate with mocked backend dependencies, not a deployed Deno Edge Function. Real Auth SDK/JWT adapters, server context minting, existing schema-compatible protected screen bridge, live editorial publication RPC, exact source content verification and RLS, provider/model integration, durable encrypted reply recovery, Preview UI/device QA and explicit beta approval remain blockers. No live plan/price/rollout can be enabled on the basis of these QA tests alone.

**Handoff:** `docs/iclub-ai-layer-p2-p3-edge-candidate-handoff-v2.1.md` defines backend service APIs, trust boundaries and future Edge deployment safety checks. Continue on QA branch, without changing existing `supabase/functions/global-ai/index.ts` or the original `exam-prep-ai` handler until protected Preview acceptance and architect authorization.


## 27. Deno/Supabase Edge technical bridge with verified fail-closed RPC wiring (2026-10-13)

**Large technical milestone, QA branch only:** implemented `qa/edge_v21/{http.ts,supabase_services.ts,runtime.ts,index.ts}` and three Deno-native regression files. These supply a strict Web Request/Response transport, no-wildcard CORS, 4 KiB body limit, generic no-secret errors, verified learner JWT through Supabase Auth, narrowly scoped service-role RPC mapping, read-only live subject check, source/topic release and user-policy contracts, plus a **Deno 2** bridge to the already-tested Node/CommonJS unified AI request flow. The QA entrypoint is **OFF by default**, explicitly locked behind `ICLUB_AI_V21_EXPLICIT_QA=isolated-preview-only` with a QA-only HTTPS origin. It is **not under active `supabase/functions/`** and cannot alter existing production AI or student progress.

**Critical fail-closed boundary:** Deno `generateSynthetic` intentionally always rejects and can NEVER use the paid provider. Several v21 RPC names are still **proposed interfaces, not deployed functions**: runtime, current protected state, opaque scoped context, rollout, rights-verified source proof and bundle, learner entitlement, monetary provider budget. Absence of any RPC returns denied/unavailable; there is no fallback to old Maths Tutor, client-selected skill, unapproved source or fabricated academic explanation. The scratch-only published-source/meter/claim/finish SQL drafts have **not** been installed in production Supabase. Content/cards/questions remain exclusively the separate editorial workflow; technical readiness becomes available only in an already authorized release after source/rights/cohort checks.

**Real native verification:** [GitHub Actions 38351457995](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38351457995), **SUCCESS** — Node.js 22 **382/382**, Deno 2.9.7 strict typecheck GREEN and **25/25 Deno tests**, PostgreSQL 16 **6/6** local scratch SQL suites, separate concurrent two-worker delivery race + forced atomic rollback GREEN, Mathematics subject-isolation and original protected-file regression PASS. All tests use synthetic data without Supabase/provider credentials and without any Vercel or production deployment.

**Next integration gates:** real DB-backed mint/verify/revoke of opaque session contexts; Auth-bound active-screen and assessment guard; separate content editor-to-publisher read-only proof and source bundle RPCs; live independent rollout/entitlement/provider-budget checks; reversible production-safe SQL migration/RLS review; real Supabase Edge bundler compatibility; controlled protected Preview browser RU/UZ/EN and explicit architect approval. Node/Deno CLI green results **do not** mean the production Supabase Edge function is ready or installed.

**Detailed handoff:** `docs/iclub-ai-layer-deno-edge-qa-bridge-v2.1.md`.


## 28. P2 server-minted temporary screen context for Lessons and Practice (2026-10-13)

**Architect intent preserved:** this chat develops **ONLY the technical AI subsystem**. Academic cards, questions, tutor explanations and editorial publication are completed in a different chat. Until the exact published source for a verified topic, function and language is ready, the unified AI must show localized **«В разработке»** with zero units and no provider calls. Existing Math P1/P5 Exam Prep Tutor is never rerouted.

**Production schema verified READ-ONLY, metadata only:** existing `public.lessons`, `public.subjects`, `public.user_subjects`, `public.practice_sessions_v4` (finalized attempt + question IDs), `public.practice_session_answers_v4`, private protected-assessment guard and global AI OFF flags. This is a factual verified integration basis across all active subjects; no source-card editing or speculative user progress was used.

**New QA-only server contract:**
- `qa/sql_drafts/iclub_ai_scoped_context_v21_UNAPPLIED.sql` creates private, short-lived opaque context handles and **service-role-only** mint/resolve/revoke RPCs. The frontend only selects an existing Lesson ID or a completed Practice session+answered question. The server independently derives the active enrolled subject, canonical Lesson `lesson_<id>` / Practice `question_<id>` topic, feature, owner and 90-second expiry. The source publisher independently decides if the topic/locale is ready.
- One active new-AI screen per learner; minting a different Lesson/Practice makes the previous handle invalid even across tabs. Repeated mint of the same still-current screen reuses the handle; creation limited to 30 distinct handles/minute. Revoke invalidates current handle; foreign/old handles cannot revoke a newer one. Live read rechecks ownership, enrollment, activity, academic completion and protected exam (not just a snapshot).
- Deno preview candidate `qa/edge_v21/{context_core.ts,index.ts,supabase_services.ts}` implements service-token-confined `/context` mint/revoke next to `/answer`. Browser cannot assert a source, subject, topic, quota, plan or academic progress. **No deployed Edge function or production database change**.
- No lesson body, academic answer, prompt, grade, chat transcript, certificate or student progress stored; only owner UUID, resource IDs, revision, timestamps and canonical subject/topic keys.

**Native verification:** [successful GitHub QA run 38353225903](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38353225903), tested commit `9b0e081ae1e5be04146194189841ea29d3990e1a`: **396/396 Node.js** tests, **36/36 Deno** tests with strict TS check, **7/7 actual PostgreSQL 16** synthetic scratch suites, separate two-worker request race and injected billing rollback PASS. Multi-surface scenario proves Biology Lesson/Practice, Economics and Informatics Practice, immediate switch revocation, student subject change, expired handles, protected exam and rate limiting. Existing original Math Exam Prep, active migrations and main app entrypoints unchanged in CI protection check.

**No deployment approval inferred:** the current production UI does not yet call the new mint/revoke endpoints. Abrupt navigation without new mint or revoke leaves an old handle for at most 90 seconds; future UI/Edge routing must explicitly revoke on screen switch and continually validate active context. The local SQL contract has not been migrated and the editorial publisher/source/rights RPCs remain uninstalled. General Help, Tours, Home/Profile require independently verified server authority before granting contexts. Full production-safe RLS/migration, privacy cleanup policy and protected Preview mobile RU/UZ/EN are still required.

**Handoff:** `docs/iclub-ai-layer-p2-scoped-context-practice-lessons-v2.1.md`. Never update academic or real-user progress as part of technical context wiring.


## 29. P2/P4 independent published-source proof and scoped delivery (2026-10-13)

**Focused technical completion in QA:** `qa/sql_drafts/iclub_ai_source_proof_bundle_v21_UNAPPLIED.sql` adds a private, versioned **source receiver**, plus service-role-only read RPCs `get_iclub_ai_v21_source_proof_service` and `get_iclub_ai_v21_source_bundle_service`. Their signatures match the existing QA Deno adapter. The source receiver is independent from the topic release registry: BOTH the versioned source AND its exact surface/subject/feature/topic/locale-approved release row (with all eight gates) must pass. Proof recomputes **SHA-256 of the actual source payload** on each request and rechecks rights, QA, conflict and runtime. Source bundle revalidates a server-minted current owner/screen and publication revision, then gives only **one exact approved prepared reply**, or the permitted source-only passage for generated route. Invalid keys, unseen subjects, stale screen, another language, revoked rights and changed digest stay unavailable. **No academic content was authored here; publisher/approval writer is separate and NOT installed.**

**Critical defect found by real PostgreSQL:** `jsonb_typeof(missing_key)` returns SQL NULL, so `<> 'string'` failed open for a nonexistent prepared card. Fixed using `IS DISTINCT FROM 'string'`; regression confirms unknown prepared card now safely returns unavailable/in-development without an approved null reply.

**Independently verified actual QA execution:** [GitHub Actions #38354487650](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38354487650), commit `c0d95159f99e0700798d57c65f7c060ebd0777cd`, SUCCESS. Native Node.js 22 **406/406**, native Deno 2 **40/40**, real isolated PostgreSQL 16 **8/8 scratch suites**, including new source-proof coverage, plus concurrency/atomic rollback and unchanged original Mathematics Exam Prep check. No real Supabase data was queried or modified for these source tests. No provider calls, Vercel builds, production migrations or student access enabled.

**Explicit next implementation gate:** separate authorized editorial publication handoff and reviewer approval protocol; real, RLS-reviewed server services for runtime/rollout/entitlement and monetary budget; genuine Supabase Edge bundling and ONE deliberate protected synthetic Preview. A verified source hash is **not** an academic correctness review, nor beta permission; current AI remains OFF. Content/questions/cards are produced only in the other chat.

Technical handoff: `docs/iclub-ai-layer-p2-p4-verified-source-bridge-v2.1.md`. Protected production academic code, localStorage and existing Exam Prep AI remain untouched.


## 30. P4 governed editorial release and safety revocation (2026-10-13)

**The exact next technical milestone is complete in QA, not deployed.** New `qa/sql_drafts/iclub_ai_editorial_ticket_publisher_v21_UNAPPLIED.sql` provides a scoped, atomic editorial-release transaction and emergency safety suspension. Content/cards/questions/lesson text remain entirely the other editorial workstream. Release requires an independently staged, non-expired single-use ticket covering source ID/version/hash, subject/surface/feature/topic/locale, ALL eight editorial/technical gates and **three distinct content, rights and technical reviewers**. Database enforces one reviewer identity per ticket, atomic locks, exact current payload SHA-256, and expected publication revision. It cannot automatically enable another language, an already active row, a quarantined source or a new beta.

**Separation of duties:** Publication/revocation RPC privileges are revoked from `public`, `anon`, `authenticated` and even learner-serving Supabase `service_role`; only a dedicated *QA-only*, non-login editorial executor role is granted EXECUTE. Tickets/signoffs have no browser-accessible writer RPC. The existing Deno learner AI adapter has no publishing or revocation method. This sandbox role is **not** production provisioning; genuine reviewer identity and evidence intake remain a future separately authorized governance integration.

**Urgent safety suspension:** an independently staged single-use safety ticket with a reason and exact expected revision disables a specific approved publication, increments revision and suspends its source in the same PostgreSQL transaction. Subsequent server source-proof/bundle requests fail closed; it does not erase lessons, answers, progress or the editor's content. A revoked/suspended version is not automatically republished.

**Verified real QA:** [GitHub Actions #38355636618](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38355636618), SUCCESS. **418/418** native Node.js tests, **40/40** native Deno with strict TypeScript, **9/9** real disposable PostgreSQL 16 suites, the previous two-worker claim race and academic isolation checks PASS. Publication was deliberately interrupted between source and release writes: the transaction rolled back source, release and ticket consumption together; retry completed after the injected failure was removed. Published material remained unavailable with the global AI kill switch ON.

**NO-GO still applies:** No real reviewer credentials, content-ingestion publisher, production migration, existing user data, Edge deployment, payment, provider, or student beta was changed or enabled. Do not infer beta approval from successful editorial publication. Real signature/evidence authority, secure migration and RLS, global/rollout/monetary authorization, provider safety and one protected synthetic Preview remain open.

Full handoff: `docs/iclub-ai-layer-p4-editorial-ticket-publication-v2.1.md`.



## 31. P8 read-only server runtime/rollout/entitlement bridge (2026-10-13)

**QA-only implementation, NOT deployed:** Added scratch-guarded `qa/sql_drafts/iclub_ai_v21_live_authority_UNAPPLIED.sql` implementing five correctly shaped Deno learner RPC contracts for runtime, protected assessment, rollout, entitlement and provider budget. Actual production v1 guards and metadata were verified READ-ONLY; existing `global_ai` runtime is OFF (UI OFF, Gateway OFF, generation OFF, kill-switch ON, rollout OFF). The v2 subject/topic/locale proof remains separate from broad v1 subject-wide readiness. Reuse the real v1 cohort, enrollment, subject guard, subscription and active-assessment authority; never create substitute learner rights.

The independent Global AI owner release row has no approval by default, and the provider-budget RPC deliberately DENIES until atomic monetary budget accounting has been approved/tested. No new commercial tariff, student rights, real model, old Math Tutor or real database change. New synthetic PostgreSQL + Node/Deno regression is wired into the existing QA-only workflow. See `docs/iclub-ai-layer-p8-runtime-authority-v2.1.md`. Preview and actual integration remain NO-GO.


## 32. P4 independently signed editorial evidence bridge (2026-10-13)

**QA-only and UNAPPLIED.** A separate Ed25519 validator with a default-DENY trusted public-key registry verifies content/rights/technical reviewers sign the same exact eight-gate source/version/hash/topic/locale/ticket/revision metadata; emergency safety suspension needs its own verified reviewer and reason. The §30 scratch publisher now requires matching short-lived private attestation in addition to three signoff rows; unsigned UUIDs alone DENY. A separate NOLOGIN evidence importer cannot publish; publisher cannot import evidence; learner service_role cannot do either. The actual keys and reviewer accounts are NOT provisioned, and synthetic PostgreSQL attestation rows simulate a verifier result, not production signatures. See `docs/iclub-ai-layer-p4-verified-review-evidence-v2.1.md`.


## 33. P8 provider monetary liability ledger (2026-10-13)

**QA-only, not deployed:** implemented `qa/sql_drafts/iclub_ai_v21_provider_spend_UNAPPLIED.sql`, a separately disabled, owner-configured monetary ceiling and permanent request-ID lease ledger. It requires v2 learner quota reservation plus first-writer delivery claim; provider budget reserve uses a global PostgreSQL transaction advisory lock. Only one successful `dispatch` per request; current protected assessment, kill switch, owner release and generation flag checked again before dispatch. Unknown timeout/cancel preserves FULL held monetary liability even if learner quota is refunded. Known provider bill uses actual <= reserved; definite never-dispatched request may release. No automatic lease deletion/reset, provider call, commercial pricing or service-role money-policy writer exists. All numbers in tests are synthetic micro-USD, not approved real pricing. The §31 read-only budget probe remains DENY; no live generation can be enabled by publishing this SQL. Native scratch real PostgreSQL regression + Node contract tests wired into isolated QA CI. Secure Edge orchestrator wiring, real provider invoice reconciliation and approved budgets remain outstanding.


§33 correction (2026-10-13): Native PostgreSQL monetary suite uses the actual existing v1 runtime schema, not a shadow definition. QA Deno maps the three new independent money RPCs and treats missing services as DENY. The prior §31 budget preflight remains DENY and paid generation stays impossible until separately approved.


## 34. P8 distributed financial concurrency and safe recovery (2026-10-13)

QA-only Part A: Two actual independent PostgreSQL sessions race for two different request IDs against a single synthetic monetary cap of 80 micro-USD. The advisory lock must permit one reservation and reject the other; the money ledger must contain exactly one held ceiling. Test script `qa/run-ai-layer-v21-budget-race.sh`, in GitHub QA CI, no provider or real database access. Part B short-lived recovery is a separate QA candidate, not a live transcript store.


§34 Part B (2026-10-13, QA only): `qa/ai-layer-v21-encrypted-recovery.cjs` proves a short-lived (2-minute existing mock TTL), AES-256-GCM-encrypted answer receipt can be shared across worker instances without plaintext storage or re-invoking the provider. Keyring MUST be independently injected; no secrets or real learner texts. Read requires both completed-delivery verification and FRESH server authorization (owner, exam, subject, source-version/revoke, session and rollout). No deployed durable storage, no actual database receipt table, no guarantee of recovery if response was lost before encrypted recording. Final encrypted storage/retention policy and real Edge route require separate approval. No live model, financial activation or user data.


§34 Part C (QA UNAPPLIED): native SQL `qa/sql_drafts/iclub_ai_v21_encrypted_reply_UNAPPLIED.sql` atomically commits the v2 learner usage/tombstone and inserts only client-server encrypted AES-GCM envelope metadata (nonce, ciphertext, auth tag, key reference) in the same PostgreSQL transaction. An injected receipt INSERT failure rolls back quota and delivery completion. Freshly authenticated server may read ciphertext only for an exact owner/session/request/source digest/route, completed reservation and non-expired two-minute access; crypto key and plaintext NEVER reside in DB. Real content permissions/source revocation must be rechecked by Edge immediately before decryption/delivery. No physical cleanup scheme, key store, real Edge integration or production migration approved. Native real PostgreSQL synthetic suite now covers this atomicity.


## 35. P9 unified synthetic Deno HTTP to server-owned RPC vertical slice (2026-10-13)

**QA ONLY — no real users, provider, database writes, migrations or Preview.** Added `qa/edge_v21/e2e_synthetic_test.ts`: true composed Deno HTTP handler + shared original CommonJS request core + Supabase service adapter + context mint/revoke, with 100% synthetic RPC transport. Exercises Biology, Chemistry, Mathematics (NOT Exam Prep), Informatics and Economics in Lessons and finished Practice; verifies RU/UZ/EN not-ready display and zero debit/model, exact per-language source approval, live source revoke while awaiting, protected exam, rollout/subject loss, killed runtime, invalid JWT, CORS and forged browser context. Prepared source only; generation and real paid provider remain disabled. A production Supabase schema migration, publisher account, actual Edge route and real browser Preview are expressly NOT part of this QA test. Legacy Math Exam Prep untouched. See `docs/iclub-ai-layer-p9-synthetic-e2e-v2.1.md`.


§35 approved mobile shell refinement (QA only): mobile collapsed chat now 76vh instead of 68vh, with dynamic full-screen expand/restore, per-language accessibility labels (RU/UZ/EN), safe-area preservation and close-on-navigation collapse reset. Existing unapproved temporary logo is intentionally unchanged. UI static/regression checks are in QA; no browser Preview or production deploy authorized.


## 36. P8 fail-closed paid route integration in original QA Edge core (2026-10-13)

**QA-only hardening (no provider enabled):** The original generated-route core previously trusted `providerBudgetAllows()` as though it reserved money; it did not invoke §33 atomic money reserve/dispatch RPCs. Fixed by making all 3 money services mandatory at construction. After durable learner quota+claim it now requires monetary reserve and one-time dispatch before touching the provider; absent, denied or lost confirmation means no model. Rechecks current user/exam/subject/source after reservation and dispatch. If reserved but definitely never dispatched, requests `no_charge` (else conserva­tively retains the hold); if dispatched, always attempts `unknown` full-ceiling reconciliation, whether provider result succeeded or failed. Any uncertain outcome prevents answer and refunds learner quota without silently releasing possible external provider liability. Existing Math provider accounting remains isolated. Tests cover money refusal, lost dispatch ACK, kill/exam between steps, provider error and duplicate requests. The Deno adapter still deliberately refuses real generation. No live budgets or entitlement changes.


## 37. P3 QA browser-to-Edge context transport without legacy cutover (2026-10-13)

**QA only:** The currently dormant global-ai-ui.js still invokes the V1 `global-ai` function and V1 bootstrap; it is not a client of the independently validated v2 /context and /answer endpoints. Do NOT claim visual/Edge end-to-end production integration or silently cut over that shell. Implemented isolated `qa/ai-layer-v21-ui-transport.cjs` and synthetic native Node tests of the correct v2 contract: server mint Lesson/finished Practice handle with *selectors only*, no user subject/plan/progress; exact answer/status with current bearer JWT, no private transcript, no retries after unknown delivery, reject stale replies after leave, logout or screen change, revoke even handles returned by a delayed mint. Nothing imports this module in index.html, app.js or active production. Real app UI cutover, strict source/rollout/auth checks and 320/390/desktop browser visual QA remain a separately authorized staging step. Temporary AI logo remains undecided.


## 38. P3 actual headless browser viewport QA, synthetic only (2026-10-13)

`qa/ai-layer-v21-visual-harness.html` loads the REAL checked-in global-ai-ui.css and global-ai-ui.js with an in-page synthetic bootstrap. `qa/ai-layer-v21-browser-visual.cjs` drives actual Chrome via native Node 22 DevTools Protocol, no npm or remote network. Tests exact 320×568, 390×844, 1366×768, 390×480, mark separation from bottom nav, panel containment, 70–80% mobile sheet, controls not overlapping, full-screen expansion/restore, RU/UZ/EN accessible labels, close on navigation, hide all AI during protected diagnostic and restore. Hosted GitHub Actions runs browser offline in existing QA branch, never Vercel. Synthetic harness is not an actual app DOM/visual signoff, and unapproved AI logo still remains unchanged.


## 39. P3 account/session isolation and stale reply protection (2026-10-13)

QA-only dormant global-ai-ui.js had no account-specific invalidation for its in-memory conversations and accepted pending old-owner replies after auth event, leaving a cross-account privacy risk in the same browser tab. Hardened onAuthStateChange SIGNED_OUT / changed session.user.id: clear only temporary chats and UI state (NEVER localStorage, databases, existing learner progress), bump auth epoch, invalidate pending responses, hide/remove old panel and force fresh bootstrap. TOKEN_REFRESHED with identical principal retains same session chat. All bootstrap replies use epoch guard to block late prior-user UI visibility. Pending answers capture auth/context epoch and request ID, refuse stale result after navigation, account switch or protected assessment. Protected Tour/Exam Prep starts invalidate work. Browser synthetic harness runs all 4 real Chrome viewports and checks old-user deferred reply cannot appear for new user and same-user token refresh preserves own session. No actual learner account access, no Preview/production/migration changes.
