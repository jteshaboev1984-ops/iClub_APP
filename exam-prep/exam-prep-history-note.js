(() => {
  "use strict";

  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const VERSION = "p105history1";
  let observer = null;
  let renderQueued = false;
  const loading = new Set();

  function rootEl() {
    return document.querySelector("#exam-prep-host-root");
  }

  function language() {
    try {
      const value = String(window.i18n?.getLang?.() || document.documentElement.lang || "ru").toLowerCase();
      return ["ru", "uz", "en"].includes(value) ? value : "ru";
    } catch (_) {
      return "ru";
    }
  }

  function copy() {
    if (language() === "uz") return {
      title: "Oldingi mashqlar",
      body: count => `Oldingi Practice va Tour javoblaridan ${count} tasi topildi. Ular faqat qo‘shimcha yo‘nalish uchun ishlatiladi va tasdiqlangan progress yoki imtihonga tayyorlikni o‘zgartirmaydi.`
    };
    if (language() === "en") return {
      title: "Previous practice",
      body: count => `${count} earlier Practice/Tour answer${count === 1 ? "" : "s"} found. This is used only as supporting context and does not change confirmed progress or exam readiness.`
    };
    return {
      title: "Предыдущая практика",
      body: count => `Найдено ответов из прошлых Practice и Tour: ${count}. Они используются только как дополнительный ориентир и не меняют подтверждённый прогресс или готовность к экзамену.`
    };
  }

  function canUse() {
    const caps = internal.lastCapabilities;
    return Boolean(
      caps &&
      caps.coreAccess === true &&
      caps.killSwitch === false &&
      caps.rolloutState === "controlled_beta"
    );
  }

  function removeNote(component) {
    rootEl()?.querySelector(`[data-ep-history-note="${component}"]`)?.remove();
  }

  async function hydrate(strip, component) {
    if (!strip?.isConnected || loading.has(component) || typeof internal.api?.legacyReferenceSummary !== "function") return;
    if (strip.parentElement?.querySelector(`[data-ep-history-note="${component}"]`)) return;

    loading.add(component);
    try {
      const result = await internal.api.legacyReferenceSummary(component);
      if (!strip.isConnected) return;
      const data = result?.ok ? (result.data || {}) : null;
      const count = Number(data?.reference_count || 0);
      if (!data || data.available !== true || count <= 0 || data.academic_credit === true || String(data.mastery_effect || "none") !== "none") {
        removeNote(component);
        return;
      }

      const c = copy();
      const note = document.createElement("div");
      note.className = "ep-history-note";
      note.dataset.epHistoryNote = component;
      const title = document.createElement("strong");
      title.textContent = c.title;
      const body = document.createElement("span");
      body.textContent = c.body(count);
      note.append(title, body);
      strip.insertAdjacentElement("afterend", note);
    } catch (_) {
      removeNote(component);
    } finally {
      loading.delete(component);
    }
  }

  function render() {
    renderQueued = false;
    const root = rootEl();
    if (!root || root.hidden || !canUse()) {
      root?.querySelectorAll("[data-ep-history-note]").forEach(node => node.remove());
      return;
    }

    root.querySelectorAll("[data-ep-overview-strip]").forEach(strip => {
      const component = String(strip.getAttribute("data-ep-overview-strip") || "").toUpperCase();
      if (component === "P1" || component === "P5") hydrate(strip, component);
    });

    root.querySelectorAll("[data-ep-history-note]").forEach(note => {
      const component = String(note.getAttribute("data-ep-history-note") || "").toUpperCase();
      if (!root.querySelector(`[data-ep-overview-strip="${component}"]`)) note.remove();
    });
  }

  function queueRender() {
    if (renderQueued) return;
    renderQueued = true;
    queueMicrotask(render);
  }

  function attach() {
    const root = rootEl();
    if (!root) {
      setTimeout(attach, 50);
      return;
    }
    if (observer) observer.disconnect();
    observer = new MutationObserver(queueRender);
    observer.observe(root, { childList: true, subtree: true, attributes: true, attributeFilter: ["hidden", "aria-hidden"] });
    queueRender();
    internal.historyNoteVersion = VERSION;
  }

  attach();
})();
