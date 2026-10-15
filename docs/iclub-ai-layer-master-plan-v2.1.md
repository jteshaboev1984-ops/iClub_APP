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


## 40. Preview preflight: real app Lessons/Practice screen compatibility (2026-10-13)

Read-only source inspection of the actual production baseline app.js/index.html showed that Lesson cards set `state.courses.lessonId = lesson.id` in an internal click handler then open `courses-video`; the current DOM does **not** expose a trusted numeric `lessonId` selector for V2 Edge. The Practice result/review uses `data-practice-ai-attempt-id` from `state.practiceLastAttempt.db.attemptId` (legacy attempt ID); it is NOT proven to equal the separately required `public.practice_sessions_v4.id`, and there is no independently verified exact `questionId` admission selector. Copying the old attempt ID into the new V2 `/context` `sessionId` field is prohibited. The active `global-ai-ui.js` still invokes V1 `global-ai`, while isolated V2 requires `/context` then `/answer`; production UI replacement remains NO-GO. **Verified QA fix:** active ordinary Practice Quiz now fully hides the AI button/panel and invalidates pending replies on entry, without touching Practice backend; restored on result. Chromium synthetic harness regression added. Protected isolated Preview needs separate owner permission and isolated non-production Supabase, plus independently verified Lesson/Practice selectors and client wiring. Until then Preview launch gate NO-GO. No new branch/PR/deploy/prod writes.


§40 protected Preview verdict (2026-10-13): real app source audit proves NO_GO. Lessons video uses internal `state.courses.lessonId` without a V2 selector; Practice result legacy `data-practice-ai-attempt-id` is not verified as `practice_sessions_v4.id` plus `questionId`; the UI still calls V1 `global-ai`. No isolated QA Supabase/auth verification or explicit owner Preview deployment authorization. Machine-readable preflight in `qa/ai-layer-v21-real-screen-preflight.cjs`, tests ensure blockers remain explicit, never silently map old attempts to V2. Active Practice Quiz blackout and stale reply suppression separately tested in actual Chromium fixture. Original app.js, index.html, and production Edge remain unchanged.


## 41. P3 QA-only exact screen binding for eventual Lessons and finalized Practice (2026-10-13)

`qa/ai-layer-v21-screen-binding.cjs` is a standalone QA-only helper (not imported by current app), which consumes only future explicit numeric V2 Lesson ID or finalized V4 Practice session+selected question selectors when their matching screen is active. It fails closed on unmodified real app markup, legacy `data-practice-ai-attempt-id`, unknown/multiple questions, active Practice Quiz/Tours/Exam Prep, malformed IDs or missing context. It invalidates and revokes old handles before transitions, drops stale mint/status/answers after screen or owner change, and still relies on server RPC for real finalization/owner/rights/rollout. Node tests and real Chromium four-viewport fixture exercise the exact markers and deliberate legacy refusal. None of these markers are yet installed in `index.html` or `app.js`, hence §40 Preview NO_GO remains. No branch/PR/Preview created; no real DB or progress touched. See `docs/iclub-ai-layer-p3-exact-screen-binding-v2.1.md`.


## 42. QA-only source-backed Practice review publisher (2026-10-13)

Source inspection finds actual V4 session in `quiz.safeSessionId` after `api.finalize`, server `finalResult.attempt_id` is a DIFFERENT identifier (never interchangeable), and finalized question IDs from `safeApi.review(dbAttemptId)`. QA-only publisher `qa/ai-layer-v21-evidence-publisher.cjs` requires completed safe V4 finalize, server-backed review, exact match against rendered review question IDs, and explicit one-question selection before exposing any v2 DOM selector. Stale async reviews and changed screens are cleared with epoch token. Lessons subject Telegram video screen overwrites selected `lesson.id` with the first subject lesson ID, therefore lesson-context binding is intentionally denied until a true lesson-specific screen exists. All scripts are isolated QA and remain unimported by app.js/index.html; approved UI integration and real isolated Preview still NO-GO. See `docs/iclub-ai-layer-p3-evidence-publisher-v2.1.md`.


## 43. Integrated original Practice source overlay, no redundant QA loops (2026-10-13)

The remaining milestone is one coherent UI candidate, NOT more isolated adapter proofs. `qa/ai-layer-v21-preview-assembly.cjs` creates and deletes temporary in-memory/OS-temp copies of original app.js and index.html with exactly 3 precise Practice hooks: navigation, server-finalized V4 result, server review rendering. `qa/ai-layer-v21-preview-glue.cjs` composes these with existing evidence publisher and ensures no legacy attempt ID can become V4 session selector. Source drift fails closed. Original app.js, index.html, Math Tutor and live storage are byte-identical, no Preview/deploy created. True Lessons AI on subject Telegram video remains NO-GO, as selected lessonId is overwritten. This is a synthetic integration candidate ONLY: QA has not switched UI to /context /answer or created a live/Preview release. Plan §10 permits existing protected Preview for isolated synthetic UI but not production writes; a new deployment needs architect approval. Follow report `docs/iclub-ai-layer-p3-p9-consolidated-source-candidate-v2.1.md`.


## 44. P9 single owner-approved, SSO-protected SYNTHETIC Preview (2026-10-13)

Owner explicitly approved exactly ONE protected Preview. Vercel `i-club-app` SSO protection verified enabled for noncustom Preview URLs. Candidate source in `qa/ai-layer-v21-protected-preview/` uses true QA global-ai-ui.js/CSS and verified QA V2 transport + binder/publisher/glue but ONLY a static in-memory synthetic Economics Practice and mock `/context` `/answer`; CSP blocks network and external resources. No real app.js/index.html, Supabase SDK, provider keys, storage writes, production targets or user data in the deployment. It demonstrates synthetic Home → active Practice blackout → finalized result → reviewed question → real AI visual shell. P9 public/beta GO remains NO-GO until separate authorization and actual backend contracts are approved. See `docs/iclub-ai-layer-p9-protected-synthetic-preview-v2.1.md`.


## 45. Единый допуск для ВСЕГО iClub (QA-only)

Один `QAAppWideFeatureAdmission` объединяет реальные surface types global help (включая навигационные разделы), subject overview по **всем предметам**, Home, Profile, Lessons, завершённый Practice, открытый архив Tours через существующий `ContentHandoffGate`. Все доказательства только из injected authenticated server services; авторизация проверяется дважды после async. Legacy Mathematics Tutor строго изолирован и его маршрут не меняется. Все тесты синтетические; Preview не является реальным AI backend. Ни одна незрелая функция/предмет не открывается на основании старого inventory. См. `docs/iclub-ai-layer-app-wide-admission-v2.1.md`.

## 46. P6 единый доверенный серверный adapter для всех экранов (2026-10-14; QA ONLY)

Из текущего HEAD `6d8e3e89b88cb386cde720494a5c42cd0adeeef2` продолжена единая архитектура: `qa/ai-layer-v21-trusted-server-adapter.cjs` переиспользует существующий `QAAppWideFeatureAdmission` и `ContentHandoffGate`. Один серверный read-only evidence-builder принимает только owner-bound `getScopedContext`, действующий server-current-screen и конкретные JWT-bound domain readers, возвращает лишь хешированный минимальный proof, повторно проверяет экран после асинхронных чтений. Незавершённые V4 Practice, неверная пара session/question, чужая запись, закрытый Tour, отсутствие runtime finalization, subject-wide video, неподтверждённый Home/Profile aggregate, stale screen, broken source/rights/rollout, активный экзамен/AI OFF закрываются без учёта запроса. Новых таблиц, миграций, permanent чатов и изменений академической истории нет. Добавлены `qa/ai-layer-v21-trusted-server-adapter.test.cjs`, offline runner и CI trigger на этот QA-блок. Подробности: `docs/iclub-ai-layer-trusted-server-adapter-v2.1.md`.

**Точная граница:** это проверяемый server-contract adapter на инъецируемых авторитетных read-only сервисах, **не** production-интеграция. `qa/edge_v21/supabase_services.ts` ещё не выдаёт необходимую серверно подтверждённую current-view/evidence для всех экранов. Показанные в тестах proofs синтетические. До серверных RPC/снимков актуального экрана, user-scoped релизов и отдельного разрешённого staging Edge cutover новые функции остаются **NO-GO**. Никакого автоматического перехода Mathematics Tutor, платежей, провайдерной генерации или Preview.


## 47. P7 единый QA Edge с доверенными evidence readers для всего iClub (2026-10-14)

После §46 реализован связанный, а не параллельный, QA-контур: существующий `CandidateEdgeRequest` принимает `TrustedAppWideServerAdapter` и запускает один app-wide admission перед запросом, после асинхронных действий и перед delivery. Deno `qa/edge_v21/runtime.ts` теперь действительно подключает этот допуск. Дополнительно проверяется server-only `proofHash`, чтобы изменение актуального доказательства экрана без смены source-version тоже отзывает запрос.

В `qa/edge_v21/screen_proof_services.ts` определены 11 минимальных read-only читателей через **один предполагаемый server RPC** `get_iclub_ai_v21_screen_evidence_service`; все права и конкретные user/session/question/attempt selectors проверяются, неизвестные RPC или записи полностью блокируют ответ. `qa/edge_v21/supabase_services.ts` получает точные поля актуального server-owned контекста. Для General Help добавлен отдельный proposed `get_iclub_ai_v21_general_scope_service`: он не подменяется искусственной строкой учебного предмета.

Deno HTTP e2e и отрицательные тесты в изолированном синтетическом окружении доказывают отказ на смену экрана, чужого владельца, неправильный selector, отсутствие RPC/публикации, текущую защищённую проверку, выключенный AI и конфликт источника без ложного списания. Рабочий Exam Prep Tutor, база, localStorage, front-end и провайдерные настройки не изменены. Фактический server RPC и живые Home/Profile/Tour screen proofs ещё **не развернуты**; all app-wide feature availability остаётся **NO-GO** до подтверждённой защищённой изолированной интеграции. Документ: `docs/iclub-ai-layer-app-wide-edge-binding-v2.1.md`. Результат CI сверять только по последнему HEAD, а не считать успешный синтетический run доказательством production готовности.


## 48. P7 фактическая проверка production-схемы и реальный SQL evidence subset (2026-10-14; READ-ONLY + SCRATCH)

Следующий логический блок после §47 завершён без записи в production: через подключённый Supabase выполнено **только чтение системных метаданных** `information_schema` и определений существующих RPC. Подтверждены физические формы `practice_sessions_v4`, `practice_session_answers_v4`, `tour_attempts`, `tour_session_runtime_v4`, `tours`, `user_subjects` и `lessons`. Выявлено: реальные Practice answers не содержат предполагавшихся тестовыми контрактами `user_id/server_checked/is_final/topic_key/revision`; эти поля нужно безопасно выводить из owner-bound finalized session/answer, а не читать как существующие колонки. У Tours timestamp финализации находится в `tour_session_runtime_v4`, а статус открытия архива определяется точно как в действующем `get_tour_review_full_safe_v4`: локальная дата Ташкента **строго позже** `end_date`, не в день завершения Tour.

Реализован **один** локальный проектный `get_iclub_ai_v21_screen_evidence_service` в `qa/sql_drafts/iclub_ai_v21_real_schema_screen_proof_UNAPPLIED.sql`; это намеренно **не** migration/production RPC. Он читает подтверждённые Practice V4 и Tour metadata, проверяет owner, enrollment, finalized status, opened archive, kill switch и защищённую проверку, не раскрывая ключей/ответов и не меняя прогресс. Права на вызов — только `service_role`. Home/Profile/general/current-screen/lesson-specific доказательства **не придуманы** и по-прежнему закрыты. Добавлен 13-й независимый disposable PostgreSQL тест `realproof`, проверяющий также чужую запись, незавершённую Practice, закрытый в последний день Tour, смену прав, exam guard и сохранность приватных ответов. CI автоматически исполняет его после остальных 12 suites. Подробный первичный аудит и NO-GO в `docs/iclub-ai-layer-p7-real-schema-proof-audit-v2.1.md`.

Срок жизни server-owned current-screen и действительный контекст Home/Profile/General/Tours остаются отдельным **блокером реальной интеграции**, пока нет подтверждённого RPC и QA UI wiring. Существующий Mathematics Tutor, production DB, main, Vercel, рабочие Functions, localStorage и реальные пользователи не изменены. Зелёный scratch CI подтверждает SQL-контракт на структурно совместимых искусственных данных, **не** готовность публикации AI для учеников.


## 49. P7 short-lived current-screen authority для Practice, Lessons, Tour Archive (2026-10-14; QA ONLY)

