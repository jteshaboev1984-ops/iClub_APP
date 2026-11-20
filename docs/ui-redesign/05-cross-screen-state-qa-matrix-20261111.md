# iClub APP — сквозная матрица UI-состояний и критериев проверки
UI-STATE-QA v1.0 · 11.11.2026 · Issue #531 · статус: CHECKLIST DESIGN ONLY

## ДОПОЛНИТЕЛЬНЫЙ GATE: ФУНКЦИОНАЛЬНАЯ ЭКВИВАЛЕНТНОСТЬ (решение архитектора 2026-11-11)

- [ ] В каждом блоке состав и назначение экранов, карточек, полей, кнопок и подтверждений до/после **совпадают**; новый UX-флоу не создаётся.
- [ ] DOM-контракты (ID, data-*, обработчики, focus/back, доступность controls) сохранены или до реализации предъявлено отдельное письменное согласование на чисто структурную замену.
- [ ] Действия, состояния, переходы, условия доступа, валидация, сохранение, результаты, длительности и UX-тексты не изменены; Stitch-придуманные функции отсутствуют.
- [ ] Изменения ограничены визуальным слоем (CSS/разрешённые декоративные элементы). Список изменённых файлов проверен на отсутствие незапрошенных логических правок.
- [ ] Сравнительное E2E before/after, включая ошибки, возврат, реальный/неучастник, mobile/desktop и три языка, подтвердило идентичную функциональность. До проверки статус **TODO**, не PASS.

## Принцип
Карта 01 фиксирует *что* может увидеть пользователь. Этот документ проверяет, *в каких условиях* и *что не должно поменяться*. До отдельного утверждения дизайна никаких runtime-тестов с изменением пользовательских данных и никаких live DB/Production writes. Ни одна строка ниже не означает «проверено». Статус по умолчанию **TODO**, а не PASS.

Обязательные базовые контексты:
- Новый школьник (выбрано 1/2 competitive); школьник с нулём выбранных subject chips; школьник с неполной географией.
- Не школьник; ранее зарегистрированный; аккаунт, привязанный к Telegram; старый черновик чужого ID.
- Competitive participant vs observer/nonparticipant; 0/1/2 competitive slots; Study subject pinned/unpinned.
- Субъект доступен / скрыт / снят; нет действующего тура / до старта / активен / завершён.
- Полный/пустой/исторический счёт; разные сезоны; валидный/невалидный сертификат.
- Exam Prep Mathematics P1/P5 **только при серверном доступе**, Econ/Chem test cohorts и unavailable states; AI ON/OFF/denied.
- Языки RU, UZ Latin, EN. Screen mobile 320/375/390 и desktop 1440; Telegram webview/iOS/Android/browser where test setup permits.

## Статусы

| Состояние | Где увидеть/проверить | Неизменяемая логика | Критерий UI |
|---|---|---|---|
| Загрузка первого запуска | Splash / returning profile | Никакой повторной регистрации существующих | Логотип/статус/без пустого белого экрана |
| Загрузка списка региона | Registration | District disabled до Region | Поле не прыгает при загрузке |
| Неверно заполненная форма | Registration | Server validation не отключать | Список обязательных полей понятен |
| Student/nonstudent switch | Registration | Реальная eligibility Tours сохраняется | Плавное появление только нужных полей |
| Уже связан Telegram | Registration recovery | Не перепривязать другой ID, не удалить историю | Безопасное и понятное подтверждение |
| Сохранение формы/повторный tap | Registration/support/settings | Нельзя сохранить дубль | Spinner, заблокированная кнопка, результат |
| Ошибка сети на первом входе | Global | Не сбрасывать last profile или drafts | Offline banner + восстановление |
| Пустой Home | Home | Никаких вымышленных достижений | CTA к доступным предметам |
| Предмет не выбран | Catalog/Subject Hub | Нет скрытого автоматического join | Ясный статический статус и доступная кнопка |
| Каталог/учебник не опубликован | Library / Books | Нет доступа к private/unpublished release | Нейтральное пустое состояние |
| Внешняя Telegram ссылка | Video/community/news | Маршрут и URL неизменны | Понимать, что откроется вне WebApp |
| Practice locked stage | Practice start | Существующие unlock gates | Отличать disabled от broken |
| Practice MCQ/input | Quiz | Формат и server correct-answer guard | Поле и кнопка не пересекаются с клавиатурой |
| Practice image | Quiz/review | Изображение не меняет ответ/таймер | Зум без потери контекста |
| Practice pause/stop | Quiz | Сохранение draft & pending ops | Предупреждение, подтверждение, возврат |
| Practice result/review/recs | Practice | Никаких фейковых правильных ответов/баллов | Источник ошибки/время и next понятны |
| Replacement of active topic drill | Practice | Нельзя потерять чужую или текущую попытку | Двухкнопочное безопасное подтверждение |
| Tour not yet live/ended | Tours | Точная дата из сервера | Правильный статус вместо активной кнопки |
| Tour active with timer | Tour quiz | 1 attempt, timer, anti-cheat untouched | HUD читабелен 320px |
| Tour anti-cheat strike | Tour quiz/result | Никаких новых правил/разрешений | Строго нейтральное ясное предупреждение |
| Tour connection loss during finalize | Tour result | Retry pending answers; score server-authoritative | «Сохраняется» ≠ «готово» |
| Participant leaderboard | Ratings | district/region/country, scores/time genuine | Панель «мой ранг» только для участника |
| Leaderboard search no results | Ratings | Фильтры/сортировка как в коде | Нулевое состояние, clear работает |
| Certificates locked/not issued | Cert list | Только после глобального закрытия | Не показывать кнопки скачивания без права |
| Public QR valid/notfound/error | Verify | Нет раскрытия приватных данных | Три разные визуальные реакции |
| Archive available/not | Archive | Нет рейтингового начисления | Различить «архив» и «активный тур» |
| Settings content language | Profile settings | Обязательная проверка точного data effect | Предупреждение соответствует фактическому поведению |
| Optional tariff hidden/visible | Profile plan | Никаких новых billing/privacy grants | Показ only if real capabilities |
| Support missing/too-short/duplicate | Support | Existing ticket flow + privacy | Без повторной отправки, сообщение адекватно |
| Exam Prep restricted | Subject Hub | Само наличие выбранного предмета не отменяет current beta gate | Никакого фальшивого «Начать» |
| Math P1 and P5 switch | Exam Prep | Раздельные ledgers/score/status | Не суммировать независимые компоненты |
| Exam Prep week work complete but correction due | Weekly | Status controlled by server | Не писать «всё освоено» при открытом retest |
| Written/external task | Exam Prep | Нет self-mark за метод | «Решение не проверено» там, где уместно |
| Hybrid Paper S4 only draft | Exam Prep | Нет production activation без owner GO | Отдельный макет с DRAFT watermark; не рисовать live entry |
| No mentor seat | Exam Prep | Core remains usable | Нет обязательной очереди ментора |
| AI disabled/limit/error | Global/Practice/Exam Prep | Нет выдуманной правильности/контента | Error/fallback не перекрывает обучение |
| Existing athlete/profile achievement | Profile | Нет пересчёта credentials | Прогресс и empty не подменяются |
| Change of UI language | All | Не меняет содержание попыток | 3 языка одинаковые функциональные CTA |
| Long Uzbek copy | All | Не усекать смысл | Без обрезания labels/ошибок/кнопок |
| Mobile keyboard and safe-area | All input screens | Не менять submit | Низ CTA, инпут и нативные кнопки видны |
| Back/root navigation | All routes | Назад не входит снова в завершённый quiz, сохраняет trial | Нет циклического перехода или dead-end |
| Refresh/Telegram reopen | In-progress flows | Existing user/account/session isolation | Состояния возвращаются без сброса |

