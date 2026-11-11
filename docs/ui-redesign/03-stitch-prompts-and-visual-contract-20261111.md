# iClub APP — Stitch handoff, дизайн-контракт и шаблоны промптов
UI-STITCH-CONTRACT v1.0 · 11.11.2026 · Owner: архитектор iClub · Tracker Issue #531

## 1. Способ связи без MCP
**Architect → ChatGPT → готовый prompt → Architect копирует в Google Stitch → Architect присылает ответ/экспорт/скриншот → ChatGPT проверяет → Architect утверждает → отдельный кодовый PR → QA → отдельное разрешение на публикацию.**

GitHub подключён к ChatGPT. Google Stitch не имеет прямых прав читать repo, Supabase, настоящие персональные данные, сертификаты и результаты. API keys, MCP и Codex **не являются условием работы**. Если Stitch вернул только картинку, это дизайн-reference, не готовая функциональная реализация.

## 2. Что ChatGPT обязан собрать ДО каждого Stitch prompt
1. Название/ID блока из 01-screen-inventory и 02-ux-blocks-roadmap.
2. Актуальный source SHA и исходный реальный экран, HTML/CSS/JS-селекторы и скриншот. Отдельно отмечать DRAFT/GATE/EXT.
3. Список реальных пользовательских действий, ограничения, логика back/exit/resume и сохранения.
4. Пустые, активные, завершённые, locked/loading/error/offline и permission states. Проверить не только одну счастливую ветку.
5. Согласованная палитра, логотип и типографика; существующий app-shell, если уже утверждён.
6. Вычитанные тексты RU/UZ/EN. Сомнительные исходные тексты вынести на отдельный COPY-QA, а не менять логику.
7. Ясное содержимое экранов; никаких исходных token/credentials/ID реальных учеников.
8. Явные границы: **редизайн, не новая функция**. Список запрещённых преобразований.

## 3. Базовый визуальный контракт
- Позиционирование: современное образовательное приложение, чисто, спокойно, логично, аккуратно; без перегруженных карточек, искусственных наград и техножаргона.
- Предпочтительно сохраняем существующий iClub brand, logo, текущую синюю основу и общий app-shell до отдельного решения архитектора. Текущий CSS токен --primary: #2F6FD6; не менять бренд автоматически.
- Canvas: основной mobile 390×844, стресс 320×720, проверка 375×812, desktop 1440; Telegram safe-area сверху/снизу, клавиатура в формах, без горизонтального скролла.
- Сетка/симметрия: единые отступы, высота контролов, вертикальная иерархия, одинаковые радиусы и выравнивание иконок/подписей. Длинные RU/UZ строки не обрезать.
- Навигация: всегда доступный корректный назад (если не запрещён active Tour), нижние четыре вкладки только там, где действующая логика их показывает. Не генерировать новую навигацию/пункты.
- Доступность: достаточный контраст, touch targets около 44px, ясно видимый focus, читаемые disabled/loading/error states, текстовые статусы вместо одной цветовой маркировки.
- Языки: RU, UZ Latin, EN; UI language и content language — разные сущности; не подменять существующие последствия переключения языка.
- Content truth: не придумывать прогресс, ранг, баллы, stage, расписание, availability, платёж или программу Cambridge. Для дизайн-макетов только подписанные вымышленные примеры.
- Никаких терминов для учеников: ledger, feature flag, state machine, evidence gate, beta transport, SQL, MCP, лесенка и пр.
- Профиль/сертификат/рейтинг: не допускать имитации реального человека и использования реальных данных.

## 4. Стандарт одного промпта для Stitch (ChatGPT выдаёт заполненную версию)

STITCH PROMPT BEGIN
Project: iClub APP — existing Telegram WebApp / mobile web, plain HTML/CSS/JS.
Task: visually redesign the EXISTING [BLOCK ID / SCREEN NAME] without changing user logic.

