# iClub Exam Prep — Written Learning, Stage 1 inventory

**Дата:** 22.10.2026 · **Статус:** технический аудит/закрытые заготовки завершены; Economics learner runtime НЕ реализован. **Режим:** чтение GitHub/Supabase/Vercel, только добавление новых неиспользуемых файлов в GitHub.

## Проверенные факты

1. В `exam-prep/exam-prep-live.js` для письменного задания Mathematics отображается `textarea[name="ep_live_written_answer"]`; функция `submitAnswer` требует непустой текст и посылает `{artifact:{text:...}}` через `submitResponse`. Это НЕ маршрут «написал на бумаге → критерии → далее». Запрещено отправлять фиктивное содержимое или менять существующую Mathematics-логику.
2. `exam-prep/exam-prep-api.js` содержит Mathematics RPC для self-mark в timed practice — не путать его с письменным Core Economics. Нынешнюю поддержку Mathematics сохраняем.
3. `exam-prep/exam-prep-host.js` намеренно показывает coming soon для не-Mathematics. Защита остаётся включённой.
4. Supabase Economics содержит справочники навыков/Paper и кандидатные связи MCQ, но сейчас не имеет подтверждённого общего сервиса `written_external → advanced_in_plan_only`, поэтому новых «Next» learner API не заявляем.
5. Существуют отдельные Mathematics-entitlement, assignment, mentor queue/review, но они не делают Economics essay uploads готовой функциональностью. Без активного назначения нельзя создавать очередь.

## Базовые показатели и защита

- Economics `economics_9708/economics_2026_2028_v1`: `draft`, `launch_enabled=false`, 16 кандидатных MCQ-связей, 0 approved.
- Прочитанные контрольные счётчики: Mathematics sessions **543**, responses **1976**; Practice attempts **502**, answers **4816**; user-subject records **2098**.
- В текущем этапе Supabase SQL — только SELECT. Счётчики — не полные по-строчные контрольные суммы.
- GitHub compare `73cdecc…84396839`: добавлены **ровно четыре** отдельных файла — документ, contract JSON, QA-скрипт, академический черновик P4 B1; ни один существовавший JS/CSS/SQL-файл не изменён.
- Vercel: последний увиденный production deployment SHA `84396839f5bd66240e07665ff64891b97e6ec925`, статус READY. Это проверка сборки, не browser E2E.
- Официальный Economics 9708 syllabus: https://www.cambridgeinternational.org/Images/697423-2026-2028-syllabus.pdf (ver.2, pp.35–36).

## Выполнено

- `docs/exam-prep-written-learning-contract-v1.md` — утверждённая архитектура.
- `exam-prep/contracts/written-learning-contract-v1.json` — отключённый машиночитаемый контракт.
- `scripts/qa-written-learning-contract-v1.cjs` — автономная проверка инвариантов, не загружается приложением. Локальная версия проверок: 30 PASS; сохранённый в GitHub JSON дополнительно перечитан и проверен по 8 ключевым условиям. **Это не production E2E QA.**
- `exam-prep/academic/economics-9708-written-requirements-P4B1-DRAFT.json` — одно собственное письменное задание P4 (олигополия и эффективность) с черновыми RU/UZ/EN требованиями. **INTERNAL DRAFT**, academic/language/rights/specific-skill mapping pending; runtime OFF.

## Следующий этап (пока не реализован)

1. Проверить контракты существующего продвижения плана; использовать их только если они действительно поддерживают external written item без письменного payload. Иначе — отдельная idempotent/authorization-bound операция `Next` с событием `advanced_in_plan_only`.
2. Отдельная read-only выдача критериев строго по `task/version` и правилам видимости timed/ordinary. Требования должны пройти академическую и языковую проверку.
3. Запретить score/mastery/AI/mentor side effects от «Next»; оставить Economics launch OFF.
4. Server + browser QA: double-click, offline, resume, смена предмета, mobile/desktop, RU/UZ/EN, AI OFF и mentor OFF. Контроль неизменности Mathematics и legacy данных.

**Решение о запуске:** Economics Exam Prep = NO-GO. Никаких student feature flags, миграций или SQL-записей.
