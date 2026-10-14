# iClub AI v2.1 — единый серверный контракт допуска для всего приложения

## Место в Master Plan
P2 readiness + P5 Practice/Tours + P6 Home/Profile/subjects/Lessons + P4 legacy Tutor isolation. Вместо новой серии предметных AI модулей создан **один** QA-only серверный диспетчер `qa/ai-layer-v21-app-wide-admission.cjs`. Он переиспользует уже проверенный `ContentHandoffGate` (текущая публикация, source/version/hash, права, cohort, protected state и повторная проверка после await).

Он покрывает следующие сценарии с раздельными доказательствами от сервера (НЕ из DOM/localStorage):
- Общая помощь iClub по разрешённым разделам приложения → подписанный/подтверждённый navigation source;
- Subject overview для Mathematics, Biology, Chemistry, Economics, Informatics; то же правило для English A1/A2/B1, SAT/IELTS, но **все эти будущие предметы фактически остаются закрытыми** до server subject activation/source/rights/content/locale rollout;
- Home — только серверно подтверждённые next-actions (никаких выдуманных достижений);
- Profile — только подтверждённый агрегат прогресса;
- Lessons — только утверждённый источник для ТОЧНОГО урока, не текущий предметный Telegram видеоэкран;
- Practice — ТОЛЬКО завершённая V4-сессия и серверно подтверждённый ответ конкретного вопроса. Старый `attempt_id` запрещено выдавать за session ID;
- Tours — только заархивированная и действительно открытая попытка;
- Mathematics Exam Prep — существующий Tutor не переключается, новый маршрут отказывает до parity.

## Единый механизм
Диспетчер использует только JWT-bound trusted services: `getScopedContext`, `getVerifiedScreenEvidence`, `isProtected`, `getServerTimeMs`. Контекст и свидетельство экрана сверяются по user ID, context revision, source-provenance hash, scope, subject, feature, topic и точному ресурсу. После общих content/readiness/cross-subject gates вновь проверяет владение и неизменность актуального экрана и evidence. Каждый исход — `canAsk` или `in_development`/`unavailable`/`hidden` — с `charge=0`, без model/provider. Это **только допуск**, не выпуск ответа, не основание для списания: реальные Edge/RPC, атомарный учёт, source publication и beta gates всё равно обязательны.

## Принципиальные NO-GO
Этот QA-сервис пока не импортирован в production Edge или реальный app.js; штатный интерфейс не включён, основной Quiz защищён. В системе нет подтверждённых live server proofs для Home/Profile/Lessons/новых предметов на основе этой сборки. Имеющийся синтетический Preview проверяет внешность/логику, а не backend. Ветка main и production Supabase не меняются, новые миграции/аккаунты не создаются. Не считать синтетически одобренные 10 предметов реальной готовностью.

## Следующая измеримая веха
Подключить **один** доверенный серверный adapter к текущим read-only RPC/readiness/source release контрактам в изолированной среде с эквивалентностью существующему Edge. Без отдельной инфраструктуры для каждого предмета и без включения до полученной редакционной публикации/архивных разрешений.
