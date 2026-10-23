# iClub APP — Stage 5A: Universal Native Weekly Plan (Economics 9708)

**Дата:** 23.10.2026  
**Статус:** DORMANT DETERMINISTIC CORE + TEST FIXTURES. **НЕ production workflow, НЕ beta, НЕ academic content release.**

## 1. Задача и фактически реализованные файлы

Эта фаза связывает **проектирование общего учебного плана** Economics с действующим письменным Core, не подключая к ученикам ещё не проверенный академический банк.

Файлы на существующей ветке `main`, без создания новой ветки:
- `exam-prep/runtime/native-weekly-plan-core-v1.js`: отдельная функция `buildPlan(input)`, не импортирована в production `index.html`, не обращается к Supabase, не мутирует входные данные и ничего не сохраняет.
- `scripts/qa-native-weekly-plan-core-v1.cjs`: автономные безопасные фикстуры; **20 PASS** при выполнении извлечённых из GitHub файлов в изолированном JS test-runner. Запуск в Node CI пока не подтверждён.

Библиотека возвращает **внутреннее предложение недельного плана**, а не опубликованный, сохранённый или назначенный ученику план. Выход всегда `release_authorized=false`, а отсутствие одобренного контента обозначается `no_approved_study_steps`, **никогда** как «ученик завершил программу».

## 2. Единый учебный путь, разные доказательства

| Тип действия | Роль | Может ли одно действие подтверждать mastery? |
|---|---|---|
| Diagnostic | Входная проверка конкретного Paper | Только по утверждённой серверной evidence policy; не от планировщика |
| Theory | Изучить концепцию/пререквизит | Нет |
| MCQ | Объективная практика P1/P3 | Только после отдельной серверной проверки |
| Written | Самостоятельная практика P2/P4 | Нет; «Далее» = навигация |
| Correction | Разбор подтверждённой ошибки | Нет без новой проверки |
| Retest | Повторная проверка | Только по новому, независимому серверному evidence |
| Mixed / Timed | Смешанные и ограниченные временем задания | Только утверждённым проверяющим, с правильным Paper |
| Paper | Цельный пробный экзамен | Письменные результаты остаются unverified без реальной проверки |

Core не выводит самозачёт эссе, оценку AI, Cambridge grade, «готов к экзамену», перевод mastery между Paper или автоматическое повышение stage.

## 3. Вход `buildPlan`: только серверно проверенный snapshot

```js
{
  program_key: "economics_9708",
  program_version: "economics_2026_2028_v1",
  route: "AS" | "staged" | "linear",
  target_papers: ["P1", "P2"], // точный экзаменационный выбор
  locale: "en" | "ru" | "uz",
  budget: {
    total_student_minutes: 540,
    economics_minutes: 180
  },
  max_items: 10,
  paper_state: {
    P1: {stage: 2, diagnostic_verified: true},
    P2: {stage: 2, diagnostic_verified: true}
  },
  focus: [{paper_code:"P1", skill_key:"..."}],
  corrections: [{paper_code:"P1", skill_key:"..."}],
  retests: [{paper_code:"P1", skill_key:"..."}],
  catalog: [
    // Only server-sourced, approved, released task metadata:
    // program/version, paper, kind, task/version, skill, duration,
    // link_role, status/mapping_status, locale/source/security gates,
    // checking_contract.
  ]
}
```

Это формат технического прототипа, **не публичный API**. Никакие `paper_state`, `focus`, исправления, доступы, оценки, длительности, статусы публикации и academic checks нельзя доверять из браузера. Их поставляет сервер, после проверки пользователя, программы, версии, разрешений, каталогов, источников и доказательств. Пока такого транспортного сервиса нет.

`route=AS` допускает только P1/P2. `staged` и `linear` требуют явного `target_papers` и могут включать P1/P2 при подтверждённой пересдаче; компонент не включается автоматически лишь потому, что он есть в A Level. Функция не переводит результаты AS в P3/P4. `link_role=prerequisite` допускается лишь для Theory, без зачёта навыка в другом компоненте.

`budget.total_student_minutes` — вся самостоятельная недельная нагрузка ученика, `economics_minutes` — только планируемое время Economics. Нельзя предлагать Economics больше общего времени. Планировщик не придумывает пропорции распределения между Paper: чередует предложенные действия в порядке явно выбранных Paper. Общая вместимость определяется проверенными длительностями заданий и переданным бюджетом.

## 4. Детерминированный алгоритм