Current screen and user flow: [exact current description].
User types and authorized visibility: [student/nonstudent/competitive/active subject/feature gate].
Real actions and destinations: [controls and Back rules; no new actions].
Required screen variations: [enumerated actual variants and states].
Existing components/brand: [approved palette, header, tabbar, typography/logo].
Responsive targets: 390x844 main, 320x720 stress, 375x812, 1440 desktop. Telegram safe-area and on-screen keyboard.
Languages: Russian, Uzbek Latin, English. All headings, fields, validation and primary CTAs should fit naturally.
Visual goals: clean clear hierarchy, aligned cards and controls, symmetric spacing, distinguish primary/secondary actions and error/locked/empty states.
Important restrictions: no new features, fake progress/scores, account reset, payment UX, changed assessment rules, AI grading, invented links, renamed subjects, or extra student steps. Show only allowed states. Do not reproduce private learner data.
Deliverables: (1) named mockup for EVERY requested state, (2) succinct visual/component decisions, (3) interactions/Back annotation, (4) responsive notes, (5) export HTML/CSS/assets when available. Explicitly identify anything you could not represent. Label sample figures as mock data. Do not merge or deploy code.
Source screenshots/notes: [provided separately, all anonymized].
STITCH PROMPT END

**Правило:** это технический шаблон, НЕ автоматически готовый промпт. Для B00 ChatGPT должен заменить все квадратные поля проверенным содержимым и дать единый копируемый законченный текст.

## 5. Что присылает архитектор обратно
Достаточно **ответа Stitch + скриншота(ов)**. Если Stitch дал Export HTML/CSS, ZIP или ссылку проекта, это ускоряет точную адаптацию; не обязательно для согласования идеи. Не пересылать API-ключи, продовые env, приватный source-контент или файлы с реальными ученическими результатами.

Я сравниваю с изначальной функцией по таблице:
- **экран есть:** yes/no, с точным ID;
- **все состояния:** yes/no;
- **логика/права:** unchanged/accidental invention;
- **RU/UZ/EN:** fits/copy concern;
- **компоненты/симметрия:** pass/revision;
- **mobile/desktop:** pass/revision;
- **безопасность:** no real data/no secrets;
- **результат:** ACCEPT DESIGN / REVISE STITCH / HOLD for missing source.

Если есть замечания — отдаю **корректирующий промпт** с конкретными изменениями, не перезапускаю проект без необходимости.

## 6. Условия внедрения после дизайна
- Только после явного «Утверждаю дизайн Bxx».
- Фиксировать exact GitHub SHA, branch, scope CSS/HTML, «что НЕ меняется».
- Не вставлять автоматически Stitch React/Next.js в обычный HTML/JS iClub. Переносить визуальную структуру, а не переписывать приложение.
- Дизайн изменяется в отдельной Draft PR, main/production не трогать; особенно не использовать прямые live Supabase writes ради макетов.
- В сложных маршрутах сначала synthetic preview, потом реальная браузерная/роль-based acceptance; сохранить route/back, dark overlays, saving indicators, server-truth, identity segregation.
- Не переделывать результаты, таймеры, Supabase RLS, пробелы в i18n, пользовательский прогресс или начисление сертификатов как побочные эффекты «красивого UI».
- API/AI capability gates остаются как в источнике, а проектные будущие тарифы не превращаются в действующее предложение.

## 7. Шаблон фактического handoff после блока (для Issue #531)
BLOCK: Bxx
SOURCE SHA: ...
BASE/HEAD branch: ...
REAL SCREENS/VARIANTS INCLUDED: [ID list]
NOT INCLUDED (reason): ...
STITCH INPUT (saved prompt): [permalink / complete copy]
STITCH OUTPUT (owner supplied): [file/screenshots/summary]
OWNER DESIGN DECISION: [approved / revisions / pending]
CODE PR: [draft URL or none]
QA: [tested dimensions + locales + functional paths, failures or pending]
MAIN/PROD: unchanged unless separately authorized
NEXT: one concrete action.
Make the **newest approved checkpoint the first line of Issue #531**, older checkpoints historical.

## 8. Ближайшая задача — B00
На первом следующем сообщении, если архитектор пишет «Начинаем B00», ChatGPT читает index.html регистрацию и app.js bindRegistration, после чего выдаёт **готовый, самостоятельный prompt для Stitch на русском с инструкциями для генерации интерфейса** (можно написать сам prompt на английском ради распознавания инструментом; все реальные UI надписи RU/UZ/EN сохраняются). Включить школьник/не школьник, subject chips 0–2, зависимые region/district, consent, loading, error и Telegram recovery. Не просить пользователя выполнять кодовые действия.
