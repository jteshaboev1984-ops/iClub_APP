# iClub AI Layer v2.1 — integrated Home → Study → Home QA

**Дата:** 15 октября 2026. **Пакет:** §§110–113. **Технический статус:** GREEN в автономной QA. **Продуктовый статус:** Global AI OFF / NO-GO; реальные пользователи не подключены.

## Итог пакета

Объединена полная цепочка **выданная Home-рекомендация → одноразовое подтверждение §108 → проверка цели §109 → новое ограниченное разрешение на конкретный экран → повторная авторизация каждого чтения → отзыв при возврате Home**. Весь путь выполняется лишь на localhost GitHub Actions и временной PostgreSQL. Текущие `app.js`, `index.html`, `i18n.js`, `style.css`, Mathematics Exam Prep, production AI-оболочка и тарифные экраны не редактировались.

### Авторизация при переходе

В `qa/ai-layer-v21-p6-study-route.cjs` (`openSyntheticStudy`) впервые имеется **собственная** краткоживущая экранная scope-запись, а не повторное использование Home context. Токен — случайный непрозрачный 192-битный bearer, на сервере только SHA-256; отдельная новая таблица `private.iclub_ai_v21_study_routes_scratch` создана строго для одноразовой CI-БД, запрещена для `anon/authenticated`. Учебный объект берётся **только из заверенного Home-плана**; клиент не присылает session, attempt, evidence ID, grades, answer keys, хеши или target route.

Для открытия применены два уровня: адресная независимая §109-проверка, а затем **один финальный SQL statement**, который ещё раз читает актуальные owner/context, полный SQL Home authority gate, источник, commercial entitlement, выбранный study/competitive slot и существование исходного академического объекта; этот же statement создаёт одно новое право перехода и переводит *искусственный* current-screen pointer из Home в отдельный Study scope. Уникальность исходного Home-handoff запрещает два активных назначения из одного подтверждения. Если повторная проверка или конкурентный screen move не прошли — отказ.

### Независимая серверная авторизация данных на экране

`readSyntheticStudy` больше **не использует Home-контекст как разрешение**. Единственным действующим указателем служит отдельный route-context с owner, revision, локалью, subject, конкретным action/object и коротким TTL. Каждый read выполняется единым свежим SQL snapshot и проверяет: активный Study screen; действующий server bearer; предмет и mode; коммерческое `enforced`; отобранный slot; source rights, content approval, version и digest; валидное Practice/Tour evidence или study enrollment; глобальное закрытие AI и active protected assessment. В ответе только target type/subject и, для завершённой Practice, безопасное количество ошибок из **синтетической** записи. Никаких конкретных question IDs, ответов, персональных оценок или произвольных client-specified академических объектов.

`closeSyntheticStudy` отзывает токен и безопасно возвращает экранный контекст на Home с увеличенной версией. Повторное закрытие и повторное чтение закрытого scope запрещены. Пока ученик находится в Study, старый Home-контекст не работает; после выхода новый Home-план должен быть вычислен заново. Чтение не меняет академическое evidence.

### Полный QA-путь в интерфейсе

Локальный `qa/preview_v21/home-pg-local.html` показывает пользователю понятную последовательность на RU/UZ/EN: проверить следующий шаг, подтвердить выбор, открыть раздел, увидеть разрешённую **read-only** сводку нужного предмета или Practice/Tour и вернуться назад. Тексты учебного экрана не содержат внутренних идентификаторов. Симметричные кнопки, подписанные действия, доступные заголовки и отсутствие горизонтального overflow проверены native Chromium на смартфоне/десктопе. Это **не** изменение реального приложения и **не** публикация editorial copy.

### Изолированные проверки и безопасность

`qa/ai-layer-v21-p6-study-route-http.test.cjs` проверяет неиспользованный Home token, повторное открытие, owner/locale/subject подмены, клиентский `objectId`, source-rights revocation после входа, отмену evidence Practice, отзыв subject selection, protected assessment, реальный для синтетической БД Tour archive, конкурентный режим предмета, возврат и необратимый отзыв route bearer. Дополнительно `qa/ai-layer-v21-p6-study-route-race.cjs` запускает **два независимых worker threads и два отдельных `psql` процесса** одновременно против одной строки: ровно один учебный экран создан, второй отказан, Practice evidence не изменилось.

Тесты старого Home с преднамеренным отзывом контекста и нового Study со сменой экранной ревизии разнесены по **двум независимым одноразовым PostgreSQL базам**. В промежуточном run #330 старая проверка корректно выявила зависимость тестов от общей synthetic revision. Восстановление реальных или тестовых записей «по ходу» не применялось: вместо этого тестовые окружения изолированы. Run #331 подтвердил этот подход; run #332 добавил проверку двух независимых исполнителей.

**Контрольное доказательство:** [GitHub Actions #332](https://github.com/jteshaboev1984-ops/iClub_APP/actions/runs/38693320501) — `completed/success`, **649/649 Node**, **14/14 independent PostgreSQL scratch suites**, старый Home HTTP test PASS, второй отдельный Study PostgreSQL + Chromium RU/UZ/EN и Study HTTP test PASS, `HOME_STUDY_TWO_WORKERS_GREEN`, Deno, две ранее существовавшие гонки и frozen/protected-file gates PASS.

## Нельзя путать с production-ready

- HTTP Bearer использует известные **только QA** test tokens; signing key — синтетический test fixture. Ни один из них не является JWT/Supabase Auth, не может использоваться в реальном сервисе.
- `private.iclub_ai_v21_study_routes_scratch` существует **только в disposable CI**; SQL не является утверждённой миграцией. Не выполнялось подключение к реальному `app.js` / Routes / Practice/Tour API и не внедрялась production Edge Function.
- Предметные доказательства и редакционно разрешённые источники в тесте — самостоятельные синтетические записи. Это не доказывает фактическую governance publication в production Supabase.
- Один атомарный test SQL entry и свежий read snapshot не заменяют настоящую транзакционную авторизацию всех API конечного экрана в live Supabase. При смене экрана требуется отдельное подписанное server context proof, не Home bearer.
- `reviewCount` взят исключительно из искусственного результата. Настоящие учебные данные и вопросы не читались; AI модель не вызывалась, расходы равны нулю.
- Core должен функционировать с AI=OFF без изменения учебных результатов, независимо от этого экспериментального AI маршрута. Нельзя подключать его в production, пока не доказано обратное отсутствие зависимости.
- Новая Supabase branch по прямому решению архитектора **не создавалась**. `main`, домены/Vercel production, реальные таблицы, миграции, тарифные UI, Mathematics Tutor, `localStorage` учеников и сохранённый прогресс не изменялись.

## Следующая производственная зависимость (единый release gate, а не микроэтапы)

Для настоящего подключения нужен **один отдельно разрешённый интеграционный выпуск**: актуальная live metadata-only сверка commercial и rights функций; approved source publication; real auth/owner + scoped context issuance в серверном trusted Edge/Supabase endpoint; независимая per-read destination API authorization и RLS/privilege review; protected integrated Preview с невозможностью изменять настоящую историю; smoke Core AI-OFF parity, RU/UZ/EN, accessibility, rollback/kill switch и отрицательные ревокации; отдельное разрешение архитектора. Пока это отсутствует, итог **Global AI OFF / NO-GO**.

Нельзя заменять настоящую авторизацию HTML-переходом или выдавать результат offline QA за выпуск функции реальным ученикам.