После §48 повторно использованы **существующие** QA структуры `private.iclub_ai_v21_current_screen` и `private.iclub_ai_v21_scoped_contexts` без создания новой таблицы, постоянного чата или записи учебной истории. `qa/sql_drafts/iclub_ai_scoped_context_v21_UNAPPLIED.sql` возвращает из server-owned rows `current_view='courses'`, точные `practice_session_id/question_id/lesson_id/tour_attempt_id`, `screen_N` revision и 90-секундную действительность. Новая выдача контекста отзывает предыдущий handle; повторное открытие той же подтверждённой записи идемпотентно. На каждом read повторно проверяются владелец, server active screen revision, TTL, protected exam, права и исходные учебные данные.

Одним существующим механизмом контекста дополнительно охвачен открытый Tour Archive: `mint_iclub_ai_v21_tour_archive_context_service` требует точного owned attempt, завершённой строки `tour_session_runtime_v4`, статуса `submitted/time_expired`, enrollment и даты **строго после** `tours.end_date` в Asia/Tashkent. Действующий `qa/edge_v21/context_core.ts` принимает отдельный строго ограниченный selector `{action:'mintTourArchive',tourAttemptId}`, но сохраняет один endpoint `/context` и один `/answer` с `TrustedAppWideServerAdapter`. Невозможно предъявить клиентский subject, topic, answer или plan как право. `get_iclub_ai_v21_screen_evidence_service` теперь возвращает минимальную `current_screen` proof **только** по серверному неистёкшему handle с актуальной ревизией и повторной проверкой исходного учебного контекста. На SQL и Deno синтетических QA тестах проверяются подмена пользователя, закрытый Tour, окончание/отзыв/смена экрана, expired handle и защита от старых ответов.

**Граница:** это server-issued текущий контекст по `Courses`, а не доказательство физических пикселей реального браузера: о navigation/logout клиент должен сообщать через revoke, в том числе после смены tab. Настоящие Home/Profile/General Help и независимая готовность Lessons/videos всё ещё **NO-GO** из-за отсутствия утверждённых server evidence и source/locale release. Контракт SQL остаётся `_UNAPPLIED` в QA, не устанавливался в Supabase. Действующий Mathematics Exam Prep Tutor, производственная база, main, UX, progress, localStorage, provider billing и Preview не тронуты. Детали: `docs/iclub-ai-layer-p7-current-screen-authority-v2.1.md`. Утверждение полной интеграции возможно только после независимой защищённой среды, реального trusted UI wiring и подтверждения контентных выпусков.


## 50. P6 Home/Profile/General Help: серверный scope и проверенные показатели Profile (2026-10-14; QA ONLY)

После §49 фактический `app.js` и read-only database schema показали важную границу: Home отображает локально выбранные учебные направления и вычисленные показатели, а Profile одновременно использует серверные и локальные источники (`Best/Trend/Stability` частично берутся из локальной Practice history). **Эти локальные вычисления не становятся подтверждённой серверной педагогической рекомендацией.** Действующая `getProfileCompletedToursCount()` учитывает `anti_cheat` наряду с `submitted/time_expired`; новый доказуемый QA-снимок намеренно НЕ копирует этот неоднозначный показатель и не подменяет существующий экран.

В существующей `qa/sql_drafts/iclub_ai_scoped_context_v21_UNAPPLIED.sql` без новой таблицы добавлены строго разделённые серверные 90-секундные `home/profile/global` scoped handles, тот же owner, kill switch, revision, TTL, rate limit, exam guard и revoke. Новый `mint_iclub_ai_v21_app_view_context_service` допускает только зарегистрированного через `public.users` владельца и ограниченные `home,profile,courses,ratings,about,support` view selectors. Через существующий **один** `qa/edge_v21/context_core.ts` доступно `mintAppView`, а `supabase_services.ts` вызывает лишь service-role RPC. Подстановка клиентских subject/topic/userId/progress/plan запрещена.

В одном `get_iclub_ai_v21_screen_evidence_service` по действующему owner-bound Profile handle выведен **минимальный агрегат фактической активности**: количество активных Competitive-предметов, закреплённых Study-предметов и уникальных завершённых Tours, имеющих подтверждённую `tour_session_runtime_v4.finalized_at` и `submitted/time_expired`. Ни mastery, ни marks, ни локальный Best/Trend/Stability, ни следующий учебный шаг не выводятся. Revision получает текущая авторитетная screen row; минимальный proofHash включает точные агрегированные значения. Другие экраны могут получить защищённый контекст, но **Home next-actions и General Help navigation НЕ имеют утверждённого опубликованного источника и остаются NO-GO**. Контекст ≠ ответ, расход квоты или разрешение провайдера.

Scratch PostgreSQL добавляет проверку владельца, фактических минимальных счётчиков, отсутствие персональных полей, завершение Tour, revoke при navigation, exam blackout и строгий fail-closed отсутствующих Home/General sources. Deno проверяет forged selectors и service-role-only mint. Итоговые тесты сверяются по последнему полному CI. Все QA SQL остаются `_UNAPPLIED`, рабочие main/app.js/index.html/Supabase, данные/progress/localStorage, действующий Mathematics Tutor, provider/billing и Preview не менялись. Детали: `docs/iclub-ai-layer-p6-home-profile-general-trusted-scope-v2.1.md`.

Следующий реальный блок: согласованный источник Home next-actions (без выдуманного прогресса), редакционно утверждённый навигационный источник General Help по RU/UZ/EN и защищённое независимое UI binding с отзывом контекста при навигации. До этого Global AI beta **NO-GO**.


## 51. P6 verified navigation source candidates + tri-locale editorial gate; Home next-actions NO-GO (2026-10-14, QA only)

После §50 проверена фактическая структура `index.html`, маршрутизация `setTab()` в рабочем `app.js` и существующие буквальные переводы `i18n.js`. На их основе **без написания новых учебных рекомендаций** создан черновик `qa/ai-layer-v21-p6-navigation-candidates.snapshot.json`: шесть проверяемых маршрутов — Home, Study, Ratings, Profile (нижняя навигация), About и Support (отдельные экраны); для каждого сохранены реальные UI selectors и **дословные** RU/UZ/EN labels. Новый тест `qa/ai-layer-v21-p6-navigation-candidates.test.cjs` откажет при исчезновении маршрута, изменении любого перевода, смешении локалей или незаметной публикации черновика. Данный каталог = **candidate/DRAFT**, не утверждённый контент и не server release.

`qa/sql_drafts/iclub_ai_source_proof_bundle_v21_UNAPPLIED.sql` расширен только для **существующей общей** функции `global/general/app_help/navigation`: допускает будущее независимое редакционно одобренное source/version/hash для данного маршрута, но запрещает `generated` route для навигационных инструкций. Сохраняются все проверки source rights, SHA256, публикации, конфликтов, locale и автора release; технический путь не создаёт утверждённых карточек, не пишет академические таблицы, не вызывает provider.

Новый `qa/sql_drafts/iclub_ai_v21_p6_navigation_gate_UNAPPLIED.sql` добавляет предполагаемый read-only `get_iclub_ai_v21_general_scope_service`: `general` разрешается **только** при независимо проверенных трёх локалях RU/UZ/EN одной версии. Любой отсутствующий перевод, неполный редакционный sign-off, изменение hash/версии, отзыв права или global kill switch сразу возвращает `allowed=false`. `get_iclub_ai_v21_screen_evidence_service` теперь признаёт `navigation` лишь при этом gate, точном server-owned текущем **global** экране и JWT-владельце; синтетические подтверждения с другого экрана / чужой учётной записи отвергаются. Проверки положительной и отрицательной публикации проведены **только** искусственными записями внутри изолированного PostgreSQL transaction, закончившегося `ROLLBACK`; не настоящие RU/UZ/EN content releases.

**Home next-actions намеренно остался DENY.** Рабочий Home пользуется локальным состоянием выбранных предметов и разнотипными Practice/Tour показателями; существующие `learning_roadmaps` не предоставляют автоматически подписанный единый кросс-предметный план. Показатели Profile из §50 не являются доказательством мастерства или основанием выдумать направление обучения. Любая персональная рекомендация требует отдельно утверждённого авторитетного server planner, права/приоритеты, ревизию, определённую семантику и независимый source/locale release.

**Выпуск:** всё в `qa/iclub-ai-layer-v21-20261012`, черновые `_UNAPPLIED.sql` без production migration, настоящих контентных seed и learner rollout. `main`, Vercel/production, реальный Supabase, localStorage, реальные ученики, прежний Math Tutor и защитные проверки не изменялись. Подробная карта: `docs/iclub-ai-layer-p6-navigation-source-review-v2.1.md`. Следующий этап — независимая редакционная доработка и проверка реально допустимых навигационных шагов/помощи по RU/UZ/EN, а для Home — согласованная серверная модель next-actions. До этого **NO-GO**.


## 52. P6 редактируемые RU/UZ/EN инструкции и проверка будущего Home-плана (2026-10-14; QA ONLY)

Проверены реальные DOM и навигация действующих `index.html`, `app.js` и буквальные RU/UZ/EN переводы `i18n.js`. Созданы 18 коротких редакционных черновиков для шести действующих переходов: Home, Study, Ratings, Profile, About и Support. Для About подтверждено различие английских названий: кнопка входа «About project», заголовок страницы «About». About находится на Главной; Support — в Профиле. Все черновики `qa/ai-layer-v21-p6-navigation-editorial-drafts.snapshot.json` имеют `releaseAllowed=false`, не опубликованы и требуют редакционной проверки. Автоматизированные тесты сверяют фактические элементы, handlers и подписи всех трёх языков, без вымышленных экранов.

Независимый QA-only `qa/ai-layer-v21-p6-home-next-action-proof.cjs` проверяет будущий server-owned Home-план: JWT-владелец, текущий 90-секундный handle/revision, самостоятельная верификация источника плана, подтверждённые backend academic evidence hash/revision каждого действия, locale-specific редакционный source release и повторная проверка экрана после асинхронных запросов. Все отсутствующие доказательства, другая учётная запись, устаревший экран, подделанные действия и неподтверждённая локаль дают `ready:false`. Этот код не подключён к Deno/production и не создаёт рекомендаций: виды действий пока только технические кандидаты для отдельного решения архитектора.

**NO-GO:** Home не получает планировщик или `home_next_actions` до отдельного утверждения академических правил, источников и приоритетов; Navigation не получает release, пока редактор не подтвердит 18 текстов и три языковых source bundles. Никаких изменений `main`, production, реального Supabase, localStorage, реальных учеников, Mathematics Tutor, платных провайдеров и Vercel. Детали: `docs/iclub-ai-layer-p6-editorial-drafts-and-home-plan-v2.1.md`.


## 53. P6 редакционный пакет для General Help без публикации (2026-10-14; QA)

В продолжение §52 создан отдельный `qa/ai-layer-v21-p6-editorial-source-packet.cjs`, который готовит **три закрытых редакционных кандидата** с шестью подготовленными ответами на каждом языке из исходных 18 текстов. Пакет строго требует исходный статус `EDITORIAL_DRAFT_NOT_APPROVED`, все семь флагов согласования выключены, точные шесть зарегистрированных маршрутов, правильные HTML selectors, родительские экраны и все три полных языка. Неодобренный, подменённый, неполный или неверно переведённый пакет отвергается. Дайджест `draftFingerprint` нужен **только для контроля редактирования** и НЕ равен database `source_hash`; ни content release, ни редакционные signoffs, ни provider request не создаются. Регрессия `qa/ai-layer-v21-p6-editorial-source-packet.test.cjs` проверяет все отказы. До отдельного одобрения содержимого General Help **NO-GO**.

## 54. P6 повторная проверка Home-источника после асинхронных операций (2026-10-14; QA)

Черновой validator `qa/ai-layer-v21-p6-home-next-action-proof.cjs` теперь фиксирует целостность плана **до** асинхронной проверки, затем повторно читает авторитетный план, подтверждает независимое право на него и ещё раз проверяет каждое академическое evidence и редакционный source для нужной локали; только после этого заново проверяется экран и TTL. Новые негативные тесты ловят замену приоритета/версии/hash, отзыв прав во время обработки и изменение общего JS-объекта. **Это всё ещё невстроенный QA-контракт**. Никакой план для ученика не создаётся, `home_next_actions` в SQL отказывает, приоритеты действий требуют отдельного продуктового решения. В реальном запуске останется требование атомарной ревизии и recheck при доставке.

## 55. P6 запрет неизвестных навигационных команд, даже если они попали в источник (2026-10-14; QA)

Существующий `qa/sql_drafts/iclub_ai_source_proof_bundle_v21_UNAPPLIED.sql` дополнен строгим allowlist шести утверждаемых ключей `nav_home/nav_courses/nav_ratings/nav_profile/nav_about/nav_support`, включая обязательную связку `global/general/app_help/navigation` и прежний prepared-only режим без LLM. В синтетическом scratch PostgreSQL специально присутствует лишний подготовленный `nav_billing`, который должен быть отклонён, несмотря на целостный content hash и синтетическую публикацию. Разрешённый синтетический `nav_about` продолжает выдаваться только при всех независимых gates, включая три языка. Реальных seed, approval или публикации не было.

