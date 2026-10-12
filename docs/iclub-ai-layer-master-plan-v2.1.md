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
