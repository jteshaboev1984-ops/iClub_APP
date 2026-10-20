# Global AI v2.1 — сверка с Master Plan P0–P9 и приоритет следующего релиза
**20.10.2026 · iClub production + текущая QA-ветка · запись только в QA**

## Продуктовая цель, а не количество подготовленных SQL-записей
Утверждённый Master Plan `docs/iclub-ai-layer-master-plan-v2.1.md` задаёт одну фирменную AI-панель для всех поддерживаемых экранов и предметов, а не отдельный AI на Chemistry/Economics. Помощь строго на основании подтверждённых учебных источников и владельца контекста. AI не изменяет исходные вопросы, академический прогресс, ответы, оценки, Exam Prep, сертификаты или localStorage. Некорректные и непроверенные источники должны оставаться закрытыми. Платная генерация, финальные тарифы, массовое открытие не авторизованы.

## Карта P0–P9 в актуальных терминах
| Этап Master Plan | Фактический прогресс | Открытая граница |
|---|---|---|
| P0 baseline | Реальная GitHub/Supabase/Vercel инвентаризация, сохранены живые ограничения | Readback перед каждым production-релизом |
| P1 Preview | QA-среда и автономный Chromium используются без реального AI model/новых пользователей | Не запускать новый Vercel deploy на каждый микрошаг |
| P2 authority / source readiness | Один JWT Edge, серверный контекст, общая проверка источников, QA negative paths | Каждая фактическая новая версия требует редакционных evidence |
| P3 единый UX | Option A панель, UI и мобильные/desktop браузерные регрессии | Положительный реальный сценарий нового контента ещё не подтверждён |
| P4 Math Tutor parity | Исходный Mathematics Exam Prep Tutor не переведён на новую квоту и не изменён; frozen-code guards | Не менять Tutor в глобальном академическом релизе |
| P5 Practice/Tours | Запрет во время active Practice/Exam и закрытого Tour, источник точной ошибки после finalized | Только 10 старых admitted question IDs доступны через активные Practice pools |
| P6 subjects / Home / Profile | Универсальный путь; опубликованная beta содержит 111 старых локализаций; +210 закрытых черновиков Chemistry/Economics | Содержательное, правовое, языковое утверждение + cohort testing |
| P7 temporary tariff | Изолированный 1:3 meter, квота и paid mock QA; текущая prepared-only beta provider OFF | Финальная коммерческая модель не утверждена |
| P8 full security/QA | Real scratch PG, Chromium, generic source admission и main-parity тесты | Реальная successful learner delivery = 0 на проверенном снимке |
| P9 owner GO/NO-GO | Предыдущие 111 карточек отдельно разрешены в closed beta, cohort 3 кандидата, 1 согласие в снимке | Новые 210 карточек не разрешены к публикации, массовое включение запрещено |

**Каталожные 321 записи не означают 321 доступных ответов.** 111 допущенных карточек соответствуют 37 вопросам, но в активных Practice pools находятся лишь 10 из них. Следующая партия 70 вопросов (210 локализаций) полностью закрыта, хотя технически все 70 связаны с текущим активным пулом.

## Почему следующий шаг — история версий, затем редакционная выдача
В существующей таблице `private.iclub_ai_v21_academic_sources` PRIMARY KEY `(surface_code,subject_key,context_key,locale)`. Две одновременно активные версии одной локали не хранятся. Ранее QA-механизм уже позволял менять текст объяснения независимо от `public.questions`, но не сохранял автоматически прежнюю версию. Простая замена поставила бы под угрозу traceability и старые разрешения. Этот пробел обнаружен при сопоставлении с требованиями Content Governance и Master Plan.

Подготовлен **неприменённый** QA-кандидат `qa/live_candidate/iclub_ai_v21_source_revision_history_QA_ONLY_UNAPPLIED_20261020.sql`. Он создаёт закрытый архив предыдущих оригинальных карточек и одну административную операцию обновления полного EN/RU/UZ набора только если все три предыдущие версии остаются черновиками без публикации, без релиза владельца и без записанных выдач. Архив append-only; новая версия сохраняет старую неизменной. Любой провал останавливает транзакцию целиком. Результаты учащихся, даже тестовых, нельзя подменять ради демонстрации.

