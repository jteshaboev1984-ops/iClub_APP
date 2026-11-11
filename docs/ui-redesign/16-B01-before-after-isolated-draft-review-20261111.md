# B01 — визуальное сравнение «Было → Стало» и исходно-совместимый черновик
**Дата:** 2026-11-11 · **Issue:** #531 · **Этап:** реализация B01 в изолированном DRAFT, ожидает визуальной приёмки архитектора и независимого release GO.

## Решение архитектора и задача
После получения четырёх экранов Stitch B01 v2 архитектор согласился на самостоятельную CSS-адаптацию **только общей верхней и нижней навигации**, без третьего раунда Stitch, и попросил показать «как в прошлый раз, что было и стало». В середине обоих сравнительных снимков показана явно подписанная НЕИЗМЕНЁННАЯ нейтральная область вместо вымышленных данных Stitch. Сравнение основано на точном текущем HTML исходной `#topbar`/`#tabbar` и той же последовательности CSS, в вариантах до/после нового стиля.

## Отделённая реализация
- [DRAFT PR #535](https://github.com/jteshaboev1984-ops/iClub_APP/pull/535): `draft/b01-sapphire-shell-visual-20261111`.
- **Финальный проверенный head:** `74a89a81c62833fb4f93bc21d491d82aefe3a342`; базовый `main` `85297150a347e98deb8f1e1c58cfbfa2236aea03` (не изменялся).
- **Четыре изменённых пути:** `visual/iclub-shell-b01.css` (новый source-compatible CSS); `index.html` (только подключение CSS); `qa/b01-shell-visual-browser.cjs` (контролируемые скриншоты и assert); `.github/workflows/b01-shell-visual-qa.yml`.
- Реальный логотип `logo.png`, текст `iClub` / `Smarter together`, четыре исходных `button.tab`, их классы, source ID и обработчики остались без изменений.
- Убраны визуально выдуманные макетом Stitch иконки профиля/шестерёнки на Home и Study; единственная шестерёнка Profile — **показ существующего** `#topbar-action[data-action="profile-settings"]`, не новая кнопка. Уведомления — только на Home по оригинальному `app.js`, реальный badge 0 скрыт.
- Улучшения: Sapphire-иерархия бренда, мягкий контекстный topbar, 44×44 пиксельные кнопки действий, плавающий rounded dock с более заметным активным пунктом, одинаковые четыре колонки и подписи RU/UZ/EN, safe-area.
- Отдельно исключены active Registration, Splash, Certificate Verify из B01 CSS (не заменять B00 и не нарушать source visibility).
- Обновление `app.js`/`i18n.js`/Supabase, образовательных экранов, Practice, Tours, Exam Prep, данных пользователя **НЕ производилось**.

## Сравнительные изображения
GitHub Actions artifact `b01-shell-before-after-chromium` в [run #43028031391](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/43028031391), **SUCCESS**, SHA совпадает с code PR. Файлы `b01-before-home-ru-390.png` и `b01-after-home-ru-390.png`; `b01-before-study-nested-ru-390.png` / `b01-after-study-nested-ru-390.png`; `b01-before-profile-ru-390.png` / `b01-after-profile-ru-390.png`; `b01-after-home-uz-320.png`. В разговоре дополнительно собраны из точных PNG сравнительные листы `b01_nav_detail_before_after.png`, `b01_home_before_after.png`, `b01_study-nested_before_after.png`, `b01_profile_before_after.png`. НЕ утверждать, что это screenshot реального авторизованного Home: центральный контент **намеренно neutral** для проверки только shell.

## Chrome UI fixture — PASS и достоверность
Изолированное чтение **реального исходного HTML** `#topbar`/`#tabbar`, реального CSS, без загрузки `app.js` и без внешней сети. Фиктивно выставлены только существующие ожидаемые состояния по `app.js`. Проверено old vs new для: Home (badge 3), nested Study Back, Profile gear, UZ Home 320, UZ Ratings 375, EN badge 0 и EN 1440; Registration/Splash без нижних вкладок, Notifications Back. Отсутствие горизонтального overflow; RU/UZ/EN подписи четырёх вкладок `Главная/Учёба/Рейтинг/Профиль`, `Bosh sahifa/O‘qish/Reyting/Profil`, `Home/Study/Ratings/Profile`, каждый пункт >=44 px и подпись не обрезана на проверенных ширинах. Снимки снимаются после короткой CSS transition (260 ms): первоначальные промежуточные кадры давали ошибочные тёмные рамки; после ожидания состояние отображается верно.

**Важно:** Это браузерная геометрия и source-markup state fixture, НЕ полная авторизованная интеграция приложения с Telegram/Supabase и не проверка всей учебной логики. Отдельный реальный JS-runtime/staging E2E обязателен перед merge/release. Ничего не публиковалось.

## Что дальше
1. Получить решение архитектора по видимым снимкам **B01 «Было/Стало»**, не повторять Stitch, если нет конкретной претензии.
2. С учётом визуальной приёмки разрешить только безопасную staging/runtime QA в изоляции; не использовать реальные пользовательские аккаунты и не менять production.
3. Без отдельного **RELEASE GO** не объединять PR #535.
4. Следующий отдельный дизайн-блок — **B02 Home**, который даёт основной «вау» зарегистрированным учащимся; не переносить вымышленные данные из Stitch.
5. B00 отдельно в [Draft PR #534](https://github.com/jteshaboev1984-ops/iClub_APP/pull/534), также unmerged. Math #450 / integration #528 не трогать.