Отчёт: `docs/iclub-ai-layer-p6-editorial-packet-and-proof-hardening-v2.1.md`. Все §53–55 изменения ограничены QA-веткой, тестовыми исходниками, документами и скретч SQL; main, production, Supabase, localStorage, реальные ученические записи, Mathematics Tutor, Vercel и billing не менялись. **Global AI NO-GO.** Следующая работа: подготовка отдельного P6 release review packet и независимая UI/Edge интеграционная проверка на синтетических данных, не включение AI.


## 56. P6 независимый QA release preflight и явный NO-GO (2026-10-14; без деплоя)

В качестве продолжения §53–55 введён маленький `qa/ai-layer-v21-p6-release-preflight.cjs`, который собирает состояние трёх закрытых редакционных пакетов и проверяет наличие ровно 18 черновых объяснений. Он **не является** publisher, CI deployment, автоматическим approval или доступом в Supabase. Результат фиксирует `NO_GO`, отдельно перечисляет непроверенные редакционные публикации, отсутствие авторитетного Home-планировщика, неутверждённые UI/Edge binding и beta cohort. Синтетический успех Node/Deno/PostgreSQL/Chromium не превращает этот отчёт в разрешение на production.

`qa/ai-layer-v21-p6-release-preflight.test.cjs` контролирует конкретные blockers и отсутствие в отчёте каких-либо действий publish/deploy/migrate/provider. Закрывающий gate требует отдельной редакционной экспертизы RU/UZ/EN, аудита прав/хэшей SQL-источника, доказанного Home planning, проверенной мобильной и desktop UI-ветки и **явного разрешения архитектора** до первого beta release. Без этого приложение остаётся в существующем production-состоянии. Детали, включая редакционные источники и гонки Home: `docs/iclub-ai-layer-p6-editorial-packet-and-proof-hardening-v2.1.md`. Внешние API, реальные учебные данные и main не затрагивались.


## 57. P6 независимое UI ↔ /context binding для Home/Profile/General Help (2026-10-14; QA only)

Сверена реальная маршрутизация `showView(viewName)` и атомарное переключение класса `.view.is-active` в неизменном production `app.js`. Создан **исключительно QA-код** `qa/ai-layer-v21-p6-app-screen-binding.cjs`, не включённый в `index.html`, `app.js`, действующие Functions или какие-либо реальные экраны. Он читает лишь видимые DOM selectors шести существующих views, никогда не считает их полномочием: по каждому разрешённому виду вызывает существующий отдельный JWT-bound `/context mintAppView` через один `qa/ai-layer-v21-ui-transport.cjs`, оставляя серверу проверку владельца, безопасности и source readiness. Клиентский userId, subject, plan и прогресс не передаются. В том же тестовом transport добавлен строгий `mintTourArchive` selector существующего QA Edge.

При уходе/смене экрана, logout, смене аккаунта или сокрытии вкладки старая локальная авторизация сбрасывается **до** подтверждения remote revoke. Во время активных Practice/Tour Quiz, Exam Prep или неизвестной страницы новый handle не создаётся. Мобильные/desktop DOM transitions с наложением двух views также fail closed. Любой устаревший ответ, поступивший после смены экрана, не показывается и не ретраится. В тесте late mint старого экрана отзывается независимо от нового контекста. В реальном приложении сейчас отсутствует этот биндинг и нет production UI entrypoint, поэтому его GREEN означает только синтетическую проверку жизненного цикла. Дополненные node-регрессии проверяют точный body без клиентских прав, revoke, protected blackout, поздний ответ и смену identity.

Этот §57 **НЕ** вводит оплачиваемый AI, новые страницы, постоянную переписку, мониторинг реальных пользователей, Supabase migration, Preview/PR или изменение Mathematics Tutor. Обязательные следующие gates: авторизованный редакционный release три локали, реальная серверная модель Home, согласование UI и защищённый Preview только по отдельному разрешению архитектора. Общий Global AI остаётся **NO-GO**.


## 58. P6 защищённая изоляция вложенных Courses-экранов от общего AI (2026-10-14; QA ONLY)

При сверке с фактическим `index.html` выявлено, что внутри Courses есть видео, результаты, reviews и рекомендации, которые требуют собственных Lesson/Practice/Tour прав, а не общей справки. QA-only `qa/ai-layer-v21-p6-app-screen-binding.cjs` теперь не mint-ит общий Global Help context, когда активны вложенные `courses-video`, Practice start/result/review/recs, Tour rules/result/review и recommendation detail, а также защищённые Quiz/Exam Prep. Второе исправление: вместо поиска **первого** активного `.view.is-active` выполняется проверка **ровно одного** фактически активного глобального view. Это исключает ложный Home контекст, если поверх него открыт неизвестный Certificates/registration экран. При Home/Profile нельзя отправлять общий `nav_*` prompt — у них иные отдельно неготовые product sources. Любой переход, уход со страницы или logout продолжает отменять локальное разрешение.

## 59. P6 контроль соответствия реальному DOM и маршрутизации iClub (2026-10-14; QA ONLY)

Добавлен `qa/ai-layer-v21-p6-real-ui-contract.test.cjs`, сверяющий все допустимые Global AI views, действительный `showView()` в `app.js`, IDs реального `index.html`, запрет неподтверждённых глобальных экранов, полный список опасных вложенных академических поверхностей и **отсутствие загрузки** QA-кандидата в рабочем приложении. Новые негативные тесты в `qa/ai-layer-v21-p6-app-screen-binding.test.cjs` проверяют наложения, защищённые вложенные экраны и недопустимые запросы с Home/Profile. Любое расхождение реального интерфейса с кандидатом приводит к провалу CI, а не к немому открытию AI.

Отчёт: `docs/iclub-ai-layer-p6-app-binding-threat-model-v2.1.md`. Данные и маршруты production, действующий Mathematics Tutor, app.js/index.html, real Supabase, localStorage, ученические результаты, миграции и платные провайдеры не тронуты. Остаются условия выпуска: утверждённые RU/UZ/EN источники, Home planner, независимая UI/Edge интеграция и отдельное разрешение архитектора. **NO-GO.**


## 60. P6 отзыв уже выданного контекста при неподдерживаемом экране (2026-10-14; QA ONLY)

Отдельный негативный сценарий проверяет не только отсутствие первоначальной выдачи, но и **немедленный отзыв уже выданного Home/Courses handle**, когда ученик попадает в непроверенную страницу Certificates, открывает вложенный Practice Review или два экрана оказываются одновременно активными. Изолированный `qa/ai-layer-v21-p6-app-screen-binding.test.cjs` требует, чтобы после каждой такой смены выполнялся `revoke`, локальное право стало `ready=false`, а последующий запрос статуса отвергался без сетевого `/answer`. Никаких изменений реального `index.html`, `app.js`, Supabase, Mathematics Tutor и состояния учеников. Защищённая интеграция остаётся NO-GO до утверждения источников и разрешения на отдельный Preview.

## 61. QA — единый общий контекст только в списке предметов (2026-10-14)

В существующем `app.js` проверен реестр 17 вложенных экранов Courses. Общая помощь QA разрешена только на `courses-all-subjects`, когда этот экран единственный активный внутри `view-courses`. Lesson, Practice, Tours, видео, материалы и все остальные вложенные экраны остаются за отдельной системой подтверждения. Добавлены автоматические сверки реального реестра и отрицательные тесты 16 остальных состояний. Production, база и данные учеников неизменны. Нет публикации AI и изменений `main`. Статус выпуска: NO-GO.

## 62. QA — срок действия серверного контекста и отбрасывание поздних ответов (2026-10-14)

`qa/ai-layer-v21-ui-transport.cjs` теперь проверяет объявленный сервером `expiresInSeconds` в диапазоне 1–90 секунд. При отсутствии либо неправильном сроке handle не принимается и отправляется отзыв; никакого бессрочного локального доступа не возникает. Локальный часовой контроль блокирует `/answer` и `/status` после истечения срока, даже если экран не менялся, а ответ, поступивший после истечения TTL, не отображается. UI binding дополнительно отзывает истёкший handle и не начинает новую сессию автоматически. Тесты покрывают прежние Lesson/Practice/Tours, нехватку TTL, истечение во время запроса и запрет повторных платных запросов. Всё только QA: серверная ревизия и ограничение времени остаются основным авторитетом, реальная UI-интеграция не опубликована. `main`, production Supabase, localStorage и прогресс учеников без изменений; Global AI NO-GO.

## 63. QA — безопасное время действия контекста (2026-10-14)

Проверка срока действия учебного контекста учитывает время начала сетевого запроса. Запоздалый ответ больше не продлевает локальный срок сверх исходного значения. При превышении срока или неправильном времени доступ отзывается без повторного запроса. Синтетические тесты охватывают длительную задержку и обратный ход часов. Production, аккаунты и учебные данные не менялись. Выпуск AI остаётся закрытым.


## 64. P6 QA — нативный Chromium и реальная структура маршрутов (2026-10-14)

Добавлен `qa/ai-layer-v21-p6-native-browser.cjs`, запускаемый в существующем offline GitHub Actions CI. Он читает **реальные названия экранов** из неизменных `app.js` и `index.html`, проверяет 17 вложенных Courses-разделов, строит **синтетический HTML** с теми же селекторами и исполняет действительные QA-модули `QaV21ScreenClient` и `QaV21AppScreenBinder` внутри настоящего headless Chromium на 320×568, 390×844, 1366×768. Проверяются Home→список предметов, переход в предмет и обязательный revoke общего контекста, Profile, наложение неизвестного экрана, истечение срока, logout и запрет последующих попыток AI. Отдельно тестируется **настоящий MutationObserver**, который сам обнаруживает изменение DOM и отзывает устаревший контекст. Тест не загружает production `app.js` и не подключается к Supabase, Vercel или AI-провайдеру; сеть в браузере ограничена инертным `data:` документом, никаких внешних запросов. Это проверка жизненного цикла на фактических именах экранов, **не** тест production UX или заявка на разрешение Preview.

## 65. P6 QA — реальный браузерный ответ после смены пользователя (2026-10-14)

В том же Chromium-контуре запущена асинхронная проверка: синтетический пользователь запрашивает подготовленный General Help, ответ остаётся ожидающим; выполняется logout, старый context отзывается, поздний ответ с маркером предыдущего аккаунта отклоняется; после повторного входа нового синтетического пользователя разрешён только отдельный новый handle. Тестируется реальный порядок событий браузера/промисов, без платного запроса или персональных данных. Ни один из тестов не активирует AI в production, не меняет `main`, рабочую Supabase, localStorage или Mathematics Exam Prep; действующие права/публикация контента остаются NO-GO.

## 66. P6 QA — браузерная проверка контекстов по RU / UZ / EN (2026-10-14)

Нативный Chromium выполняет изолированный маршрут для трёх языков: русский на 320×568, узбекский на 390×844 и английский на 1366×768. Для каждого языка отдельно проверяются отзыв при смене экранов, реальный MutationObserver и отклонение позднего подготовленного ответа после выхода ученика. Внешних сетевых запросов, обращения к рабочей базе и AI-провайдеру нет. Проверка охватывает поведение контекста, но не подтверждает публикацию редакционных текстов или реальную готовность Global AI. Production, main и данные учеников неизменны; выпуск остаётся NO-GO.


## 67. QA — отзыв полномочий при откате системного времени (2026-10-14)

Обнаружен пробел в QA транспортном клиенте: после получения 90-секундного handle `Date.now()` мог откатиться назад, а сравнение `now < expiresAtMs` снова продлило бы локальный срок. `qa/ai-layer-v21-ui-transport.cjs` теперь отслеживает последнее проверенное время и **навсегда закрывает текущий экземпляр клиента при откате, нецелочисленном значении или исключении часов**. Отдельные негативные проверки доказывают, что восстановление системного времени не возобновляет старый контекст, а `/answer` после отката не вызывается. Продуктовое время и серверная ревизия остаются более строгим источником полномочий; это дополнительная локальная защита.

## 68. QA — безопасный отказ при ошибке получения JWT (2026-10-14)

Ранее `readJwt()` вызывался за пределами `try/catch` в `authenticatedPost`, и исключение SDK могло создать необработанный rejected Promise. Получение JWT теперь защищено и возвращает только `authentication_required` без передачи внутренних исключений, логина, секрета или сетевого запроса `/answer`. Негативные тесты имитируют исключение до mint, при revoke и перед запросом ответа после успешного mint. Отзыв полномочий и блокировка предыдущего пользователя сохраняются.

