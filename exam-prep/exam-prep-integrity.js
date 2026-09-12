(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = "p243integrity1";
  const PROTECTED_TYPES = new Set(["diagnostic", "retest", "mixed", "timed", "paper"]);
  const PROTECTED_ROLES = new Set(["diagnostic", "retest", "mixed", "timed", "unseen"]);
  const DEDUPE_MS = 800;

  let active = null;
  let observer = null;
  let lastSignalAt = 0;
  let suppressUntil = 0;
  let chain = Promise.resolve();

  function normalizeLanguage(value) {
    const language = String(value || "ru").toLowerCase();
    return ["ru", "uz", "en"].includes(language) ? language : "ru";
  }

  function text(language, status, strict) {
    const copy = {
      ru: {
        clean: "Во время этой проверки оставайтесь в iClub. Переход в другую вкладку или приложение будет зафиксирован.",
        warning: "Вы вышли из окна проверки. Это зафиксировано. Продолжайте работу в iClub.",
        review: "Зафиксировано несколько выходов из окна проверки. Попытка продолжится с отметкой для проверки.",
        strictReview: "Зафиксировано несколько выходов из окна проверки. Попытка сохранится, но не будет учитываться как сопоставимый экзаменационный результат."
      },
      uz: {
        clean: "Ushbu tekshiruv vaqtida iClub oynasida qoling. Boshqa sahifa yoki ilovaga o‘tish qayd etiladi.",
        warning: "Siz tekshiruv oynasidan chiqdingiz. Bu qayd etildi. Ishni iClub ichida davom ettiring.",
        review: "Tekshiruv oynasidan bir necha marta chiqish qayd etildi. Urinish davom etadi va tekshiruv uchun belgilab qo‘yiladi.",
        strictReview: "Tekshiruv oynasidan bir necha marta chiqish qayd etildi. Urinish saqlanadi, ammo taqqoslanadigan imtihon natijasi sifatida hisobga olinmaydi."
      },
      en: {
        clean: "Stay in iClub during this check. Switching to another tab or app will be recorded.",
        warning: "You left the check window. This was recorded. Continue your work in iClub.",
        review: "Several exits from the check window were recorded. The attempt will continue with a review flag.",
        strictReview: "Several exits from the check window were recorded. The attempt will be saved but will not count as a comparable exam result."
      }
    };
    const c = copy[normalizeLanguage(language)];
    if (status === "review_required") return strict ? c.strictReview : c.review;
    if (status === "warning") return c.warning;
    return c.clean;
  }

  function rootEl() { return document.querySelector("#exam-prep-host-root"); }
  function hostOpen() {
    try { return window.iClubExamPrep?.isOpen?.() === true; } catch (_) { return false; }
  }
  function assessmentVisible() {
    const root = rootEl();
    return Boolean(
      active?.protected && active?.status === "active" && hostOpen() && root && !root.hidden &&
      root.querySelector("[data-ep-live-submit]")
    );
  }

  function removeBanner() {
    rootEl()?.querySelector("[data-ep-integrity-banner]")?.remove();
  }

  function renderBanner() {
    const root = rootEl();
    if (!root || !assessmentVisible()) { removeBanner(); return; }
    const shell = root.querySelector(".ep-host-shell");
    if (!shell) return;
    let banner = shell.querySelector("[data-ep-integrity-banner]");
    if (!banner) {
      banner = document.createElement("div");
      banner.className = "ep-live-notice";
      banner.dataset.epIntegrityBanner = "true";
      banner.setAttribute("role", "status");
      banner.setAttribute("aria-live", "polite");
      shell.insertBefore(banner, shell.firstChild);
    }
    const strict = ["timed", "paper"].includes(active.sessionType);
    const message = text(active.language, active.integrityStatus, strict);
    if (banner.textContent !== message) banner.textContent = message;
  }

  function ensureObserver() {
    const root = rootEl();
    if (!root || observer) return;
    observer = new MutationObserver(() => renderBanner());
    observer.observe(root, { childList: true, subtree: true });
  }

  function isProtectedSession(session) {
    if (!session || session.status !== "active") return false;
    if (PROTECTED_TYPES.has(String(session.session_type || ""))) return true;
    const items = Array.isArray(session.items) ? session.items : [];
    return items.some(item => PROTECTED_ROLES.has(String(item?.reserve_role || "")));
  }

  function setSession(detail) {
    const session = detail?.session;
    if (!session?.session_id) return;
    active = {
      sessionId: String(session.session_id),
      sessionType: String(session.session_type || ""),
      status: String(session.status || ""),
      language: normalizeLanguage(detail?.language),
      protected: isProtectedSession(session),
      integrityStatus: "clean",
      eventCount: 0
    };
    ensureObserver();
    removeBanner();
    if (!active.protected || active.status !== "active") return;
    renderBanner();
    Promise.resolve(internal.api?.integrityStatus?.(active.sessionId)).then(result => {
      if (!result?.ok || !result.data || active?.sessionId !== String(session.session_id)) return;
      active.integrityStatus = String(result.data.status || "clean");
      active.eventCount = Number(result.data.event_count || 0);
      renderBanner();
    }).catch(() => {});
  }

  function clearSession(sessionId) {
    if (!active) return;
    if (sessionId && active.sessionId !== String(sessionId)) return;
    active = null;
    removeBanner();
  }

  function eventKey(type, sessionId) {
    return `ep-integrity-${type}-${sessionId}-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
  }

  async function sendSignal(type, snapshot, clientEventId) {
    const api = internal.api;
    if (!api?.recordIntegrityEvent) return null;
    let result = await api.recordIntegrityEvent(snapshot.sessionId, type, clientEventId);
    if (!result?.ok) {
      await new Promise(resolve => setTimeout(resolve, 400));
      if (active?.sessionId !== snapshot.sessionId) return result;
      result = await api.recordIntegrityEvent(snapshot.sessionId, type, clientEventId);
    }
    return result;
  }

  function record(type) {
    const now = Date.now();
    if (now < suppressUntil || !assessmentVisible()) return;
    if (now - lastSignalAt < DEDUPE_MS) return;
    lastSignalAt = now;
    const snapshot = { ...active };
    const clientEventId = eventKey(type, snapshot.sessionId);
    chain = chain.then(async () => {
      const result = await sendSignal(type, snapshot, clientEventId);
      if (!result?.ok || !result.data || active?.sessionId !== snapshot.sessionId) return;
      active.integrityStatus = String(result.data.status || active.integrityStatus || "clean");
      active.eventCount = Number(result.data.event_count || active.eventCount || 0);
      renderBanner();
    }).catch(() => {});
  }

  window.addEventListener("iclub:exam-prep-session", event => setSession(event.detail || {}));
  window.addEventListener("iclub:exam-prep-session-ended", event => clearSession(event.detail?.sessionId));

  document.addEventListener("visibilitychange", () => {
    if (document.visibilityState === "hidden") record("visibility_hidden");
  });

  window.addEventListener("blur", () => {
    setTimeout(() => {
      if (document.visibilityState !== "hidden") record("window_blur");
    }, 250);
  });

  document.addEventListener("click", event => {
    if (event.target?.closest?.("[data-ep-live-end]")) suppressUntil = Date.now() + 2000;
  }, true);

  ensureObserver();
  internal.integrityClientVersion = VERSION;
})();
