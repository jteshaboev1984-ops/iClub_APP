(() => {
  "use strict";
  const root = document.getElementById("epv3-root");
  if (!root) return;

  const areaFromSkill = (skill) => {
    const parts = String(skill || "").split("-");
    if (parts.length < 3) return "";
    const explicit = parts[1];
    if (["QUA","FUN","COO","CIR","TRI","SER","DIF","INT","DAT","CNT","PRO","DRV","NOR"].includes(explicit)) return explicit;
    if (parts[0] === "P5" && parts[1] === "GEO") return "DRV";
    return "";
  };

  root.addEventListener("click", (event) => {
    const target = event.target.closest("[data-skill]");
    if (!target) return;
    if (!target.dataset.area) {
      const area = areaFromSkill(target.dataset.skill);
      if (area) target.dataset.area = area;
    }
  }, true);

  const params = new URLSearchParams(window.location.search);
  const requestedScreen = params.get("screen");
  const requestedComponent = params.get("component");
  const requestedSkill = params.get("skill");
  const requestedArea = params.get("area") || areaFromSkill(requestedSkill);

  if (requestedScreen) {
    requestAnimationFrame(() => {
      const candidates = [...root.querySelectorAll(`[data-screen="${CSS.escape(requestedScreen)}"]`)];
      const target = candidates.find(el => !requestedComponent || el.dataset.component === requestedComponent) || candidates[0];
      if (!target) return;
      if (requestedComponent) target.dataset.component = requestedComponent;
      if (requestedSkill) target.dataset.skill = requestedSkill;
      if (requestedArea) target.dataset.area = requestedArea;
      target.click();
    });
  }
})();