## 69. P6 — редакционный лист 18 навигационных инструкций (2026-10-14; NO-GO)

Подготовлен `docs/iclub-ai-layer-p6-editorial-review-sheet-v2.1.md` из действующего чернового `qa/ai-layer-v21-p6-navigation-editorial-drafts.snapshot.json`: шесть реальных переходов приложения и точные RU/UZ/EN тексты, все **без переписывания**. Материал доступен для будущей человеческой проверки содержательной точности, локализации, доступности и прав; все решения о публикации оставлены неутверждёнными. Подготовка документа **не** выставляет release/rights/editorial flags и не создаёт `source_hash` в Supabase.

Home next-actions всё ещё не имеет подтверждённого кросс-предметного планировщика и утверждённых академических приоритетов. Ни одному ученику AI не открывается автоматически. Все §§67–69 выполняются в одной QA-ветке без изменения `main`, реального Supabase, данных учеников, localStorage, Mathematics Tutor, production UI, биллинга или Vercel. **Global AI: NO-GO**.

## 70. P6 — сверка Home с фактическими источниками данных (2026-10-14)

В режиме READ-ONLY сверены `renderHome`, `computeHomeCompetitiveStats`, `computeHomeStudyPracticeStats`, обработчики карточек и `renderSubjectHub` действующего `app.js`. Home получает данные выбранных предметов из локального профиля, использует кеширование и запасные значения при ошибках, а для Tours — календарное время браузера и несколько статусов попыток. Поэтому отображаемый процент и «нулевой» fallback не могут служить подтверждённым основанием AI-рекомендации. Наличие `guardStudy` и проверки активности в `renderSubjectHub` не позволяет утверждать, что переход с Home обходит коммерческую проверку. Подготовлена отдельная матрица допустимости трёх технических видов действий и необходимых подтверждений: `docs/iclub-ai-layer-p6-home-evidence-reconciliation-v2.1.md`. Решений о приоритетах за ученика не принято. Серверного планировщика Home нет, выпуск остаётся NO-GO, реальные данные и production не менялись.


## 71. P6 — защита от использования визуальных показателей Home как AI-доказательств (2026-10-14; QA ONLY)

После фактической сверки §70 добавлен `qa/ai-layer-v21-p6-home-source-drift.test.cjs`: независимая автоматическая проверка текущих Home display sources, которая требует повторного аудита при изменении смешанных статусов `submitted/time_expired/anti_cheat`, локального календаря устройства, нулевого fallback, выбора закреплённых предметов или проверок доступа в Subject Hub. Отдельные отрицательные мутации доказывают, что такое изменение не проходит бесшумно. Тест включён в offline Node runner и QA GitHub Actions. **Успешный тест подтверждает границу доверия, а не истинность показанного процента и не право AI рекомендовать следующий шаг.**

Home next-actions остаётся без серверного планировщика, одобренной учебной политики приоритетов, независимого owner-bound evidence и редакционно опубликованных RU/UZ/EN источников. 18 инструкций General Help остаются черновиком. Отдельного разрешения на beta/release нет. Документ с точными условиями: `docs/iclub-ai-layer-p6-home-source-drift-gate-v2.1.md`. Все изменения только в QA-ветке; `main`, production, Supabase, локальные данные, Mathematics Tutor, Vercel и provider/billing не затрагивались. **Global AI — NO-GO.**


## 72. P6 — запрет отправки устаревшего AI-запроса после ожидания JWT (2026-10-14; QA ONLY)

Проверка синтетического `qa/ai-layer-v21-ui-transport.cjs` обнаружила, что после асинхронного `readJwt()` потенциально устаревший `/context` или `/answer` всё ещё мог быть отправлен до последующей проверки смены экрана/аккаунта. Добавлена повторная предсетевая проверка `epoch`, актуального context handle и 90-секундного срока; долгий JWT mint отказывается без обращения к Edge. Отложенные ответы по-прежнему отдельно отвергаются **после** обращения. Новые синтетические тесты охватывают logout, смену экрана, истечение lease и позднее получение JWT; `qa/ai-layer-v21-ui-transport.test.cjs` уже входит в offline QA. Это защита от лишней отправки/потенциального расхода и не заменяет backend owner/access/assessment/usage guards.

Файл отчёта: `docs/iclub-ai-layer-p6-jwt-dispatch-race-v2.1.md`. Полный CI GREEN не заявлен без подтверждённого результата. `main`, production, Supabase, student data, localStorage, работающий Mathematics Tutor, Vercel/Preview, provider и billing не изменены. General Help RU/UZ/EN и Home next-actions по-прежнему требуют отдельных утверждений. **Global AI — NO-GO.**


## 73. P6 — независимая проверка RU/UZ/EN инструкций и доступных названий (2026-10-14; QA ONLY)

Проверены все 18 черновых General Help instructions (шесть реальных маршрутов × три языка) с исходными `index.html`, `app.js`, `i18n.js`. Буквальные RU/UZ/EN подписи внутри черновых инструкций соответствуют реальным видимым названиям кнопок. Для английского «О проекте» сохранена точная кнопка **About project**, а не заголовок страницы **About**. Исходные 18 текстов не переписаны и не утверждены.

В реальных четырёх кнопках нижнего меню выявлена отдельная проблема доступности: `aria-label` остаётся буквальным английским, хотя видимый текст берётся из локализации. Зафиксировано **9 расхождений** (4 RU, 4 UZ, 1 EN: Study ↔ Courses), а контейнер нижней навигации подписан `Bottom navigation`. Это проверка исходников, не фактический screen-reader тест. Новые `qa/ai-layer-v21-p6-navigation-semantic-review.cjs` и `.test.cjs` обеспечивают независимый редакционный gate: 18 кандидатных текстов, семантические отрицательные мутации, запись доступных названий и неизменный `NO_GO` без человеческого sign-off. Они включены в существующий QA-only offline runner и workflow. Подробная таблица и review blockers: `docs/iclub-ai-layer-p6-navigation-locale-a11y-review-v2.1.md`.

Исправления legacy `aria-label`, публикация General Help, новый Home planner, runtime/provider и cohort включение **не производились**. Перед релизом требуется отдельная редакционная/доступностная проверка всех языков и прав, независимая повторная проверка источника/version/hash, фактический keyboard/screen-reader QA и отдельный GO архитектора. Полный CI GREEN не заявлен без результата GitHub Actions. `main`, production, реальная Supabase, пользовательские данные/localStorage, Mathematics Tutor, платежи и Vercel не изменены. **Global AI — NO-GO.**


## 74. P6 — доступные подписи нижней навигации без изменения production HTML (2026-10-14; QA ONLY)

На основе подтверждённых 9 конфликтов §73 сделан **строго изолированный** вариант исправления: `qa/ai-layer-v21-p6-nav-a11y-preview.cjs` создаёт только копию действующего `index.html` в памяти и удаляет ровно четыре статических `aria-label` нижних кнопок. Родные видимые `span.tab-txt[data-i18n]` вместе с `aria-hidden` иконками становятся источником озвучиваемого названия. В реальном исходнике меняются только 4 подстроки суммарно на 81 символ, вне `tabbar` содержимое неизменно. В прямой source-сверке текущий код имел 9 разночтений, вариант Preview — 0, все 18 редакционных инструкций продолжают совпадать с UI; **это не approval**. QA reviewer принимает оба режима, но всегда возвращает `NO_GO` без независимой проверки.

Добавлены негативные unit-тесты изменения селекторов/перевода и нативный Chromium QA `qa/ai-layer-v21-p6-nav-a11y-browser.cjs` (320×568 RU, 390×844 UZ, 1366×768 EN, Chrome accessibility tree, keyboard focus, clipping, запрет внешних обращений). Скрипт подключён к QA-only GitHub Actions; полный итог Actions отдельно не подтверждён. Независимый локальный Chromium эксперимент подтвердил доступные названия этих четырёх кнопок во всех трёх языках на перечисленных размерах, но это не эквивалент полноценного workflow/реального screen-reader QA. `aria-label="Bottom navigation"` у самой нижней панели пока **не локализован** и подлежит отдельному редакционному решению. Документ: `docs/iclub-ai-layer-p6-accessible-nav-preview-v2.1.md`.

Ни один исходный `index.html`, `app.js`, `i18n.js`, учебные модули и legacy состояния не менялись. Не было Supabase/Vercel/provider/billing операций или реальных ученических запросов. Следующий блок — единый QA release preflight для General Help с явно незакрытыми редакционными и accessibility gates. **Global AI — NO-GO.**


## 75. P6 — единый редакционный и accessibility preflight без права релиза (2026-10-14; QA ONLY)

Существующий безопасный `qa/ai-layer-v21-p6-release-preflight.cjs` расширен сквозной проверкой шести маршрутов и 18 черновых RU/UZ/EN инструкций по исходникам приложения, плюс повторной проверкой §74 accessible-name кандидата. Реальный source-audit: 18 согласованных черновых инструкций, 9 расхождений доступных имен в неизменном интерфейсе, 0 расхождений в отделённом QA-кандидате. **Это не готовая локализация всей нижней панели:** `Bottom navigation` остаётся английской подписью landmark, и настоящий assistive-tech QA, редакционное/правовое подтверждение не пройдены. Возврат preflight **всегда `NO_GO`**, публикация/деплой/платный вызов не осуществляются. Новые поля проверяются автоматическими регрессиями, а review-документы §74/§75 добавлены в QA-only workflow. Отчёт: `docs/iclub-ai-layer-p6-unified-release-preflight-v2.1.md`.

Архитектурный блокировщик Home next-actions не разрешён без решения владельца о допустимых педагогических действиях и приоритетах; редакционные RU/UZ/EN инструкции не опубликованы; Global AI не внедрён в реальный production UI/Edge. Переход к Preview/beta невозможен без нового полного CI, server-owned источников/прав, cohort и явного GO. Вся работа сохранена только в `qa/iclub-ai-layer-v21-20261012`; рабочие `main/index.html/app.js/i18n.js`, Math Tutor, Supabase, данные пользователей и localStorage не затрагивались. **Global AI — NO-GO.**


## 76. Единый итог QA-кандидата и предел самостоятельного выпуска (2026-10-14; без production)

После §§74–75 составлена единая итоговая матрица R1–R8 без автоматического GO: `docs/iclub-ai-layer-v21-end-to-end-release-boundary-20261014.md`. Академические и защитные QA-контракты P1/P5, Practice/Tours, current-screen JWT/revoke, синтетические тарифы и международные локали подготовлены, но их создание **не означает установленные production RPC, опубликованные редакционные источники, оплаченный провайдер или разрешённую cohort beta**. Home next-actions требует решения архитектора о значении/приоритетах учебных действий и серверного доказательства; 18 навигационных текстов требуют независимого редакционного/правового заключения; нижняя landmark подпись и реальное screen-reader QA не закрыты. Финальная коммерческая политика остаётся тестовой 1:3, отдельный GO обязателен.

Последняя сверка ветки с исходным production SHA `9afc7b44aead03b2a30544e6e7d4c4eb8670efbf` не нашла изменений защищённых `app.js/index.html/i18n.js/style.css`, `exam-prep/`, `supabase/migrations/`, Tutor Edge. Автоматические Node/Deno/PostgreSQL/Chromium tests включены в QA CI, но **полное подтверждение последнего успешного run не получено**, поэтому общий verdict остаётся `NO_GO`. Продолжение после этой границы может требовать новых production-like интеграций, прав контента или отдельных разрешений; запрещено обходить их ради формального завершения этапа. Реальные пользовательские данные, локальные прогрессы, legacy Mathematics Tutor, Vercel production и платные обращения не менялись.


## 77. Три продуктовых решения архитектора утверждены для QA/Preview, но не для production (2026-10-14)

Получено явное согласование: (1) точные 18 RU/UZ/EN текстов навигации как продуктового варианта; (2) доступные имена нижнего меню, совпадающие с переведёнными видимыми названиями кнопок, и `Нижнее меню / Pastki menyu / Bottom navigation`; (3) порядок Home **разбор завершённой Practice → открытый архив Tour → продолжение доступного предмета**, только по подтверждённой сервером информации. Согласование относится к дальнейшей технической работе без остановки на каждом этапе, **не** разрешает production/Supabase/localStorage writes, реальные платные вызовы, cohort beta или автоматическую публикацию редакционных источников.

Утверждения зафиксированы отдельно от release flags в `qa/ai-layer-v21-owner-product-decisions-20261014.json`. Одобрение 18 конкретных текстов закреплено на Git blob `ab94d7ca03bbdf521acc95dedafd0dba43c45f7e`; изменение исходного черновика требует нового product review. `qa/ai-layer-v21-owner-product-gate.cjs` проверяет привязку, не подменяя независимую экспертизу прав и source publication.