1. Проверить профиль программы, маршрут, Paper, язык, бюджет, stage 0–6 и форму подтверждённых сервером учебных рекомендаций.
2. Отобрать **только** опубликованные, академически/языково/технически проверенные материалы со статусом `approved`, `mapping_status=approved`, разрешённой версией, готовыми `ru/uz/en`, доступным источником и безопасной проверкой.
3. При отсутствии достоверной диагностики компонента предложить доступную диагностику и не перескакивать к оцениванию поздних стадий.
4. Для этапа 2+ предложить due retest, работу над подтверждённой ошибкой, изучение заданного навыка и профильную практику (MCQ для P1/P3; письменную для P2/P4).
5. В соответствии с отдельно подтверждённым stage добавлять mixed (3+), timed (4+), paper rehearsal (5+). Стадии автоматически **не повышаются**.
6. Чередовать выбранные Paper без заранее навязанного соотношения часов, не превышать недельную доступность и лимит задач.
7. Если утверждённого материала или времени недостаточно, вернуть явную причину блокировки, **не считать отсутствие заданий завершением курса**.
8. Вернуть машиночитаемый draft с `evidence_rule` на каждом шаге. Никаких side effects, grade, mastery, ready/not-ready или DB writes.

Распределение ошибок и retest — только на основе предоставленного сервером подтверждённого журнала; клиентская отметка «прочитал/сделал» не создаёт объективного evidence.

## 5. Что показали реальные read-only проверки Supabase

| Объект | Состояние на 23.10.2026 |
|---|---|
| Economics canonical skills | 498; `approved=0` |
| Paper-skill associations | `approved=0` |
| MCQ candidate links | 16; `approved=0` |
| Written P2/P4 | 22 draft; `release_enabled=0` |
| Economics learner written plans/items | 0 / 0 |
| Флаг экономики | `draft`, `launch_enabled=false` |
| Mathematics Exam Prep sessions/responses | 543 / 1 976 |
| Legacy Practice attempts/answers | 502 / 4 816 |
| User-subject selections | 2 098 |

Следовательно, **сегодня невозможно составить настоящий содержательный ученический недельный план из approved Economics content**. Система должна возвращать blocker, а не незаметно использовать `candidate` MCQ и EN-only эссе.

## 6. QA и границы достоверности

20 тестов охватывают: published/approved gating, first diagnostic, порядок Theory/MCQ/Written, проверку письменного незачёта, staged AS resit, запрет прямого зачёта prerequisites в A, пропуск неопубликованных/неполных языков, error→retest priority, стадии 0–6, отказ от автооценки письменного Paper, баланс между Paper, лимит недельного времени, запрет фальшивой готовности, детерминированность и неизменность входных данных.

Проверены тесты на **точном содержимом созданных GitHub файлов** в изолированном JavaScript окружении; это не заменяет Node CI, настоящую авторизацию, browser/mobile UX или реальное выполнение server-side plan.

Код **не импортирован** в `index.html`, поэтому не выполняется у действующих учеников. Действующие RPC, Mathematics, Practice, Tours, localStorage, история попыток и оценки не менялись.

## 7. Следующий Stage 5B: перевод внутреннего предложения в реальный защищённый план

1. Определить и реализовать серверно принадлежащий источник `paper_state`, исправлений, due retests, доступных approved tasks и лимита времени. Вход в `buildPlan` должен формироваться **из базы**, а не из произвольного браузерного JSON.
2. Отдельно привязать **каждое письменное задание** к проверенному syllabus skill, paper и version; развернуть Section A source-material с approved source-version. Текущие таблицы written tasks не содержат полной canonical mapping, поэтому не объявлять их готовым mixed-plan catalog.
3. Подготовить approve workflow: академическое и языковое QA, MCQ answer-key/server checking, уникальные exam/reserve pools, предметные AO. Не копировать учебные вопросы Cambridge, их схемы или source diagrams.
4. Создать server-authorized, additive native plan snapshot с versioning и policy для resumed/replayed действий. Не перезаписывать записи Mathematics и legacy Practice/Tours.
5. Структуру написанного Core verbinden с каноническими private функциями `plan_next_v1/open_v1/criteria_v1/advance_v1/status_v1` через авторизованный транспорт; **никаких service role secrets в браузере**.
6. Провести positive/negative JWT E2E, cross-user isolation, lost-network/replay, phone/desktop RU/UZ/EN, offline, review source, regression old subjects.
7. Только потом интегрировать через прежний Mathematics Exam Prep Host и явно согласовывать закрытую Economics beta.

**NO-GO остаётся.** `Vercel READY` и автономные тесты не означают работающую подготовку к экзамену.

## 8. Инварианты для всех следующих изменений

- Один визуальный Exam Prep, собственный предметный контент и академическая логика Paper.
- Один ученический Core без зависимости от AI Tutor и Mentor Care.
- Доказательство знаний задаёт только серверное evidence; письменное `Next` не равно correctness.
- Никакого повышения stage из календаря.
- Никакого переноса P1/P2 зачёта в P3/P4.
- Никакого изменения legacy attempts/answers/ratings/certificates/pools, локальных данных или сброса прогресса.
- Версионирование и rollback для каждого будущего включения.
