# B00 — Исходно-совместимая двухшаговая регистрация: контрольная приёмка локального E2E

**Дата:** 2026-11-11 (Asia/Tashkent)  
**Tracker:** [Issue #531](https://github.com/jteshaboev1984-ops/iClub_APP/issues/531)  
**Implementation:** [Draft PR #534](https://github.com/jteshaboev1984-ops/iClub_APP/pull/534) `draft/b00-registration-two-step-visual-20261111`, **SHA `8f546f1f21bd75662fa86025ac9e8e65d1ab7848`**  
**Base main:** `85297150a347e98deb8f1e1c58cfbfa2236aea03`  
**CI:** [Actions run #43011874638](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/43011874638), **SUCCESS**; artifact `b00-registration-visual-qa-screenshots` contains 10 PNG.  
**Статус:** визуальный черновик реализован и mock-runtime QA пройден; **real staging/authenticated E2E & separate owner RELEASE GO PENDING**. НЕ merged, НЕ production.

## Принятое исключение
По решению архитектора регистрация отображается в двух визуальных шагах, сохраняя единую существующую форму и исходный обработчик сохранения. Переключение шагов — минимальное presentation-only взаимодействие; не вносить изменения в Supabase, схему, регистрационные правила и пользовательские данные. Третий корректирующий промпт Stitch исключён как необязательный.

## Реализовано в отдельном Draft PR
1. `index.html` — только подключения нового CSS и JS (4 добавленные строки), никакой замены исходных полей.
2. `registration-b00-ui.js` — точные исходные DOM-элементы существующего `#reg-form` без клонирования разделены визуально: Step 1 = язык/ФИО/регион/район; Step 2 = школьный статус/условные школа-класс-предметы или информационная карточка/согласие/старый Submit. Navigation Next и Previous не вызывают новый save; topbar Back как прежде закрывает приложение.
3. `visual/iclub-registration-b00.css` — все правила scoped только для B00; чистый двухколоночный выбор предметов, адаптивные отступы, исходный бренд и safe-area.
4. `qa/registration-b00-browser.cjs` + `qa/registration-b00-real-app-mocked-e2e.cjs` — изолированные проверки Chromium.
5. `.github/workflows/b00-registration-visual-qa.yml` — автоматическая CI-проверка Ubuntu 24.04/Chromium, без обращения к производственной БД.

## Проверенные сценарии
**1. Реальный markup, изолированный browser test:** 320 / 375 / 390 / 1440px; один исходный `#reg-form`, один Submit, исходные option 7–11, обязательные поля, блокировка Next до выбора района, поля не теряются при возврате, Enter не вызывает раннюю регистрацию, единственная финальная отправка, RU/UZ stage labels, overflow=0. **PASS**.

**2. Реальный `app.js` + `i18n.js` в браузере, но Supabase/Telegram полностью подменены локальными stub:** 
- RU, 390px, школьник с 2 competitive subjects → fake users upsert once + fake user_subjects 2 rows, переход Home. **PASS**.
- UZ, 375px, школьник с 1 competitive subject → fake users once + 1 competitive row, переход Home. **PASS**.
- EN, 320px, нешкольник → fake users once, **нет** выбора competitive/нет user_subjects rows, переход Home. **PASS**.
- EN, 390px, synthetic users-save-failure → штатное однокнопочное предупреждение, без перехода Home, без subject writes. **PASS**.
- RU, 390px, synthetic Telegram duplicate unique-constraint → штатный recovery-modal с ровно `Отмена` и `Восстановить профиль`, источник регистрации не подменяется вымышленным login screen. **PASS**.
- После school ON→OFF→ON восстановлена актуальная сводка выбора **без изменения самих сохранённых значений или правил**. **PASS**.
- Отдельный check geometry: индикатор и заголовок Step2 находятся **ниже** sticky topbar; cross-viewport/full-page screenshots. **PASS**.
- **No external requests** (blocked external destinations = 0), no unexpected JS page errors. **PASS**.

## Выявлено и устранено внутри B00
- 320px horizontal overflow от существующего скрытого `#reg-is-school` select, наследовавшего видимую ширину. Исправлено scoped-CSS скрытого технического поля.
- Next мог быть запущен до загрузки обязательного District — разрешён только при enabled и валидном обязательном поле.
- При школьник→нешкольник→школьник исходный выбор корректно очищался, но визуальная summary могла оставаться устаревшей — после события переключения вызывается **существующий** renderer, без новой бизнес-логики.
- `progress.scrollIntoView(start)` мог визуально перекрываться sticky topbar — заменён на возврат scroll к началу, добавлен геометрический тест.
- Изначальные ошибки QA fixture исправлены отдельно, **без изменения бизнес-логики**: DOM-order предметов (а не click-order), невидимый checkbox управляется визуальным switch label.

## Достоверность и оставшиеся обязательные gate
- **Проверено:** исходный `app.js`/i18n runtime в Chromium, но auth, rows, RPC и persistence — **FAKE** в одном тестовом процессе. Это не авторизованный запрос к реальному Telegram или Supabase.
- **НЕ проверено:** настоящая анонимная сессия, RLS/JWT, сохранение в реальной тестовой PostgreSQL/Supabase, фактический Telegram initData, принудительное восстановление между устройствами, реальные сетевые сбои и доставка уведомлений.
- **Ничего из этого не делается на production**; для полного подтверждения нужна отдельная изолированная тестовая база/аккаунт и её разрешение. Не использовать настоящие профили/учебный прогресс для QA.
- Pre-existing copy ambiguity о языке заданий, уже отражённая в Issue #531, **не исправлена** под видом редизайна.
- **Не вливались** PR #534 или документы PR #532. Остальные задачи #450 и #528 не затрагивались. **Не публиковать до отдельного GO**.

## Следующая точная задача
В новом чате начать **с проверки текущего HEAD PR #534 и последнего CI**, не повторять инвентаризацию и уже зелёный mocked runtime. Затем решить только оставшийся release-gate: изолированный real backend/auth/Telegram E2E при наличии безопасного стенда и разрешения; после этого запросить решение архитектора о визуальном утверждении и публикации. Параллельно можно начать дизайн B01 без изменения рабочего приложения, но не считать B00 уже выпущенным.