Автономный PG-тест `qa/live_candidate/iclub_ai_v21_revision_ledger_SCRATCH_TEST_ONLY_20261020.sql` использует только синтетическую запись, проверяет три языка, старую версию, подмену архива, запрет замены разрешённого или уже выданного ответа, а также запрет RPC для service_role. Синтетические данные нельзя переносить в production. **Факт прохождения QA устанавливается отдельно после завершения Github Actions для точного SHA.**

## Очередь контент-редактуры
`docs/iclub-ai-v21-qbank-70-editorial-review-queue-20261020.csv` фиксирует все 70 предметно-реальных вопросов, язык, chapter source, status `PENDING` и 8 точных замечаний. Автоматические технические проверки прошли 70/70; это не значит, что 70/70 академически, языково и юридически утверждены. Не заполнять фиктивные review/rights подписи. Права на Cambridge Coursebook и права на оригинальные explanations — разные вопросы.

## Последовательность до будущего релиза
1. Закончить полную scratch-верификацию безопасной истории версий и стабильности текущего main.
2. Уточнить 8 отмеченных случаев как новые AI-only версии на EN/RU/UZ, отдельно от исторических question rows, и передать полную очередь на реальное Content/Academic/Rights/Language review.
3. После реального reviewer evidence и явно выбранного владельцем объёма партии подготовить один минимальный reversible release; не открывать новых карточек автоматически.
4. Проверять реальную завершённую ошибочную Practice-попытку только настоящего согласившегося участника, без подделки, с проверкой no-source/correct/skipped/foreign/in-progress/revoked, трёх языков, квот и неизменности Math Tutor.
5. Лишь после этой демонстрации рассматривать расширение cohort/предметов и потом — отдельно — платную генерацию/тарифы.

**Production boundary:** никаких изменений `main`, Vercel, Math Tutor, исходных вопросов, биллинга, данных и прогресса пользователей во время QA-кандидата. Любой выпуск P9 — отдельный GO владельца.

## Проверенная следующая точка

Точная кодовая точка QA: `19e82bd5cf41eb25174c757e4ad27c66cc3abd4f`. [Полный offline QA + независимый PostgreSQL](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/39432852027) и [проверка с актуальным main](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/39432851756) — оба **SUCCESS**. Это доказывает контракт архивирования в синтетических сценариях, но не разрешает применение migration на production.

Добавлен `docs/iclub-ai-v21-3-trilingual-curated-content-proposals-20261020.json` — три технически подготовленных редакционных предложения (Chemistry #10095, Economics #9465 и #9723, полный EN/RU/UZ). Их девять строк привязаны к предыдущей версии и исходным SHA-256, но не заменяют текущий контент и не подписаны Content/Academic/Rights/Language reviewers. Новые QA-тесты проверяют структуру и вычислительные шаги; не заявлять публикацию.

Блокер теперь конкретен: произвести независимый академический/правовой/языковой review исходных **70**, включая 8 отмеченных вопросов, получить явное решение на реальную малую партию, затем установить проверенный общий source gate + archive в отдельном обратимом релизе. Перед проверкой нового route на ученике нужен настоящий неправильный ответ в **завершённой** Practice и отдельное согласие; ни тестовые попытки, ни чужие данные, ни активные экзамены не используются.

## Final CI acceptance of curated proposals (same QA branch)
- Isolated real PostgreSQL history, negative grants/versions, all legacy safeguards and Chromium: **SUCCESS** [39433780886](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/39433780886).
- Actual current-main integration parity: **SUCCESS** [39433780419](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/39433780419).
- Both certify exact source code commit `f6d50304d82863d8487b7ee066d34c3b18605bf0`. Later documentation edits do not alter tested source code.
- `docs/iclub-ai-v21-3-trilingual-curated-content-proposals-20261020.json` stays editorial/rights/locale PENDING and `NOT_APPROVED_NOT_STAGED_NOT_RELEASED`.
- These passes do not constitute academic reviewer approval, real account E2E, or production deployment permission.
