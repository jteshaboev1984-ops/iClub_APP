(() => {
  "use strict";
  const root = document.getElementById("v3-app");
  if (!root) return;

  root.addEventListener("click", (event) => {
    const action = event.target.closest(".v3-action-card [data-screen='math-hub']");
    if (!action) return;
    const isHome = root.querySelector(".v3-greeting") && !root.querySelector(".v3-topbar__back");
    if (!isHome) return;
    event.preventDefault();
    event.stopImmediatePropagation();
    window.location.href = "ui-v3-exam-prep.html?screen=question-retest&component=P1&skill=P1-DIF-02&area=DIF";
  }, true);
})();