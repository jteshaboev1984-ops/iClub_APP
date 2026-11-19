# iClub AI Tutor — единая карта экранов и гибридных действий v1

**Решение архитектора:** один существующий iClub AI Tutor во всём приложении. Его значок показывается по текущему экрану, а не по чужому экрану или незавершённой записи в базе. Бета-согласие проверяется отдельно. Новых AI-окон не создавать.

**Этап 1 (этот PR):** привести к единой карте `PREPARED_SCREEN_ACTIONS` уже опубликованные продуктовые подсказки в `iclub-ai-v21-ui.js`. Максимум три коротких вопроса на текущем экране, язык RU/UZ/EN. Все готовые кнопки идут строго по существующему `iclub-ai-v21-prepared` и существующим утверждённым ключам; не допускается подмена произвольным запросом модели. Никаких миграций, тарифов, новых Edge-функций, академических источников и платных вызовов.

## Экран → доступные уже проверенные действия

| Экран | Готовые действия | Ограничение |
| --- | --- | --- |
| Главная | Начать обучение, правила Practice, подготовка к туру | Общие инструкции, не вымышленный персональный план |
| Список предметов / предмет | Начать обучение, правила Practice, учебные материалы | Не обещать объяснение темы без проверенного источника |
| Перед Practice | Правила Practice, разбор ошибок, рекомендации | Никаких подсказок для активного вопроса |
| Завершённая Practice | При наличии валидного PC1: объяснить реальный результат, следующий шаг, сравнить попытки | ТОЛЬКО серверные персональные данные, привязка к попытке |
| Завершённая Practice без доступного PC1 | Общий порядок разбора, рекомендации и правила | Нельзя выдавать общие подсказки за персональный результат |
| Разбор ошибок / рекомендации | Порядок разбора, рекомендации, где материал | Конкретная ошибка: только после утверждения вопросного источника |
| Tours и архив | Только опубликованные правила тура/помощь; отдельные карточки архива и сертификатов ещё не опубликованы | Нет решений до глобального открытия разбора |
| Книги, видеоуроки, уроки | Поиск материалов и общая навигация | Без утверждённой привязки не заявлять знания видеосодержания |
| Exam Prep P1/P5 | Пока только материалы и правила Practice | Отдельные AI-1 источники и режим, защищённые проверки недоступны |
| Рейтинг, профиль, уведомления, сертификаты, поддержка | Только соответствующие реально опубликованные подсказки; когда профиль/рейтинг/уведомления не имеют карточки — безопасная помощь без выдуманных данных | Не придумывать результаты пользователя |

**Проверено по живому Supabase 29.10.2026:** на RU/UZ/EN одновременно опубликованы и прошли rights/content/locale review только семь продуктовых ключей: `books_help`, `catalog_help`, `practice_after`, `practice_rules`, `recs_help`, `support_help`, `tour_rules` (остальные 6 опубликованных ключей — техническая навигация `nav_*`, не общие объяснения). Упоминание `home_next`, `archive_help`, `profile_meaning`, `certificates_help`, `ratings_help`, `notifications_help`, `community_help`, `about_help`, `video_help` и т. п. в API/коде не делает их утверждёнными: **кнопки для неопубликованных ключей не показывать**. Если экран не имеет специализированной карточки (например, показатели профиля), показывать только близкую по смыслу опубликованную поддержку, а не ложное персональное объяснение. Слова кнопок берутся из авторизованного контракта RU/UZ/EN, а не из тем, названий экранов или текстов пользователя. Кнопки не выполняют навигацию за ученика и не изменяют оценки.

## Единая модель взаимодействия

1. **Готовая инструкция:** ученик нажал кнопку — выдать утверждённую подсказку без модели. Экран помогает выбрать разрешённое действие, но не предоставляет доступ к скрытым материалам.
2. **Проверенный результат:** `Practice` использует существующий PC1/PC2 для собственного завершённого attempt ID, проверяет владельца и финальный статус. Сравнение и следующий шаг серверные и не генерируются моделью.
3. **Свободный вопрос:** только по явному нажатию отправки. Вызывает существующую модель лишь при подтверждённых полномочиях, контексте, провайдерском бюджете, лимитах и безопасности. Никаких автоматических запросов при открытии Tutor или смене экрана.
4. **Академический вопрос:** точный lesson/topic/archived Tour/Practice error разрешается только при наличии утверждённого, актуального источника для конкретного предмета и всех трёх языков; иначе показать честный отказ/доступную обычную помощь. Нельзя переносить общую математическую карточку Exam Prep на конкретный legacy Practice question без проверки версии и решения.
5. **Защищённый экран:** значок скрыт во время активной Practice/Tour/защищённой проверки Exam Prep. Сервер независимо проверяет защищённые попытки. Открытие архива Tour после глобального закрытия — обязательное условие.

## Следующие небольшие этапы (вне этого PR)

- **Качество:** безопасная текстовая нормализация ответов (например, видимые `**`), точные локализованные наименования кнопок, проверки RU/UZ/EN.
- **Утверждённые учебные темы:** постепенно добавлять точный источник/версию/3 языка и объяснение с моделью, начиная с малого объёма и не утверждая содержимое видео без транскрипта.
- **Исправление ошибок:** только после связи конкретной финализированной ошибки, вопроса, утверждённого объяснения и прав пользователя.
- **Exam Prep / прогресс / Tour archive:** подключать существующие server-owned deterministic contracts и отдельные release gates по мере готовности. AI не пересчитывает score/mastery/rating/certificates.

