# iClub APP — roadmap визуального обновления от регистрации до последнего пользовательского сценария
UI-ROADMAP v1.0 · 11.11.2026 · Issue #531 · база main 12c4381d75b2ebe112b60cdd574626ba137a06d8

## Цель и неизменяемый подход
Обновить весь визуальный опыт iClub, сохранив узнаваемый бренд, **все действующие функции и пользовательские данные**. Владелец приложения — продуктовый архитектор: он утверждает каждый выбранный дизайн. ChatGPT — технический исполнитель и контролёр совместимости. Google Stitch — только дизайн-макеты; обмен результатами вручную, никаких MCP, сторонних API-ключей и Codex по умолчанию.

**Перед первым экраном:** не переписывать архитектуру. Текущие index.html/app.js/style.css, visual CSS, i18n.js и специализированные JS — основа. Ориентир — реальный экран на устройстве и код, а не абстрактный «идеальный» редизайн. В Stitch использовать обезличенные примеры.

**Status words:** BACKLOG → SOURCE VERIFIED → PROMPT SENT → STITCH RECEIVED → DESIGN REVIEW → DESIGN APPROVED → DRAFT IMPLEMENTED → QA PASSED → OWNER RELEASE GO → RELEASED. Эти этапы независимы для каждого блока. Дизайн APPROVED ≠ разрешение MERGE/DEPLOY.

## Блоки в порядке пользовательского пути

| Блок | Что целиком охватывает | Матрица карт | На выходе из Stitch | Когда готов к отдельному внедрению |
|---|---|---|---|---|
| **B00 — Регистрация и первое открытие** | Splash, восстановление, форма RU/UZ/EN, выбор региона/района, школьник/не школьник, предметы, согласие, ошибки/повтор/профиль Telegram | A01–A14, N01–N06/N09 | Полный экран, краткие состояния, интеракции, клавиатура/кнопки | Все варианты и валидация показаны; ни один существующий пользователь не переведён на повторную регистрацию |
| **B01 — Каркас интерфейса** | Topbar, нижние 4 вкладки, back, notifications badge, visual tokens, карточки, типографика, компоненты | B01–B02, N01–N11 | Система базовых компонентов + образцы | Доказаны отсутствие конфликтов CSS и одинаковое поведение на каждом маршруте |
| **B02 — Главная** | Competitive, закреплённые учебные, дополнительные разделы, пусто/загрузка/недоступно | B03–B07 | Home 0/1/2 competitive, study-card variants | Все прямые переходы ведут в те же существующие действия |
| **B03 — Каталог/предметы/обучение** | Каталог и фильтры, выбранный предмет, mentor, видео Telegram, Books, библиотека, Exam Prep placeholder | C01–C11 | Каталог + Subject Hub + материалы + соответствующие conditional states | Нет нового предметного маршрута; media/back/права сохраняются |
| **B04 — Practice** | Этапы, темы, попытка, MCQ/input, pause/resume, результат, вкладки, разбор, рекомендации, история и повтор | D01–D17 | Единый набор экранов Practice + все три состояния ответа + черновик/ошибка | Серверная проверка и idempotency не меняются; история/пулы/answers сохраняются |
| **B05 — Tours** | Календарь/статус, правила, активный тур/таймеры, anti-cheat, результат, разбор, история | E01–E10 | Набор соревновательных экранов с неизменной смысловой иерархией | Таймер/1 попытка/anti-cheat/score untouched, сертификаты не открываются раньше срока |
| **B06 — Ratings** | District/Region/Country, фильтры/сезон, поиск, таблица, нижняя панель «мой ранг», отсутствие участия | F01–F07 | Compact leaderboard + search/info/empty | Нет ранга у неучастника, расчёт/время/рейтинги не переписаны |
| **B07 — Profile и доступ** | Обзор, достижения, свободные слоты, настройки языка/Competitive/Study, тарифные блоки по праву | G01–G14 | Profile main + Settings + conditional Plan/Subject Access | Без reset языков/прогресса; коммерческая архитектура не активируется |
| **B08 — Информация и помощь** | Уведомления, About, team/mentor, внешнее community, 8 support topics/FAQ/заявка, статусы | H01–H08, B05 | Общий стиль информационных страниц и формы | Пользователь может реально отправить обращение; no accidental external tab |
| **B09 — Сертификаты и архив** | Карточки, сезоны, предпросмотр, download, lock, QR verify, archive+replay | I01–I07 | Certificates list/view/verify + archive | Результаты, QR и условия открытия/закрытия не изменены |
| **B10 — Math Exam Prep** | Dashboard/Exam Profile, P1/P5, diagnostic, tracker/skill, weekly, corrections/retest, timed, readiness, materials, 42 Extra Hard, optional AI; Hybrid S4 лишь с gate | J01–J25 | Модульная серия экранов в стиле основного iClub, строго разные P1/P5 | Не трогает Issue #450 без отдельного source/owner GO; no fake score or AI grading |
| **B11 — Economics Exam Prep** | Limited entry, P1/P3 MCQ, 12-item check, plan/theory, full paper/history/profile, written P2/P4 if available | K01–K12 | Предметный набор на единой визуальной системе, не новый app | Реальный доступ/assessments/сохранение per-paper проверены |
| **B12 — Chemistry Exam Prep** | Conditional Entry/P1/recheck/labs и unavailable states | L01–L08 | Единый host + chemistry-specific states | Controlled beta release и права неизменны |
| **B13 — AI и коммерческие оверлеи** | iClub AI chat, contextual/Practice AI, ограничения/ошибки, тарифные объяснения и будущие (design-only) flows | M01–M05, G11–G14 | Панель AI и все ограниченные состояния без обещания неподключённых функций | No new AI entitlement/payment; scorer remains deterministic |
| **B14 — Системные состояния и окончательный QA** | Loading/error/empty/confirm/offline, Telegram links, responsive layout, public QR, end-to-end back, 3 языка | N01–N12 + A..M | Общий набор empty/error/skeleton/toast/modal guidelines | Полное smoke/regression покрытие, независимый Preview, отдельное GO |