## 78. Серверно подтверждённый приоритет Home без выдуманных предметных рекомендаций (2026-10-14; QA ONLY)

В `qa/ai-layer-v21-p6-home-next-action-proof.cjs` добавлен узкий доверенный handoff: только после штатной проверки JWT-владельца, текущего Home, 90-секундного handle, неизменного snapshot, независимых академических подтверждений, актуальных locale/source и вторичной проверки отзывов источников он может выдать минимальный набор идентификаторов и типов действий. Для включения утверждённого порядка необходимы **подписанная полнота проверки всех трёх категорий и точная версия policy**; отсутствие, неверная версия, неполное покрытие или изменение источника — отказ, не выдуманный fallback.

`qa/ai-layer-v21-p6-home-approved-priority.cjs` применяет только утверждённый порядок. При двух одинаково приоритетных допустимых предметах возвращает `selection_required`, не ранжирует предметы скрыто. Без подтверждённых данных возвращает `in_development`. Синтетические тесты проверяют positive и отрицательные маршруты, владельца, TTL, редакционную блокировку, изменения plan/evidence и tie. **Рабочий серверный cross-subject planner не установлен;** реальные Home-рекомендации пока закрыты.

## 79. Утверждённая локализация доступных названий навигации (2026-10-14; QA ONLY)

Изолированный `qa/ai-layer-v21-p6-nav-approved-locale.cjs` применяет подтверждённые RU/UZ/EN названия нижней панели только к копии HTML в памяти; сохраняет четыре натуральных локализованных текстовых имени кнопок без конфликтующих английских `aria-label`. Отдельный QA helper допускает обновление имени панели при смене языка, но НЕ подключается к текущему `app.js`. Тест проверяет три локали, отказ при DOM drift и отсутствие изменения legacy `index.html`; реальный Chromium QA теперь проверяет также локализованную роль `navigation`. Это продуктово одобренный **Preview-кандидат**, не production patch.

## 80. Единый preflight: одобрена продуктовая логика, права/публикация/реальная beta закрыты (2026-10-14)

`qa/ai-layer-v21-p6-release-preflight.cjs` отображает принятые решения и отдельно проверяет три языка, но сохраняет `NO_GO`, `NOT_EDITORIALLY_PUBLISHED`, отсутствие реального server-owned Home planner, live RPC и разрешения cohort/payment. Новый checkpoint: `docs/iclub-ai-layer-owner-approved-qa-next-actions-20261014.md`. Node-кандидаты внесены в offline runner и QA workflow; актуальный полный CI GREEN ещё требует фактического подтверждения. Изменения ограничены `qa/iclub-ai-layer-v21-20261012` и документами, без deploy/production/main/живой Supabase/ученических записей. **Global AI: NO-GO до отдельных технических/правовых release gates и явного разрешения архитектора.**


## 81. Независимый QA smoke утверждённой продуктовой логики и сохранности (2026-10-14; NO-GO)

Прямое исполнение действительных QA-модулей `qa/ai-layer-v21-p6-home-next-action-proof.cjs` и `qa/ai-layer-v21-p6-home-approved-priority.cjs` в изолированном V8 с синтетическими серверными reader-функциями дало **9 положительных маршрутов и 15 корректно заблокированных отрицательных**: Practice раньше Tour/продолжения, Tour раньше продолжения, неоднозначные одноранговые предметы без произвольного выбора, отсутствующее полное coverage, устаревшая/чужая authority, revoked source и неподтверждённые академические записи. Аналогичный сквозной синтетический вызов существующего `qa/ai-layer-v21-p6-release-preflight.cjs` вернул `NO_GO` с зафиксированными owner product approvals и отдельно отсутствующими source publication, реальным planner/entitlement и cohort. Это smoke на макетных services, **не** тест реальной Supabase и не итог Node/Deno/PostgreSQL/Chromium CI.

Побайтовые Git blob SHA уже существовавших `global-ai-ui.js`, `app.js`, `index.html`, `i18n.js`, `style.css` совпали с исходным QA checkpoint `c565f9a8d70ceeb791137bec36e5bf1f2e21de4c`: нынешняя работа не меняла рабочие исходники. `global-ai-ui.js` имел отдельные исторические различия QA-ветки с production baseline **до** данного этапа, потому не объявляется равным production; приложение не деплоилось. В workflow protection добавлены `i18n.js` и `style.css`. Точный результат последнего полного GitHub Actions не доступен через проверенный status endpoint, поэтому общий CI/Global AI: **NO-GO**. Продолжать только независимую реализацию подписанного read-only server planner, editorial rights/version/hash release и защищённый Preview после технических допусков; реальная beta/provider/production остаются за отдельным GO владельца.


## 82. Home: отдельное серверное перечисление реальных Practice/Tours/предметов (2026-10-14; SCRATCH ONLY)

Добавлен отдельный read-only SQL-кандидат `qa/sql_drafts/iclub_ai_v21_home_scan_scratch_UNAPPLIED.sql`. Он опирается на реальные формы таблиц, проверяет текущий server-owned Home handle, владельца, активный предмет, завершённость Practice и неправильные ответы, финализацию Tour и истечение его даты по Asia/Tashkent; результат не содержит оценок и ответов. Дополнительно блокирует активный экзамен, чужие контексты, отозванные права и слишком много равноранговых вариантов. Установка и исполнение жёстко ограничены БД с `iclub_ai_v21_scratch_*`. **Это НЕ работающий production/Home planner**: право коммерческого доступа в нём пока представлено явно синтетической записью, реальная подписанная полная серверная политика/источники не опубликованы.

## 83. Дополнительный PostgreSQL suite Home (2026-10-14)

`qa/sql_drafts/iclub_ai_v21_home_scan_local_pg.psql` создаёт одноразовые синтетические записи и тестирует owner, completed/active Practice, открытый/закрытый/anti-cheat Tour, protected exam и revoke. Suite `home` добавлен в `qa/run-ai-layer-v21-postgres-local.sh` и в GitHub Actions (теперь 14 scratch suites). Данные сверяются только после запуска настоящего PostgreSQL. Локального установленного PostgreSQL в текущем execution-контуре нет, полный CI GREEN пока не получен.

## 84. Одобренные 18 текстов как immutable QA-only пакет, НЕ production publication (2026-10-14)

`qa/ai-layer-v21-p6-approved-copy-bundle.cjs` связывает тексты с конкретным согласованным Git blob SHA, отклоняет любое незаявленное редактирование и выдаёт отдельные `ru/uz/en` тексты без каких-либо `rightsApproved`, `globalAiSourcePublished`, provider permissions. Даже продуктовое одобрение НЕ заменяет независимый редакционно-правовой release source/hash/version.

## 85. Реальный изолированный Vercel Preview с синтетическим UI (2026-10-14)

Создано Preview-развёртывание `dpl_BswWrQATQYEL86vEAxaECgQhs27r` на `https://i-club-8ikby7smn-jasurbeks-projects-c5451f97.vercel.app`; Vercel вернул `READY`, `target=null`, `alias=[]`. В deployment inventory только один статический `index.html` из `qa/preview_v21` (не production приложение); `connect-src 'none'`, никаких сетевых API, Supabase, локальных записей или AI provider. Для Preview-показа UI нужны SSO полномочия; внешняя неавторизованная проверка страницы пока не пройдена. Настоящий единый UI+Edge+Supabase ещё не интегрирован.

## 86. Release/CI граница после Preview (2026-10-14)

Node copy/preview tests, 14-й PostgreSQL suite и QA Vercel Preview добавлены только в изолированный контур. GitHub Actions результат полного запуска не удалось получить через доступные GitHub функции; отсутствие PR-run и commit statuses не равно GREEN. Дальнейший реальный release требует законного governed-source publishing в отдельной непроизводственной БД, реализации owner-scoped commercial authority, целостной серверной подписи Home плана, end-to-end интеграции и полного GREEN оригинального Mathematics Tutor + всех UI/PG/Deno tests. Подробный фактологический отчёт: `docs/iclub-ai-layer-qa-home-preview-ci-handoff-20261014.md`. **Production/Main/Supabase/ученики/локальные данные/платные вызовы без изменений, Global AI — NO-GO.**


## 87. Проверяемый полный QA CI впервые получен (2026-10-14; GREEN для зафиксированного commit)