## Точное правило показа значка

JavaScript и CSS обязаны принимать одно и то же решение **по активному экрану**, не по наличию старого класса `is-active` в скрытой другой вкладке. В частности, CSS-блокировка Practice/Tour действует только при `#view-courses.is-active` с соответствующим `courses-practice-quiz` или `courses-tour-quiz`. Иначе оставленная в DOM незавершённая сессия скрывает Tutor на Главной/Профиле вопреки продуктовым правилам. В активных заданиях блокировка должна срабатывать до первого кадра и повторяться в JavaScript и на сервере при запросах.

## Безопасность и выпуск

Инварианты: Core независимо работает при AI OFF; не менять таблицы и данные реальных учеников, `localStorage`, результаты, предыдущие оценки; server-only provider keys; отсутствие AI в активном экзамене; одни и те же академические факты на трёх языках; нет автоматических расходов; один существующий Tutor без новых панелей.

QA этапа 1: изолированный Chromium с настоящими JS-файлами проверяет Home, предмет, Practice, смену языков RU/UZ/EN, конкретный approved prepared route, отсутствие модельных вызовов; существующие GoTrue/PostgreSQL/Deno/PC1–PC4 проверки, защита активных Tours/Exam Prep и Core regression. Никаких платных провайдерских вызовов, Preview или real-user accounts для теста. Merge только при зелёной целевой проверке и неизменившемся main.

## Continuation plan — 2026-11-19 (Issue #412)

This section is a **task-specific implementation plan**, not a new standing rule, tariff decision or authorization to release. Prior sections describe the already accepted 2026-10-29 screen map and must not be re-run as a new implementation.

### Package A — existing Tutor delivers learner-safe educational help (START HERE)
1. Trace the already deployed provider-free routes and the existing `iclub-ai-v21-ui.js`, `iclub-ai-v21-beta-client.js`, `practice-ai-ui.js`, `exam-prep/exam-prep-ai-ui.js` without introducing a second AI window. Reuse genuine server-owned finalized Practice result/approved source context and existing 243 Mathematics P1/P5 Tutor Cards; preserve Exam Prep's existing controlled behavior.
2. On a typed subject/academic question with **no approved source or no enabled academic route**, show a clear RU/UZ/EN academic-source-unavailable explanation rather than pretending a topic was taught or redirecting it to paid general chat. Retain existing prepared product help for nonacademic questions. This first change is provider-free and does not grant new capabilities.
3. Test subject/assessment/current user transitions with existing CI. Do not claim browser E2E from source-only assertions; a real authenticated browser/HTTP pass and learner visual acceptance remain separate release evidence. Existing unmerged Practice AI Draft #366 owns overlapping experimental source: do not edit that branch, replay it, or replace its protected code with stale definitions.

### Package B — reliability / privacy / budget preparation
- Reuse existing request IDs, service-only source retrieval, saved receipts and per-route limits. Identify missing correlation of UI ↔ server request ↔ outcome/latency/token estimate/spend; store only minimal authorized metadata, **not all learner prompts/responses** by default.
- Confirm explicit provider timeout, unknown-charge replay behavior, 429 / unavailable model messaging, source/prompt/model version bindings and AI-OFF Core preservation. Test only real gaps, not a new observability platform or speculative provider-failover system.
- Owner must approve any new minors' consent/retention policy, paid budget ceiling, production/security change or wider learner access.

### Package C — limited model-backed educational clarification (HOLD)
- Only after A/B pass and owner sets an explicit small cross-route spend ceiling: a learner deliberately submits a question tied to an **authorized approved** source. Server chooses whether a model call is allowed; no model call on opening a screen. Respect subject/locales, provenance, output validation, safe unavailable response and existing financial receipts.
- No blanket generation ON, new provider, checkout/tariffs, fine-tuning, compulsory RAG/vector DB, semantic cache, multiple agents or auto-switch to paid backup models. Keep subject expansions separately governed.

### Package D — evaluate and extend (HOLD)
- Start with **30–50** targeted cases (RU/UZ/EN, exact P1/P5 source, finalized Practice, no-source, protected attempt, missing auth, model failure and request accounting) rather than a mandatory huge generated corpus. Evals should check grounding, factual correctness, usefulness, non-disclosure and source stability; human/reviewer calibration is independent of an LLM-as-judge score.
- Record request IDs, counts and latency/errors/cost with privacy by default; review feedback and delayed unaided Practice learning. Expand Economics → Chemistry → Biology → Informatics only when reviewed original source cards and academic release gates permit. Never award marks/progress via AI.

### Evidence and GO
- Use the existing `docs/ai/ai-edge-route-inventory-v1.md` as the historical + current route ledger, this implementation contract as the task-level spec and Issue #412 as the live checkpoint. Do **not** create redundant PRD/API/runbook files for already documented functions.
- Package A changes may be developed in a **separate Draft PR** and tested without production writes. Merge to `main`, Vercel deploy, Supabase/Edge write, paid-model usage, feature activation and academic publication require **specific owner GO**. Branch SHAs and test results, not dated checklists, determine completion.