**Последовательность:** B00 первый. B01 фиксируется после первого согласованного решения B00, иначе поздняя смена токенов сломает много макетов. B02–B09 — последовательная основа действующего приложения. B10–B12 отделены от активной команды Exam Prep. B13 — только разрешённые реальные AI/commerce UI, не обещания. B14 закрывает сквозные сценарии, но ранний QA обязателен для каждого блока.

## Что именно считать одним завершённым визуальным блоком

Каждый блок должен иметь:
1. **Source pin:** точный main/ветка SHA, существующие файлы, текущий screenshot (без персональных данных), проверенные пути входа/back.
2. **UI inventory:** все экраны и видимые состояния, различия student/nonstudent, competitor/viewer, new/existing, allowed/denied, empty/active/finished, locales RU/UZ/EN.
3. **Visual brief:** одна основная задача для Stitch, неизменяемая логика/тексты, запреты; изображения только синтетические.
4. **Stitch handoff:** исходный промпт, скриншот/экспорт/ответ, указание какие экраны действительно сгенерированы.
5. **Product approval:** архитектор пишет явное «утверждаю дизайн Bxx» или даёт поправки; замечания сохраняются.
6. **Implementation PR:** отдельная ветка от проверенного HEAD, только HTML/CSS/минимальная JS-разметка; никакой «чистой» замены большого app.js.
7. **Acceptance:** 320×720 / 375×812 / 390×844 / 1440, RU/UZ/EN, back/keyboard/click/focus/contrast/truncation, screenshot diff и test proof функциональности.
8. **Data gate:** неизменные auth, Supabase contracts, localStorage drafts, attempts, P1/P5 ledgers, backend.
9. **Release gate:** ссылку Preview, QA-log, точный SHA, явный release GO архитектора. До этого Draft PR не merge.
10. **Checkpoint:** какая подзадача завершена, какая именно следующая, без общих пересказов.

## Минимальные общие визуальные компоненты (один раз, переиспользуются)
- Shell/topbar/tabbar/back/safe-area, toast, loading overlay/skeleton.
- Page heading/subtitle; section heading/section gap; neutral card; subject card.
- Primary/secondary/disabled/danger buttons; inputs/selects/textarea/search; radio/toggle/chip; focus/keyboard.
- Status chip/empty/error/locked, progress indicator, segmented switch, item list/card row, bottom action bar.
- Assessment HUD: question/progress/timer/MCQ/input/image/submit and result summary, without altering game rules.
- Certificate card/preview, leaderboard row/my rank, video/source card, mentor portrait, AI panel.
- Consistent shadow/border/radius/typography, alignment, baseline spacing, contrast and long Uzbek translations. Current initial visual CSS: primary #2F6FD6; any brand change requires a separate approval.

## Правила разделения работы параллельных потоков
- Issue #531 **UI-only**. Other implementation agents work independently. Never blindly merge visual CSS into another agent’s pending module.
- Issue #450 controls Mathematics P1/P5 and related migrations. Treat live/DRAFT status from its current top checkpoint; do not change Stage, scoring, times, skill authority, schema or access.
- Issue #528 is parallel global release/integration context; do not merge or publish its changes from the UI issue.
- Existing academic governance: official syllabus authority, P1/P5 separate, written marks only if verified. AI cannot award marks or mastery.
- Plans/subject-access direction from docs/iclub-registration-tariff-choice-v2-approved-20261008.md is **design-only** when commercial flags/payment are OFF.
- No request in this roadmap authorizes database cleanup, reset, destructive migration, main merge or production deploy.

## Дизайн-приёмка по каждой итерации
Функции должны быть идентичны: количество шагов/кнопок может стать визуально проще, но каждый реальный исходный путь остаётся достижим. Требуемый экран не принимается если: есть несуществующая кнопка; исчезла возможность возврата; пользовательский текст выдаёт внутренний термин; RU/UZ/EN расползаются; есть горизонтальный скролл на 320px; нажатию доступен запрещённый функцией экран; пересчёт результата/сброс progress; Sketch/Stitch макет по ошибке назван production.

## Точка старта B00
1. Прочитать UI-MAP §A и реальные index.html строки #view-splash, #view-registration, app.js bindRegistration и Telegram recovery.
2. Получить screenshot реальной текущей регистрации **без данных пользователей** (или воспроизвести в isolated local/browser mock). Никаких prod DB writes ради screenshot.
3. Я готовлю **один полный Stitch prompt** для регистрации: school/non-school, RU/UZ/EN, disabled, empty, form validation, submit/connection/recovery.
4. Архитектор вставляет промпт в Stitch и присылает текст ответа + экраны/экспорт. При необходимости повторяем только визуальную правку.
5. Только после явного одобрения — отдельный Draft PR с кодом. B01 после B00.

**Продолжение:** см. 04-handoff-checkpoint-20261111.md и Issue #531. Никаких сроков по умолчанию, прогресс фиксируется фактами, а не календарём.
