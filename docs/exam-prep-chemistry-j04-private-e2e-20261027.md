# iClub Chemistry 9701 — J-04: authenticated P1 end-to-end verification, 27.10.2026

## J-05 — устойчивость интерфейса P1 и повторяемые проверки (27.10.2026)

**Доработано в существующей ветке, без GO, PR, merge или деплоя.**

- В одном рабочем окне появились компактная раскрываемая карта **40 вопросов**, понятные состояния «выбран / отвечен», активный номер и переход к любому вопросу без прокрутки 40 экранов. Сохранённый ответ остаётся на сервере; возвращение к первому пропущенному вопросу действует и при достижении последнего номера.
- Экран завершения предупреждает о количестве неотвеченных вопросов. После finish правильные ответы и объяснения доступны, до finish — нет. Карта имеет aria-label, aria-current, keyboard focus-visible, 8 колонок на широком экране и 5 колонок на узком (максимум 520px), использует прежнюю тему Exam Prep.
- Исправлена возможная гонка **переключение RU/UZ/EN пока ответ ещё записывается**: новая загрузка ждёт завершения сохранения. При переключении языка во время GET результат первоначального GET отклоняется в пользу нового языка. Никаких локальных замен подлинным серверным данным.
- При потере подтверждения ответа после успешной записи повторное чтение восстанавливает серверный выбор; перезапуск UI восстанавливает незавершённую попытку через историю. При отказе сервера `attempt_closed_or_expired` UI безопасно вызывает серверное finish и показывает результат, без зависшего сообщения об ошибке.
- **Новый повторяемый Node тест:** `node scripts/qa-chemistry-9701-j05-ui-navigation-offline.cjs` — 4/4 пройденных сценария, на фальшивых учебных строках, без подключения к Supabase и без материалов настоящего экзамена. Код и стили прошли синтаксическую и структурную проверку.
- После J-05 повторно исполнен production **READ-ONLY** `scripts/qa-chemistry-9701-j04-final-readonly.sql`: **32/32 PASS**. Chemistry реальные попытки = 0, отдельные согласия = 0, разрешённые к выпуску вопросы = 0, beta enabled = false; Mathematics и Practice счётчики неизменны.
- Последний `main` содержит отдельные обновления Economics и release guard. Chemistry ветка сохранила актуальный `exam-prep-economics-native.js`, `index.html` с Economics v11 и свои изолированные стили/скрипты. Новых веток не создавали и старые не удаляли из-за ещё не интегрированных уникальных источников.

**Граница достоверности:** успешно проверено серверное J-04 E2E внутри ROLLBACK и J-05 JavaScript на имитации DOM. **Реальный браузерный вход тестировщика, screenshots мобильного и desktop и production rollout НЕ выполнены.** Для полноценного продуктового GO также остаётся построить и проверить путь диагностика → обучение → исправление ошибок → повторная оценка и раздельные P2/P3/P4/P5.

---



**Status: full server journey tested under transaction-local authorization; no real beta launch.**

**Same working branch:** `work/chemistry-9701-j02-auth-host-20261026`. No new branch, no PR, no merge or Vercel production deployment. No external examiner; Chemistry P1 content remains internally AI-reviewed and owner release blocked.

## What was tested with existing Mathematics Beta members