Для получения фактических логов создан исключительно QA→QA черновой PR [#342](https://github.com/jteshaboev1984-ops/iClub_APP/pull/342), не связанный с `main`. Из первоначального workflow #203 выявлены две реальные ошибки тестов; обе устранены без ослабления auth/academic protection. [GitHub Actions #206](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38589514037) вернул **GREEN**: 619/619 Node, Chromium, Deno TypeScript + regression, 14 PostgreSQL scratch suites включая Home, две параллельные гонки и проверка защищённых файлов. Ранее из-за ограничения PR-only GitHub connector полный CI ошибочно был «неподтверждён»; теперь есть прямые логи и URL.

## 88. Подписанный read-only Home plan: независимые owner/evidence/source gates (2026-10-14; QA ONLY)

`qa/ai-layer-v21-p6-home-signed-server-bridge.cjs` реализует независимый серверный кандидат: проверяет owner-bound Home, exact plan version/complete scan, ограниченный TTL и неизменность SQL scanner после `await`; требует отдельный академический proof, коммерческое разрешение для каждого действия и отдельный published rights-approved locale source; только после повторной проверки предметных прав подписывает минимальный plan с server-only HMAC. Изменённые source/subject данные не могут сохранять прежнюю подпись. QA тест вызывает этот модуль вместе с существующим `QAHomeNextActionProof` и утверждённым приоритетом. Все успешные сценарии используют синтетические independently mocked server services, а не публикацию неутверждённых источников в реальную базу. **Это пока не deployed Supabase/Edge функция.**

## 89. Обязательная разница между legacy разрешением и реальными AI-правами (2026-10-14)

READ-ONLY проверкой сигнатуры и определения `public.get_iclub_subject_access_guard_service_v1(uuid,text,text)` подтверждено: `allowed=true` может сопровождаться переходным режимом `shadow` или `legacy_passthrough`, а `select_competitive` проверяет место, не факт реального выбора предмета. Существующий клиентский `commercial-access-ui.js` тоже не может быть самостоятельным AI-разрешением при ошибке RPC. В §88 добавлена обязательная форма полного service-bound access proof (пользователь, предмет, разрешённый intent, версия, проверенный commercial/grandfathered, отдельная competitive selection). Shadow/passthrough и отсутствие этой формы fail closed. Production права и тарифы не менялись. Переход к реальному Edge требует заверенной серверной реализации этой формы, не клиентского bool-флага.

## 90. Chromium cleanup и второй полный Green (2026-10-14)

Run #209 успешно прошёл обновлённые Node-тесты, но затем упал после успешных трёх локалей Chromium на `ENOTEMPTY` при удалении временного профиля. В `qa/ai-layer-v21-p6-nav-a11y-browser.cjs` добавлено ожидание завершения Chrome и ограниченная повторная очистка каталога (настоящие a11y asserts сохранены). [GitHub Actions #211](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38590672176) затем завершился **GREEN** для тех изменений. Важно: §89 добавлен после фиксации соответствующего PR merge commit; его итог отдельно должен быть подтверждён следующим CI, а не подставлен под успешную историю #211.

## 91. Текущая граница выпуска после real CI

Доказательство: `docs/iclub-ai-layer-p6-signed-home-ci-proof-20261014.md`. Архитектура и QA тесты продвинулись, но настоящее коммерческое разрешение на новый AI, rights/source publication, production-grade atomic Home planner, реальная интеграция Vercel Preview + независимая Supabase и разрешение beta/provider/live migration отсутствуют. Общий **Global AI NO-GO**, даже если очередной offline CI GREEN. `main`, действующая Supabase, пользовательский прогресс, Mathematics Tutor и production домены не затронуты.


## 92. Offline QA без новой платной Supabase-ветки (2026-10-15)

Архитектор прямо отказался от создания отдельной Supabase development branch. Запрет зафиксирован в `docs/iclub-ai-layer-zero-new-supabase-branch-v2.1-20261015.md`. Дальнейшая работа использует **только уже существующие** QA GitHub, изолированный синтетический PostgreSQL внутри CI, Node/Deno, Chromium и ранее созданный статический защищённый Vercel Preview. Production Supabase допускает только разрешённый метаданный аудит схемы, **не** чтение записей пользователей, не временные таблицы, не миграции и не транзакционные тестовые записи. Новые проекты/ветки Supabase и billing не создавались.

## 93. Реальный режим предмета и повторная проверка оснований Home (2026-10-15)

Сканер `qa/sql_drafts/iclub_ai_v21_home_scan_scratch_UNAPPLIED.sql` теперь учитывает поле `user_subjects.mode`: `study` для завершённой Practice и продолжения предмета, `competitive` для официально открытого архива Tour. Внутри **исключительно синтетического scratch** доступ к предмету привязан к тройке `owner/subject/intent`, а не ко всем предметам пользователя сразу. Тесты PostgreSQL `qa/sql_drafts/iclub_ai_v21_home_scan_local_pg.psql` проверяют смену режима, отзыв одного разрешения, сохранение другого разрешённого предмета и полный fail-closed при отсутствии прав. Это **не реальная коммерческая authorization service**; действующая Supabase не менялась.

В `qa/ai-layer-v21-p6-home-signed-server-bridge.cjs` перед подписью плана повторно запрашиваются **академические доказательства**, **rights/content/source hash/version** для каждой записи и **полный server-owned screen + scan** после всех асинхронных операций. Изменение источника, отмена академического подтверждения, смена владельца или экрана приводит к отказу. Добавлены адресные отрицательные тесты.

## 94. Подтверждённый полный CI для §92–§93 (2026-10-15)

В изолированном QA→QA запуске [GitHub Actions #221](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38679111813) подтверждено **GREEN**: **628/628 Node**, **14/14 disposable PostgreSQL**, Chromium/мобильная навигация RU/UZ/EN, Deno + Edge contract, конкурентные транзакции, проверка неизменности `app.js/index.html/i18n.js/style.css` и существующего Exam Prep. По сравнению с исходным production baseline ни один защищённый файл не изменён. CI GREEN относится только к offline QA candidate, а не к реальному Supabase+Edge+AI rollout.

**Global AI по-прежнему NO-GO.** Без нового Supabase branch продолжаются offline проверки и подготовка независимого QA release candidate; никакие утверждённые продуктовые тексты не объявляются редакционно опубликованными, AI не тратит средства, реальная beta не открывается. Реальный интегрированный Preview нельзя объявить доказанным на основании статического Vercel Preview или синтетического PostgreSQL.


## 95. Зафиксирована защита существующей AI-оболочки и тарифной логики (2026-10-15)

При source-сверке выявлено, что `global-ai-ui.js` в QA (`023516d2127a838f8b12b398215745304fe11d9e`) исторически **не совпадает** с production (`001e90f8b5e02b3b6d828c3958c9de24356dc814`). Аналогично рабочие commercial UI-файлы нельзя переопределять в рамках отдельного AI-проекта. Для предотвращения регрессии в GitHub Actions добавлен **дополнительный** независимый diff-контроль `global-ai-ui.js`, `commercial-access-ui.js` и `plans-ui.js` против ранее проверенного QA-baseline commit `c565f9a8d70ceeb791137bec36e5bf1f2e21de4c`. Прежний контроль production-базиса для `app.js/index.html/i18n.js/style.css`, Exam Prep и миграций сохранён. Таким образом, CI не путает старые QA-отличия с новым изменением и не выпускает случайно исправленную в другом проекте оболочку.

[GitHub Actions #225](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38679463759) завершился **GREEN** после этой защиты: **628/628 Node**, **14/14 scratch PostgreSQL**, Chromium, Deno, parallel/monetary race и оба независимых file-drift gates. Это подтверждение **текущего QA-кандидата**, а не реального Supabase, платного провайдера или production выпуска. Вспомогательный QA→QA PR #342 закрывается **без слияния**. Новая Supabase branch не создавалась по прямому запрету архитектора. **Global AI: NO-GO** для учеников до отдельного GO.


## 96. Реальный изолированный HTTP → PostgreSQL → подписанный Home (2026-10-15; QA ONLY)

В `qa/ai-layer-v21-p6-home-pg-http-gateway.cjs` реализован отдельный **локальный**, строго привязанный к `127.0.0.1` HTTP-обработчик со структурным контролем POST/origin/token/body и запрещённым клиентским `userId`. Временно созданная PostgreSQL 16 `iclub_ai_v21_scratch_ci_home_http` получает синтетические учебные записи из `qa/sql_drafts/iclub_ai_v21_home_http_fixture_local_pg.psql`. В этом контуре проходят настоящий scratch SQL Home scanner, режимы study/competitive, повторные независимые проверки учебных evidence, отдельный source governance (только synthetic releases), HMAC подпись и owner-approved Home priority. Клиенту передаётся только тип допустимого действия или список равноприоритетных вариантов, без баллов, ответов, авторизационных секретов и академических записей. Ни один из этих файлом не подключается к действующему приложению/Edge/Supabase.

`qa/ai-layer-v21-p6-home-pg-http.test.cjs` проверяет RU/UZ/EN, владельца, чужой аккаунт, смену режима, уже завершённую Practice, открытый Tour, отсутствие произвольного выбора предмета, отказ после отзыва прав и экрана. Новая локальная Chromium-страница `qa/preview_v21/home-pg-local.html` реально вызывает локальный HTTP, а `qa/ai-layer-v21-p6-home-pg-chromium.cjs` проверяет 320×568 RU, 390×844 UZ, 1366×768 EN, состояние кнопок, отсутствие горизонтального выхода и запросов за пределы localhost. Это **не** Vercel deployment. Получен [полный GREEN #236](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38680967823): прежние 628/628 Node, 14/14 PostgreSQL, native Chromium/Deno/parity, новый localhost Home Chromium и HTTP Node e2e PASS.

## 97. Найден и закрыт форматный баг серверного PG→JS чтения (2026-10-15)

Первый настоящий HTTP e2e обнаружил, что `PostgreSQL EXISTS(...)::text` возвращает строку `true`, а синтетический QA gateway ошибочно сравнивал с `t` из традиционного psql-формата boolean. Это блокировало даже валидный Home request (fail closed). Исправлен **только** тестовый адаптер, ограничения чужого владельца/источника не ослаблены. Полный GREEN #236 подтверждает корректность исправления.

## 98. Source governance в настоящем scratch PostgreSQL вместо фиксированного разрешения (2026-10-15; NO-GO for live)

После #236 убран фиксированный ответ `ready:true` для источников в локальном gateway. Отдельная **синтетическая** scratch PostgreSQL таблица содержит 12 записей RU/UZ/EN × action/subject, со своим 64-hex отпечатком, состояниями `rights_approved`, `content_approved` и `revoked_at`. Сервер читает эти записи при каждом evidence cycle. HTTP-тест дополнен реальным изменением `revoked_at` и отзывом `rights_approved`: подпись и рекомендация должны блокироваться без доступного опубликованного источника. Эти synthetic source rows **не означают фактических прав на реальные учебники или независимого редакционного утверждения**; 18 инструкций General Help ранее получили лишь продуктовое одобрение. После выявленной ошибки автоматической вставки SQL и полной пересборки scratch fixture получен [GitHub Actions #245](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38681529131) — **GREEN**: 628/628 Node, 14/14 PG, localhost Home HTTP/Chromium RU/UZ/EN и реальные synthetic source revocation/rights проверены.

Все SQL-схемы `*_UNAPPLIED.sql` ограничены одноразовым scratch DB. Создание новой Supabase-ветки явно запрещено архитектором, production/Supabase real rows, localStorage, Exam Prep и платный provider не затрагиваются. **Global AI: NO-GO для учеников**, несмотря на успешный scratch E2E.


## 99. Итог полного локального end-to-end Home и source governance (2026-10-15)

`qa/sql_drafts/iclub_ai_v21_home_http_fixture_local_pg.psql` теперь действительно создаёт **12 независимых** синтетических source records (RU/UZ/EN × action/subject) с отличающимися 64-hex digest, rights/content flags и emergency revoke; раньше source release для HTTP проверялся жёстко запрограммированным `ready:true`. Gateway читает настоящее состояние этих таблиц в одноразовой PostgreSQL, при `revoked_at` и `rights_approved=false` подписанный план и HTTP-рекомендация становятся недоступны, после восстановленного synthetic разрешения путь снова валиден. Ошибка генерации файла из-за интерпретации комбинации `$'` в строковой замене была обнаружена выполнением SQL и устранена пересборкой fixture из исходного ранее проверенного PG набора, без ослабления проверок.

[Actions #245](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38681529131): **GREEN** всех существующих проверок (Node 628/628, PostgreSQL 14/14, Deno, обычный Chromium, два concurrent race набора) и дополнительного end-to-end Chromium→HTTP→PostgreSQL→signed Home в RU/UZ/EN плюс тест отзыва источника. Артефакты подробно: `docs/iclub-ai-layer-home-real-http-pg-chromium-qa-20261015.md`.

**Важное разграничение:** этот новый путь технически интегрирован в локальном disposable QA, а не в рабочем iClub APP. Это не запуск реальной Supabase-авторизации, не подтверждение реальных академических прав, не выпуск source-пакета, не подключение коммерческого AI и не разрешение beta. Существующий защищённый Vercel Preview остаётся статическим, новый HTTP Preview запускается только внутри CI. Production, `main`, Supabase, пользовательский прогресс, Mathematics Tutor, тарифные файлы и домены не изменяются. Отдельная Supabase-ветка запрещена архитектором и **не создавалась**. **Global AI — NO-GO для реальных учеников.**


## 100. Аудит фактических тарифных правил iClub без чтения данных учеников (2026-10-15)

READ-ONLY просмотрены определения действующих `public.get_iclub_subject_access_guard_service_v1(uuid,text,text)`, `public.get_iclub_subscription_capabilities_service_v1(uuid)` и структуры `private.iclub_commercial_access_config`, `private.iclub_subject_slot_selections`, `public.user_subjects`, `public.subjects`. Настоящая guard-функция допускает `allowed=true` даже при `shadow`/`legacy_passthrough` и для grandfathered-совместимости; `select_competitive` доказывает свободный слот, но не совершённый выбор предмета. `capabilities.ai_generation_entitled` подтверждает только право тарифа, не отдельное GO на новый AI. Изменять эти функции запрещено: они обслуживают реальных пользователей и старый доступ.

## 101. Реальный по форме тарифный контракт в изолированной PostgreSQL + сквозной Home (2026-10-15)

Созданы `qa/ai-layer-v21-p6-commercial-contract-adapter.cjs` с негативными тестами и `qa/sql_drafts/iclub_ai_v21_commercial_contract_fixture_local_pg.psql`, воспроизводящий **только в одноразовой PostgreSQL** серверный `guard(open)`, подписку и сохранённый выбор предмета. Новый адаптер требует одновременно: `subject_limits_mode=enforced`, snapshot complete, guard commercial с reason `subject_selected`/`plan_all_subjects`, `resolved=true`, `ai_generation_entitled=true`, реальное owner/subject/mode, активный предмет, `study_selected`, отдельный `competitive_selected` для Tour и независимый **QA-only** AI feature gate. Shadow/passthrough/grandfathered автоматически **NO-GO** для нового AI. Путь `qa/ai-layer-v21-p6-home-pg-http-gateway.cjs` перестал выдавать фиктивный `mode=commercial,allowed=true` без тарифного подтверждения — читает единый scoped snapshot из synthetic PG.

Сканер Home теперь проверяет действительные выбранные subject slots **до определения приоритета**, поэтому недоступная Practice/Tour не скрывает подтверждённый другой предмет. В PG-тестах проверены выключенный тарифный AI entitlement, отзыв отдельного AI feature gate, `shadow`, `off`, неверные или отсутствующие study/competitive selection и восстановление валидного доступа. Никаких реальных entitlements, production конфигураций или предметов пользователей не читали и не меняли.

## 102. Подтверждённый интеграционный CI и контроль изменения серверного контракта (2026-10-15)

[Actions #258](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38683473859): **GREEN**, 635/635 Node, 14/14 независимых PostgreSQL scratch suites, native Chromium RU/UZ/EN, реальная локальная цепочка Home→HTTP→PG commercial snapshot→signed Home→browser, Deno Edge и обе конкурентные гонки. Первое тестовое окружение не содержало `private.iclub_subject_slot_selections` во второй (HTTP) базе; после фиксации общего DDL в обеих одноразовых базах полный CI прошёл. Точная база отпечатков **существующего определения**: `get_iclub_subject_access_guard_service_v1` — `bb0c27de3665e5c6e16810044b1316a5`; `get_iclub_subscription_capabilities_service_v1` — `58bfe7eaf0c54a8e74d50bbf79416684` по `md5(pg_get_functiondef(...))`. Изменение исходных серверных функций после этого аудита требует нового анализа, не молчаливого доверия старым тестам. Подробно: `docs/iclub-ai-layer-p6-live-commercial-contract-audit-20261015.md`.

**Общий Global AI NO-GO.** Для настоящего выпуска всё ещё не выполнены реальный серверный rollout/owner proof, отдельная академическая source rights-публикация, реальный интегрированный Edge+Supabase Preview и разрешение архитектора. Это проверка совместимости текущей архитектуры на **локальных synthetic contracts**, не работа реальных пользователей. Production `main`, Supabase, Mathematics Tutor, тарифы, сертификаты, student progress и платные AI-запросы без изменений. Запрещённая новая Supabase-ветка не создавалась.


## 103. Версионированный read-only контроль коммерческого контракта (2026-10-15)

Отдельным **read-only** запросом `md5(pg_get_functiondef(...))` действующей Supabase (метаданные `pg_proc` и имена аргументов, **не** таблицы учеников) закреплены две исходные функции: `public.get_iclub_subject_access_guard_service_v1(uuid,text,text)` = `bb0c27de3665e5c6e16810044b1316a5`, `public.get_iclub_subscription_capabilities_service_v1(uuid)` = `58bfe7eaf0c54a8e74d50bbf79416684`. Данные сохранены в `qa/ai-layer-v21-p6-live-commercial-catalog-snapshot.json`. Чистый `SELECT` для будущей независимой сверки — `qa/sql_drafts/iclub_ai_v21_commercial_pg_proc_READ_ONLY.sql`; секретов, пользовательских записей, DDL и записей БД нет.

`qa/ai-layer-v21-p6-commercial-catalog-drift.cjs` возвращает только `matched:true, releaseAllowed:false` при точном совпадении двух сигнатур и hash. Отсутствие функции, новая версия, чужой параметр/схема, дубли и неполный результат возвращают **NO-GO**. Это проверка **предоставленного доверенным read-only источником** каталога; CI не подключается к production и не претендует на самостоятельную автоматическую проверку live Supabase. При будущей интеграции повторный метаданный аудит и независимый feature/source/owner-GO обязательны.

[GitHub Actions #263](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38683948146) — **полный GREEN** нового snapshot/gate: **638/638 Node**, **14/14 PG scratch**, реальный localhost Chromium→HTTP→signed Home через disposable DB RU/UZ/EN, Deno, race и protected-file drift. Это **только QA**. Production/main/реальные данные/тарифы/Mathematics Tutor/локальный прогресс/платные запросы не менялись; отдельная Supabase ветка не создавалась. Global AI **NO-GO** до разрешения полноценного выпуска.


## 104. Последний Home HTTP-gate после принятого приоритета (2026-10-15; QA ONLY)

Отдельный `qa/ai-layer-v21-p6-home-delivery-gate.cjs` блокирует выдачу уже подписанной рекомендации, если после `buildHomePlan` и `QAHomeApprovedPriority.choose` текущие коммерческие права, академические доказательства, source rights/content/hash/version, экран, полный scan, владелец или TTL изменились. Реализована двойная перепроверка прав после асинхронных чтений и финальное сопоставление сканера/экрана непосредственно перед HTTP-ответом. `qa/ai-layer-v21-p6-home-pg-http-gateway.cjs` вызывает gate до успешного 200. В одноразовой PostgreSQL специальные negative tests отзывают коммерческий `ai_generation_entitled`, source rights или меняют screen revision **после** выбора, но **до** отправки; обязательный ответ — fail closed, без пользовательских данных. [Actions #275](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38684809721) — полный GREEN §104 после исправления обнаруженной гонки с поздним отзывом источника.

**Важно:** последовательные read-only проверки НЕ заменяют одну serializable серверную транзакцию. Даже после последней проверки возможна более поздняя запись/отзыв прав. Это остаётся отдельным обязательным live-release gate; нельзя заявлять абсолютную atomic authorization.

## 105. Приватность ответа: внутренние evidence/action IDs остаются внутри QA-сервера (2026-10-15)

При равноприоритетных предметах `QAHomeApprovedPriority` продолжает внутреннее сравнение подписанного полного набора `candidateActionIds`, но HTTP теперь выдаёт только `choices:[{actionCode,subjectKey}]` после серверной проверки точного множества. Номера внутренних session/evidence, HMAC, grades, answers и JWT не передаются. Подмена ответа или изменение множества вариантов блокируется. [Actions #280](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38684994156) — полный GREEN серверного §105 и прежней математики, Pg/Chrome/Deno.

## 106. Трёхъязычное отображение равных по приоритету предметов и TTL (2026-10-15)

В **локальной синтетической** `qa/preview_v21/home-pg-local.html` добавлены ровные визуальные ряды разрешённых предметов, без кнопок с несуществующей навигацией и без внутренних идентификаторов. Названия основных/дополнительных предметов скопированы дословно из действующего `i18n.js` (RU/UZ/EN) и сверяются отдельным Node-тестом `qa/ai-layer-v21-p6-home-subject-labels.test.cjs`. Ответ выводится только через безопасный `textContent`; если пришёл неизвестный subject key или некорректная структура choices, UI fail closed.

Home также не сохраняет бессрочный устаревший ответ: `expiresAtMs` от подписанного плана приводит к автоматическому закрытию рекомендации, а смена экрана/языка и выход сбрасывают её немедленно. Chromium проверяет обычную Practice, tie двух субъектов на 3 языках, desktop/mobile, screen-reader landmark и истечение TTL без дополнительного запроса.

[GitHub Actions #287](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38685398048) — **полный GREEN 645/645 Node, 14/14 PostgreSQL**, обычный Chromium + HOME_PG_CHROME_TIE_GREEN RU/UZ/EN, HOME_PG_CHROME_TTL_GREEN, HTTP→signed PG, Deno, два parallel race теста, legacy protected-file guards. Отчёт: `docs/iclub-ai-layer-home-final-delivery-privacy-qa-20261015.md`.

**Global AI по-прежнему NO-GO:** Vercel Preview остаётся статической SSO-демонстрацией, новый HTTP Preview существует только внутри CI; реальная независимая source-rights публикация и live Edge/Supabase authorization не делались. По прямому решению архитектора новый Supabase branch не создавался; без нового отдельного GO запрещены любые изменения `main`, production, реальных ученических данных, localStorage, Mathematics Tutor, тарифов, доменов и платных AI-вызовов.


## 107. Один согласованный PostgreSQL MVCC snapshot непосредственно перед Home HTTP (2026-10-15; QA ONLY)

На основании найденной late-revocation гонки §104 реализован **один заключительный read-only SQL SELECT** `qa/sql_drafts/iclub_ai_v21_home_atomic_delivery_READ_ONLY.sql` для одноразовой local PostgreSQL. В рамках одного statement snapshot он проверяет текущий owner-bound Home context и revision/expiry, глобальный kill switch, protected-exam gate, исходный полный набор приоритетных кандидатов из server-scan, коммерческое `enforced`/AI entitlement и отдельное QA feature allowance, реальные по форме slot selections, evidence завершённой Practice/официального Tour/активного предмета, locale source rights/content/hash/version для каждого подписанного действия. Запись и изменение реальных данных исключены; исполнение скрипта вне `iclub_ai_v21_scratch_*` должно отказывать.

`qa/ai-layer-v21-p6-home-delivery-gate.cjs` **обязательно** требует результат `true` от последнего единого SQL authority check; прежние независимые HMAC/commercial/academic/editorial/full-scan проверки также сохранены. Локальный gateway `qa/ai-layer-v21-p6-home-pg-http-gateway.cjs` передаёт в SQL только структурно валидированный server-owned план и строго разрешённые UUID/action/locale/source values. Для воспроизводимой гонки есть test-only `beforeAtomicRead` callback: в disposable PostgreSQL source rights, AI plan entitlement и owner-screen revision отзываются именно после предыдущих асинхронных проверок и перед единственным SQL. Все сценарии должны завершиться без HTTP рекомендации.

[GitHub Actions #295](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38685923168) подтвердил base SQL **GREEN 647/647 Node, 14/14 PG, Chromium, Deno**. Далее [GitHub Actions #298](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38686134805) подтвердил полный **GREEN** после более строгих last-moment source/tariff/screen revocation injections, включая Home HTTP/Chromium RU/UZ/EN и защиту Mathematics Exam Prep. Документ: `docs/iclub-ai-layer-home-single-snapshot-qa-20261015.md`.

**Release boundary:** один PostgreSQL MVCC SELECT гарантирует согласованность только внутри выполненного read statement, **не** обеспечивает сериализуемую блокировку будущего действия после ответа и не защищает от нового отзыва после SQL. Для живого продукта понадобятся доверенная атомарная проверка+действие в одной транзакции, реальная отдельная source rights-публикация, подтверждённый live server auth, integrated protected Preview и отдельное GO архитектора. Отдельная Supabase-ветка по решению архитектора НЕ создавалась. Production/main/действующий Tutor/тарифы/localStorage и реальные ученики не изменялись. **Global AI остаётся NO-GO.**


## 108. Одноразовое подтверждение выбранного Home-действия (2026-10-15; QA ONLY)

Последний read-only MVCC Home-gate §107 дополнен **одноразовым action-time claim** на отдельной временной PostgreSQL без каких-либо изменений учебного прогресса. После проверки HMAC, коммерческого доступа, источников, учебного evidence, текущего экрана и полного приоритета QA Home выдаёт только 192-битный непрозрачный случайный `handoffToken`. В таблице `private.iclub_ai_v21_home_action_handoffs_scratch` хранится SHA-256 токена, исходный канонический подписанный план, владелец/контекст/язык/expiry и список точных разрешённых действий. Поле с прямыми session/evidence IDs клиенту не выдаётся.

При `POST /qa/home/confirm` отдельный localhost QA-handler заново подтверждает связку owner+context+locale+action+subject, HMAC и TTL. Затем **одним SQL-оператором** ещё раз проверяет полный PostgreSQL MVCC-снимок прав/источников/evidence §107 и конкурентно обновляет ровно один `consumed_at IS NULL` токен. Уже использованный токен, чужой владелец, неверное действие, неподтверждённый предмет и отзыв прав блокируются. Ответ `qa_handoff_confirmed` всегда содержит `reviewOnly:true`, `releaseAllowed:false`, `navigationExecuted:false`, `progressChanged:false`: никаких настоящих переходов и записей ученического прогресса не выполняется.

В локальном `qa/preview_v21/home-pg-local.html` добавлено подтверждение разрешённого действия и симметричные доступные кнопки выбора равноприоритетных предметов с прежними RU/UZ/EN названиями. Chromium проверяет успешное одноразовое QA-подтверждение на каждом языке без навигации и академических изменений; при выходе/истечении TTL старые разрешения не доступны. **Проверка конкуренции вынесена отдельно:** `qa/ai-layer-v21-p6-home-action-race.cjs` запускает два независимых потока с разными `psql`-процессами против одной строки во второй одноразовой базе — ровно один claim успешен, второй fail-closed, Practice остаётся прежней.

[GitHub Actions #319](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38689905828) — фактический **GREEN 649/649 Node**, **14/14 обычных scratch PostgreSQL**, плюс отдельный независимый Home action race DB, localhost HTTP, native Chromium RU/UZ/EN, Deno, две старые гонки и protected-file gates. Подробный отчёт: `docs/iclub-ai-layer-home-one-use-action-qa-20261015.md`.

**Граница §108:** это атомарное погашение **только синтетического токена**, а не транзакционный переход ученика в реальной Supabase. На production до действия требуется настоящая доверенная проверка в той же транзакции, что и фактическое действие, legal/source-rights GO и отдельное разрешение архитектора. Новая Supabase-ветка не создаётся. `main`, production, реальные ученики, тарифы, localStorage, Mathematics Tutor и платный provider не изменяются. **Global AI остаётся OFF/NO-GO**.

## 109. Отдельная авторизация учебного назначения после Home claim (2026-10-15; QA ONLY)

Продолжение §108: в `qa/ai-layer-v21-p6-home-destination-proof.cjs` создан независимый server-owned **read-only destination check** для завершённой Practice (`practice-review`), официально закрытого Tour (`tour-review`) и действующего study-предмета (`subject-hub`). В localhost QA `POST /qa/home/destination` допускает проверку только **уже подтверждённого** одноразового токена и выбранного действия/предмета. План и ID академического объекта извлекаются из сохранённого подписанного серверного плана; браузер не может подменить session/attempt ID. Финальный единый SQL snapshot повторно проверяет статус claim, HMAC-bound plan, current Home/context/rights/source/evidence/slot и наличие выбранного конкретного объекта. Если права/источник отозваны уже после успешного `/confirm`, получение даже read-only destination-proof блокируется. Дополнительные SQL HTTP negative tests охватывают pre-confirm, чужого пользователя, подмены, post-confirm source revocation и три destination-типа.

**Это не живой учебный переход.** Возвращается лишь минимальный server-approved тип назначения, всегда `reviewOnly:true,releaseAllowed:false,navigationExecuted:false,progressChanged:false`. В `app.js`/действующие Practice, Tour и Mathematics Exam Prep ничего не встраивалось. После выхода с Home конечный экран обязан заново создать **собственный** authenticated context и независимо авторизовать каждое получение учебных данных. Home-token никогда не становится разрешением на чтение произвольных API. Ни Supabase, ни Vercel, ни actual student data, localStorage, тарифы, текущая AI-оболочка, платная модель или `main` не изменялись; новая Supabase branch не создавалась. До отдельного Go остаются реальные Edge+Supabase rights, publication, integrated Preview и полноценный destination API. **Global AI OFF / NO-GO.**

Подробно: `docs/iclub-ai-layer-home-destination-reauthorization-qa-20261015.md`. [GitHub Actions #324](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38691379094) — **GREEN** для §109: **649/649 Node**, **14/14 PostgreSQL scratch**, локальный HTTP→PG после claim с post-confirm revocation и тремя видами учебного назначения, Chromium RU/UZ/EN, Deno, все конкурентные тесты и запрет изменений защищённых файлов. Это QA-доказательство, **не** live Supabase/Edge authorization или разрешение Global AI.

## 110–113. Полный защищённый QA-маршрут Home → учебный раздел → назад (2026-10-15; QA ONLY)

Этот пакет объединяет самостоятельную серверную авторизацию конечного экрана, защищённый **read-only** запрос учебного объекта, путь RU/UZ/EN в нативном Chromium и конкурентный отказ повторного использования. Проверка начинается с уже подтверждённого одноразового §108 Home token и свежего §109 destination-proof. Отдельная одноразовая PostgreSQL-операция повторно проверяет действующие права/источники/учебное evidence и создаёт короткий owner-bound `routeToken`, одновременно переключая **только искусственный** server current-screen из Home в Study. Старый Home context перестаёт действовать. Каждое последующее чтение Study делает свою независимую актуальную проверку owner, предмета, source rights/hash/version, commercial `enforced`/mode/slot, защищённого экзамена и конкретной Practice/Tour/study записи. Возврат отзывает route token, обновляет screen revision и требует нового Home proof. Клиент не выбирает object/session/attempt ID, не получает answer keys, grade или server hashes. Этот контур **не встраивается** в реальные экраны или API.

Добавлены `qa/ai-layer-v21-p6-study-route.cjs`, отдельная `private.iclub_ai_v21_study_routes_scratch` только в temporary PostgreSQL, 3 localhost QA endpoint `/qa/study/open`, `/qa/study/read`, `/qa/study/close`, полноценный доступный UI с Back и RU/UZ/EN, HTTP отрицательные проверки и гонка **двух независимых worker threads/psql** против одного Home action. Для предотвращения влияния тестов друг на друга старые Home revocation tests и новый Study browser/server journey теперь выполняются в **отдельных одноразовых базах**, без каких-либо изменений настоящей Supabase. Сценарии покрывают продолжение предмета, архив завершённого Tour, исправление Practice, смену режима, отзыв source после входа, повторные обращения, владельца, locale и active protected assessment.

[GitHub Actions #332](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38693320501) — полный **GREEN 649/649 Node, 14/14 PostgreSQL**, отдельный Study PostgreSQL + Chromium RU/UZ/EN, `HOME_STUDY_BACK_CHROME_GREEN` на всех трёх языках и `HOME_STUDY_TWO_WORKERS_GREEN` (один вход, один отказ), Deno и защита legacy/protected files. Документ: `docs/iclub-ai-layer-home-study-full-flow-qa-20261015.md`.

**Граница:** это автономная симуляция безопасного пользовательского перехода, **НЕ реальное открытие учебных данных учеников**. Production Auth, server-permitted учебная навигация, RLS/API, отдельная source-rights публикация, интегрированный защищённый Preview и одобрение выпуска отсутствуют. Ни `main`, ни production, ни реальная Supabase, ни localStorage/учебная история, ни существующая AI-оболочка/тарифы/Mathematics Tutor не менялись. Новая Supabase branch и платные AI-запросы не создавались. **Global AI OFF / NO-GO** до одного отдельного разрешённого интеграционного release gate.

## 114. Сверка P0–P9 с настоящими контрактами и автоматический NO-GO для интеграции (2026-10-15; READ-ONLY + QA)

Проведена повторная сверка документа с фактическим кодом QA и текущей метаданных-схемой Supabase **без чтения пользовательских данных и без записей**. Полный разбор: `docs/iclub-ai-layer-p0-p9-live-gap-and-readonly-preflight-20261015.md`. Важное уточнение к более ранним статусам: **P0** (начальный read-only аудит) выполнен с обязательным повторением перед выпуском; **P1–P8** имеют завершённые различные QA-подзадачи, но пока не соответствуют полным live/release gates; **P9** фактически не выполнен. Успешный offline CI **не** означает закрытие всего P2–P8.

По точному сканированию `qa/edge_v21/supabase_services.ts` зафиксировано **23 ожидаемых RPC-имени**. Read-only `pg_catalog.pg_proc` действующей Supabase **не показал ни одной** из этих новых функций. Наличие legacy функций не заменяет отдельные v2.1 контракты: fallback к старым RPC без авторизации запрещён. Существующие коммерческие `get_iclub_subject_access_guard_service_v1` / `get_iclub_subscription_capabilities_service_v1` повторно совпали с утверждёнными MD5 `bb0c27de3665e5c6e16810044b1316a5` / `58bfe7eaf0c54a8e74d50bbf79416684`; executable privileges `anon/authenticated=false`, `service_role=true`. Проверенные учебные и commercial таблицы имеют RLS ON, но это **не** полный аудит самих policy expressions. Прямые SELECT роли `anon/authenticated` для private selections, Practice sessions/answers и Tour runtime недоступны; будущий AI должен использовать явно авторизованные endpoint и owner proof. Действующие `exam-prep-ai` и `practice-ai` Edge-функции зафиксированы как активные, новый v2.1 Edge не развёрнут.

В QA добавлены `qa/ai-layer-v21-p9-live-metadata-readonly-snapshot.json`, `qa/ai-layer-v21-p9-live-integration-preflight.cjs`, отрицательные тесты и `qa/sql_drafts/iclub_ai_v21_p9_catalog_READ_ONLY.sql`. Preflight сравнивает live snapshot с **точным списком вызовов реального QA-адаптера**, коммерческими function hashes/grants, RLS, защищённым Tutor, отсутствием соединения QA-кода с production UI, источниками и интегрированным Preview. Даже искусственное выставление всех метаданных как «готовых» **не даёт GO**: проверка требует независимых release/owner/provider, RLS, Core AI-OFF и editorial/legal gates. Запуск в CI ничего не читает из production: использует датированный snapshot. Новый read-only SQL сохранён для будущего повторного разрешённого метаданного аудита.

[GitHub Actions #335](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38695206769) — **GREEN**: 656/656 Node (включая 7 новых fail-closed P9 checks), 14/14 scratch PostgreSQL, localhost HTTP, отдельный Study workflow, Chromium RU/UZ/EN, Deno, независимые двухпоточные гонки и protected file gates. Ожидаемый production preflight: **23 missing RPC, NO-GO**.

**Следующий крупный допуск:** подлинное owner/subject/intent + RLS/security review для всех server endpoints; одобренная независимая source-rights publication, реальное trusted Edge/Supabase implementation и отдельный защищённый интегрированный Preview, с проверкой Core AI OFF/Math parity, rollback, тарифной экономики и отдельным разрешением архитектора на cohort/provider/live spend. На существующей production Supabase **никаких миграций**, новых тестовых пользователей, данных, платных вызовов или новых Supabase branch. `main`, работающий Mathematics Tutor, сертификаты, тарифные экраны, локальный и серверный прогресс не изменялись. **Global AI OFF / NO-GO**.


## 115. Единая сверка 23 готовых QA SQL-контрактов и 7 live RLS policy (2026-10-15; QA ONLY)

Определено, что **все 23 RPC имени** будущего `qa/edge_v21/supabase_services.ts` уже имеют SQL определения в **9 существующих** `*_UNAPPLIED.sql`. Не создавать дублирующие заглушки. `qa/ai-layer-v21-p9-rpc-draft-manifest.json` и `qa/ai-layer-v21-p9-draft-contract-gate.cjs` автоматически проверяют точные аргументы, соответствие Edge-контрактам, защищённый SECURITY DEFINER/search_path, запреты PUBLIC/anon/authenticated, service_role-only grants, scratch DB guard и граф SQL-зависимостей. Отрицательные проверки встроены в офлайн CI.

Metadata-only `pg_catalog.pg_policy` подтвердил семь политик: публичный каталог `subjects`, owner `auth.uid()` для `tour_attempts` и пяти политик `user_subjects`. Датированные отпечатки хранятся в `qa/ai-layer-v21-p9-policy-fingerprint-snapshot.json`. Это не подтверждение корректной работы нового service-role Edge, не live authorization и не разрешение миграции.

**23/23 SQL черновиков != 23/23 live функций.** На действующей Supabase по предыдущему метаданному аудиту по-прежнему 0/23 новых v2.1 RPC. Применение к production запрещено, реальный интегрированный Preview не создан, права на источник/смета/миграции/rollout не утверждены. Полный отчёт: `docs/iclub-ai-layer-p9-rpc-draft-and-rls-contract-audit-20261015.md`. **Global AI OFF / NO-GO**.


**Итог технического CI:** [GitHub Actions #338](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38698089004) — **GREEN, 664/664 Node, 14/14 independent scratch PostgreSQL**, проверка исходного Home HTTP, полный Chromium RU/UZ/EN Home→Study→Home и два независимых PostgreSQL-исполнителя с результатом один вход / один отказ. Новый fail-closed SQL RPC coverage test проверил все 23/23 existing UNAPPLIED drafts и отрицательные сценарии. Первый промежуточный run #337 отклонил дефект самого отрицательного теста с заменой SQL delimiter; тест и валидатор исправлены, полный run #338 GREEN. Protected app/Exam Prep/tariff файлы не изменились. Этот успех **не** означает live deployment либо разрешение запускать Global AI.

## 116. Совместная транзакционная проверка девяти UNAPPLIED SQL (2026-10-15; QA only)

Собран единый disposable PostgreSQL fixture с подлинной v1 тарифной базой и synthetic academic schema; девять черновиков загружаются в одном `BEGIN`, проверяются 23 RPC и server-role permissions, OFF gates, невозможность платного запроса, затем один `ROLLBACK` должен вернуть исходную v1. Интеграционная схема основана на искусственных таблицах и ограниченных v1 stub-функциях, **не production clone**. Дополнительно 15-й независимый PostgreSQL набор включён в QA CI. [Actions #340, attempt 2](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38699714767) **GREEN: 664/664 Node, 15/15 PostgreSQL**, integrated 23/23 RPC и rollback baseline PASS. В последующей live metadata-only сверке 89 столбцов десяти таблиц выявлено **49** несовпадений с упрощённым fixture: это **не production clone**, до запуска потребуется новый полный synthetic schema compatibility. Датированная metadata-карта: `qa/ai-layer-v21-p9-production-schema-shape-readonly.json`. Результат: `docs/iclub-ai-layer-p9-nine-draft-integrated-qa-20261015.md`. Исходный run #340 остановился до PG-тестов по 20-секундному Chrome CDP timeout, повторный без изменения кода GREEN. Production Supabase, Vercel, main, данные и прогресс не затронуты. Global AI OFF / NO-GO.

## 117. Production-column-shape synthetic QA и независимость двух учеников (2026-10-15; QA only)

По датированным production metadata из §116 подготовлен отдельный локальный SQL overlay: все **89 колонок** десяти таблиц соответствуют именам, типам и nullable; добавлены 49 ранее отсутствовавших колонок. Настоящие production rows, Auth, RLS definitions, triggers, indexes и ограничения не копировались; **это не настоящий Supabase-клон**. Сохраняя девять `UNAPPLIED` SQL в одном `BEGIN/ROLLBACK`, новый тест проверяет два owner-bound Practice, denial чужих объектов, отзыв enrollment, protected assessment, повторное чтение, RLS subset через *синтетическую* локальную `auth.uid()`, отказ прямого privileged RPC и транзакционное отклонение дубликата учебного результата. Не означает доказанную production JWT авторизацию. Все проверки изолированы в 15-м scratch PostgreSQL-наборе. **[GitHub Actions #343](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38702394334) GREEN: 666/666 Node, 15/15 PostgreSQL**, Chromium RU/UZ/EN и двухисполнительные гонки. `FULL_SHAPE_89_GREEN`, `TWO_OWNER_RLS_GREEN`, `TWO_OWNER_SCOPE_GREEN`, `INTEGRATED_NINE_ROLLBACK_GREEN` подтверждены логом. Первый run #342 выявил nullable mismatch `public.tours.is_active` в упрощённой fixture; исправлен **только QA overlay**, никакие production поля не менялись. Полный отчёт: `docs/iclub-ai-layer-p9-full-shape-two-owner-qa-20261015.md`. Global AI OFF / NO-GO.
