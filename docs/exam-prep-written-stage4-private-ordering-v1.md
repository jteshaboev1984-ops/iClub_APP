# iClub Exam Prep — Stage 4: закрытая последовательная письменная практика

**Дата:** 22.10.2026  
**Итог:** PRIVATE BACKEND INSTALLED / ECONOMICS NO-GO.  
**Production:** действующие Mathematics, Practice, Tours и клиентские маршруты не изменялись.

## Фактическое состояние после сверки параллельных изменений

Почти одновременно были установлены две миграции Stage 4:
- `20261022152815_iclub_exam_core_written_sequential_navigation_v1.sql` — основная серверная последовательность, вызовы и ограничение на один активный план;
- `20261022152858_iclub_exam_core_written_ordered_path_private_v1.sql` — альтернативные закрытые функции и второе ограничение плана.

Чтобы исключить двойную реализацию, установлена третья миграция
`20261022153349_iclub_exam_core_written_concurrent_stage4_consolidation_v1.sql`.
Она удаляет **только дубликаты второй миграции**, после проверки отсутствия назначенных учеников, планов и шагов. Исторические миграции остаются в GitHub и Supabase; ни одну не скрывали и не переписывали.

## Единый текущий серверный маршрут

`private.iclub_exam_core_written_plan_next_v1(uuid)` →  
`private.iclub_exam_core_written_open_v1(uuid,text)` →  
`private.iclub_exam_core_written_criteria_v1(uuid,text,text,uuid,text)` (необязательно) →  
`private.iclub_exam_core_written_advance_v1(uuid,text,text,uuid,text)` →  
`private.iclub_exam_core_written_status_v1(uuid,text,text,uuid)` (восстановление).

Все эти операции закрыты в private schema и имеют service-role-only EXECUTE; публичных student endpoints нет. `advance_v1`, `open_v1` и `criteria_v1` теперь проверяют порядок шага. `advance_v1` требует предварительное `opened_at`; повторный вызов не создаёт повторного продвижения. Единственный активный план на ученика/программу/версию обеспечен индексом `iclub_exam_core_written_one_active_plan_v1`.

**Правило:** «Далее» фиксирует только прохождение письменного учебного шага. Не записываются эссе, фотографии, оценки, mastery, AI-решения или mentor task. Обычная письменная практика не является полноценным проверенным пробным Paper 2/4.

## Проверено в живой Supabase после консолидации

| Проверка | Результат |
|---|---|
| Активный индекс на план | ровно 1 |
| Канонические private-функции | 5 |
| Дублирующие функции | 0 |
| Доступ `anon/authenticated` к `plan_next` | отсутствует |
| Доступ `service_role` к `plan_next` | есть |
| Экономика | `draft`, `launch_enabled=false` |
| Письменные задания | 22 черновика, 0 выпущенных |
| Learner plans / plan items / access | 0 / 0 / 0 |
| Mathematics sessions / responses | 543 / 1 976 |
| Practice attempts / answers | 502 / 4 816 |
| User-subject selections | 2 098 |

Числа истории сверены с переданным baseline; это не полноценные построчные хеши. Не выполнены authenticated happy-path, cross-user, concurrent-click, offline-recovery и browser QA.

## Блокировки и следующий инженерный шаг

1. Подготовить `native` генератор плана с проверяемым порядком, индивидуальными правилами AS/A Level и версиями заданий; не использовать старые Mathematics plan tables.
2. Создать защищённый learner transport в отдельном тестовом контуре. Нельзя передавать `service_role` в браузер или открывать student access без проверки прав и полного пути.
3. Академически проверить и локализовать все 22 P2/P4 черновика (EN/RU/UZ); добавить правильные источники данных Section A, графики и точные требования, не копируя защищённый контент.
4. Проверить реальные тестовые JWT, доступ разных пользователей, идентичность статуса после обрыва связи, двойной «Далее», порядок шагов и включение/отключение режима.
5. Провести E2E в существующем математическом дизайне и отдельный MCQ academic QA (1644 кандидата) до release decision.

**NO-GO:** Экзаменационный Economics не включать. Дополнительные функции не импортированы в `index.html`, пользовательский путь не доступен; нельзя объявлять Vercel READY свидетельством завершённого Exam Prep.