- Source population: **4 Mathematics controlled-beta cohort members, 3 active; 2 active with Chemistry selected**. No new user, duplicate membership, test password or real-user enrollment was created.
- For SQL testing, selected **existing consenting Mathematics beta account IDs** in the private database and set a **transaction-local, simulated authenticated JWT identity**. This is a **SQL-authentication simulation**, not login into the real user's web browser or authenticated session.
- Every positive test was wrapped in `BEGIN ... ROLLBACK`, with fail-closed assertions before and after. Only **inside each uncommitted transaction**, an owner release manifest for the existing 40 internally AI-reviewed originals, temporary Chemistry-specific opt-in, published program/P1 metadata and beta flag were made visible to that transaction. The changes were never committed or visible as published Chemistry to production users.
- Case 1: `start` returns a 40-question, 75-minute session. Repeated start with the same client key resumes same attempt. GET on RU/UZ/EN returns correctly localized options and never leaks `answer_key`, correct index or explanation before finalization. Answer save and retry is idempotent; re-answer persists when changing locale.
- Case 2: **full live user API** processed 40 MCQs, 39 answered (one deliberately wrong, one missing), yielding exactly **38/40**, with server-side shuffle mapping checked against private authoritative keys in the test harness. `finish` replay is idempotent, answer edits after finish rejected; own history displays one attempt, 39 responses and the same 38/40; post-finish explanation and correct indices are available.
- Case 3: second **eligible** Mathematics beta account with its **own temporary Chemistry opt-in** still cannot read, answer, finish or retrieve the first account's attempts. Isolated 0-history for second user.
- Case 4: adjust *only the uncommitted QA session's* deadline to the past; late answers rejected, finish works, old attempt persists. Revoke Chemistry opt-in: further GET/history blocked, yet the attempt row **remains** (not deleted). Existing Mathematics beta consent/membership unaffected.
- Every transaction **ROLLED BACK**. The final read-only pass confirms **zero Chemistry real or synthetic sessions**, zero Chemistry opt-ins, zero approved release items, Chemistry program draft/OFF, library hidden.

## Browser module verification

- Executed `exam-prep-chemistry-native.js` inside isolated JavaScript mock DOM: menu → begin → answer → automatic next question → RU→UZ language switch → another answer → finish → localized result and answer explanations. UI makes the expected Chemistry RPC calls; no service-role credentials, answer keys or persistent browser-side progress stores included. This is a structural **mock**, not real desktop/mobile visual acceptance.
- J-03 Chemistry invitation and self-consent UI already tested using a mock DOM, including eligible/ineligible paths and reversible opt-in; student testing not triggered.
- Common `exam-prep-host.js` and `exam-prep-chemistry-native.js` compile; CSS uses existing responsive Economics and host components.
- **Latest main drift identified**: upstream changed `exam-prep-economics-native.js` and `index.html` while Chemistry feature branch existed. These two files have been synchronized from the current `main` into the **same Chemistry working branch**, preserving the new Chemistry script loader and updating cache-bust tokens for the modified host JS/CSS. This reduces risk of overwriting recent Economics features. The branch is still not merged into `main`.

## Invariants / reproducible checks

Run `scripts/qa-chemistry-9701-j04-final-readonly.sql` against live Supabase: **32/32 PASS** after all positive tests were rolled back. Expected Maths baseline 544 sessions / 1,979 responses; Practice 502 attempts / 4,816 answers; at least one Economics native attempt; all 26 earlier Chemistry private variants preserved. No `public.questions`, mathematical scores/mastery, or localStorage were changed.

The positive test used transaction-local simulated JWT for actual existing Math beta account IDs; the detailed SQL was executed and rolled back, and is intentionally **not** committed as a dangerous re-runnable script with status-`published` updates against a shared production database. The final READ-ONLY file is committed and safe to rerun.

## Remaining, not done

1. **Real device/browser session acceptance** still required with a consenting existing beta user: desktop/mobile, keyboard/focus, network disruptions and performance. SQL JWT simulation is not a real browser login.
2. No actual learner can see the new Chemistry code until owner-controlled release/merge/deployment. Do not activate program/manifest/beta on production without separate release GO. Current branch remains private to development.
3. The 40 fixed MCQ set is insufficient for reliable repeat exams without question rotation; reserve expansion and student learning path (diagnosis → plan → lessons → errors → recheck) remain product blockers. P2/P3/P4/P5 assessment and honest handling of real lab/written skills remain out of scope of Paper 1.
4. Historical Mathematics and Economics consent, grades, progress, localStorage and sessions must stay unaffected. Never add release flags or use admin/service secrets in the browser.
5. The older Chemistry work branch retains unpublished, unique academic and SQL materials. Do **not** delete that branch until its sources are safely consolidated. No new branch was created in J-04.

**Current status:** J-04 authenticated *server* path passed under ROLLBACK; end-user rollout remains OFF; separate controlled beta GO required.
