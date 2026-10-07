(() => {
  "use strict";

  const CACHE_MS = 12000;
  const cache = new Map();

  const COPY = {
    ru: {
      selectRequired: "Сначала выбери предметы тарифа: Профиль → Тариф → Предметы тарифа.",
      notInPlan: "Этот предмет не входит в выбранные предметы тарифа. Измени выбор в Профиль → Тариф → Предметы тарифа.",
      compNotInPlan: "Для Tours выбери этот предмет в Competitive: Профиль → Тариф → Предметы тарифа.",
      manageInPlan: "Для этого beta-аккаунта предметы настраиваются через Профиль → Тариф → Предметы тарифа.",
      unavailable: "Этот предмет сейчас недоступен.",
      generic: "Не удалось проверить доступ к предмету. Попробуй ещё раз."
    },
    uz: {
      selectRequired: "Avval tarif fanlarini tanlang: Profil → Tarif → Tarif fanlari.",
      notInPlan: "Bu fan tarifdagi tanlangan fanlarga kirmaydi. Profil → Tarif → Tarif fanlari bo‘limida tanlovni o‘zgartiring.",
      compNotInPlan: "Tours uchun bu fanni Competitive sifatida tanlang: Profil → Tarif → Tarif fanlari.",
      manageInPlan: "Bu beta-akkauntda fanlar Profil → Tarif → Tarif fanlari orqali sozlanadi.",
      unavailable: "Bu fan hozir mavjud emas.",
      generic: "Fan kirishini tekshirib bo‘lmadi. Qayta urinib ko‘ring."
    },
    en: {
      selectRequired: "Choose your plan subjects first: Profile → Plan → Plan subjects.",
      notInPlan: "This subject is not included in your selected plan subjects. Change it in Profile → Plan → Plan subjects.",
      compNotInPlan: "To use Tours, select this subject for Competitive in Profile → Plan → Plan subjects.",
      manageInPlan: "For this beta account, subjects are managed in Profile → Plan → Plan subjects.",
      unavailable: "This subject is unavailable right now.",
      generic: "Could not verify subject access. Try again."
    }
  };

  function locale() {
    const lang = String(window.i18n?.getLang?.() || "ru").toLowerCase();
    return lang === "uz" || lang === "en" ? lang : "ru";
  }

  function copy() {
    return COPY[locale()] || COPY.ru;
  }

  function key(subjectKey, intent) {
    return String(subjectKey || "").trim().toLowerCase() + "::" + String(intent || "study");
  }

  function showToast(text, duration = 2800) {
    const toast = document.getElementById("toast");
    if (!toast || !text) return;
    toast.textContent = text;
    toast.classList.add("is-show");
    setTimeout(() => toast.classList.remove("is-show"), duration);
  }

  function messageFor(result) {
    const c = copy();
    const reason = String(result?.reason || "");
    if (reason === "subject_selection_required") return c.selectRequired;
    if (reason === "subject_not_in_plan") return c.notInPlan;
    if (reason === "competitive_not_in_plan") return c.compNotInPlan;
    if (reason === "manage_in_plan_subjects") return c.manageInPlan;
    if (reason === "subject_unavailable" || reason === "competitive_requires_main_subject") return c.unavailable;
    return c.generic;
  }

  async function check(subjectKey, intent = "study", { fresh = false } = {}) {
    const normalizedSubject = String(subjectKey || "").trim().toLowerCase();
    const normalizedIntent = String(intent || "study").trim().toLowerCase();
    const cacheKey = key(normalizedSubject, normalizedIntent);

    if (!normalizedSubject) {
      return { allowed:false, enforced:false, reason:"invalid_subject" };
    }

    if (!fresh) {
      const cached = cache.get(cacheKey);
      if (cached && (Date.now() - cached.at) < CACHE_MS) return cached.value;
    }

    if (!window.sb?.rpc) {
      return { allowed:true, enforced:false, reason:"guard_unavailable" };
    }

    try {
      const { data, error } = await window.sb.rpc("get_iclub_my_subject_access_v1", {
        p_subject_key: normalizedSubject,
        p_intent: normalizedIntent
      });

      if (error || !data || typeof data !== "object") {
        return { allowed:true, enforced:false, reason:"guard_unavailable" };
      }

      const value = {
        allowed: data.allowed === true,
        enforced: data.enforced === true,
        reason: String(data.reason || ""),
        planCode: String(data.plan_code || "")
      };

      cache.set(cacheKey,{ at:Date.now(), value });
      return value;
    } catch {
      return { allowed:true, enforced:false, reason:"guard_unavailable" };
    }
  }

  async function guard(subjectKey, intent, { silent = false, fresh = false } = {}) {
    const result = await check(subjectKey,intent,{ fresh });
    if (result.allowed !== false) return true;

    if (!silent) showToast(messageFor(result));
    return false;
  }

  function invalidate(subjectKey = "") {
    const prefix = String(subjectKey || "").trim().toLowerCase();
    if (!prefix) {
      cache.clear();
      return;
    }

    for (const k of cache.keys()) {
      if (k.startsWith(prefix + "::")) cache.delete(k);
    }
  }

  window.addEventListener("iclub:subject-selection-changed", (event) => {
    invalidate(event?.detail?.subjectKey || "");
  });

  window.addEventListener("focus", () => invalidate());

  window.iClubCommercialAccessUI = Object.freeze({
    version: "canary_subject_access_enforcement_v1",
    checkStudy: (subjectKey, options) => check(subjectKey,"study",options),
    checkCompetitive: (subjectKey, options) => check(subjectKey,"competitive",options),
    guardStudy: (subjectKey, options) => guard(subjectKey,"study",options),
    guardCompetitive: (subjectKey, options) => guard(subjectKey,"competitive",options),
    guardLegacyToggle: (subjectKey, options) => guard(subjectKey,"legacy_toggle",options),
    invalidate
  });

  window.dispatchEvent(new CustomEvent("iclub:commercial-access-ready"));
})();