## Проверочные маршруты (по порядку выполнения)
- [ ] FLOW-01: новая школьная регистрация RU, 1 subject, Home.
- [ ] FLOW-02: новая школьная регистрация UZ, 2 subject, ошибки формы и корректировка.
- [ ] FLOW-03: не школьник EN → Study → Practice, Tours denied, Ratings observer.
- [ ] FLOW-04: зарегистрированный Telegram account, safe reopen и восстановление.
- [ ] FLOW-05: Home → Catalog → Subject → Mentor/Books/Video → Back.
- [ ] FLOW-06: Practice enter → stage/topic choice → quiz MCQ & input → pause/resume → result → review/recs.
- [ ] FLOW-07: Practice failed network and retry, draft ownership, no answer loss.
- [ ] FLOW-08: Tours closed/rules/active/result/review; exact anti-cheat and timer states in synthetic mode.
- [ ] FLOW-09: Ratings season/scope/filter/search, participant/observer.
- [ ] FLOW-10: Profile main/settings RU/UZ/EN/subject slots/credentials and safe back.
- [ ] FLOW-11: Support 8 topics → FAQ → send missing/duplicate/success state with nonproduction test data.
- [ ] FLOW-12: Notifications unread/read/delete one/all/empty.
- [ ] FLOW-13: Certificates list → viewer/preview → export; public QR verify valid/invalid/error; Archive.
- [ ] FLOW-14: Math Exam Prep P1 and P5 distinct, Core AI=OFF, entry/diagnostic/tracker/weekly/retest.
- [ ] FLOW-15: Math optional Extra Hard, assessment result and missing mentor/AI state; Hybrid S4 only if separately released.
- [ ] FLOW-16: Econ beta path P1/P3 entry/plan/full MCQ/history, written only with access.
- [ ] FLOW-17: Chem Entry/P1/recheck/labs only if server access, otherwise «в разработке».
- [ ] FLOW-18: global AI panel open/close, missing allowance/network fallback, no effect on scores.
- [ ] FLOW-19: all four tabs and all modal/back controls on 320/375/390/1440 with RU/UZ/EN.
- [ ] FLOW-20: legacy content/practice/tour/certificate unchanged when new CSS is disabled; compare before/after screenshots.

## Приёмка отдельного блока
| Gate | Прежде чем поставить PASS |
|---|---|
| Source | Записан SHA и список оригинальных действующих screen selectors |
| Visual | Все ID блока из UI-MAP включены или мотивированно исключены; архитектор одобрил |
| Text | Все видимые строки RU/UZ/EN в ожидаемой иерархии; несоответствия отдельно |
| Functional | Back/exit/resume/auth/assessment rules не менялись |
| No data loss | Пользовательская история и local drafts неизменны, никакой live destructive SQL |
| Responsive | 320×720, 375×812, 390×844, 1440 без горизонтального скролла |
| Evidence | Обезличенные screenshots + exact SHA/CI/proof и Preview URL |
| Approval | Owner отдельно одобрил дизайн, отдельно release; до этого Draft PR |

**Главное:** таблица не является отчётом о прошедших тестах. Она станет чек-листом для каждого блока и финальной B14.
