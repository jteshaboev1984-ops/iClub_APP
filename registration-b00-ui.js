/* B00 registration two-step presentation adapter.
   Keeps the ORIGINAL #reg-form, input nodes, submit listener and data contract.
   If enhancement fails, the original single-page registration remains available. */
(() => {
  "use strict";

  const view = document.getElementById("view-registration");
  const form = document.getElementById("reg-form");
  const content = view?.querySelector(".content.reg");
  if (!view || !form || !content || form.dataset.b00Enhanced === "1") return;

  const stepOneIds = ["reg-language", "reg-fullname", "reg-region", "reg-district"];
  const stepOneFields = stepOneIds.map((id) => {
    const input = document.getElementById(id);
    const field = input?.closest("label.field");
    return field?.parentElement === form ? field : null;
  });
  const originalChildren = Array.from(form.children);
  const submit = document.getElementById("reg-submit");
  const language = document.getElementById("reg-language");

  // Do not enhance a changed/partial registration DOM.
  if (
    stepOneFields.some((field) => !field) ||
    stepOneFields.some((field, index) => originalChildren[index] !== field) ||
    !submit || submit.form !== form || !language
  ) return;

  const copy = {
    ru: { count: (n) => `Шаг ${n} из 2`, one: "Личные данные", two: "Школа и предметы", nonSchool: "Режим обучения", next: "Далее", previous: "Назад" },
    uz: { count: (n) => `${n}-bosqich / 2`, one: "Shaxsiy ma’lumotlar", two: "Maktab va fanlar", nonSchool: "Ta’lim tartibi", next: "Davom etish", previous: "Orqaga" },
    en: { count: (n) => `Step ${n} of 2`, one: "Personal details", two: "School and subjects", nonSchool: "Learning mode", next: "Next", previous: "Previous" }
  };
  const getCopy = () => copy[language.value] || copy.ru;

  const create = (tag, className) => {
    const node = document.createElement(tag);
    node.className = className;
    return node;
  };

  const progress = create("div", "reg-b00-progress");
  progress.setAttribute("role", "status");
  progress.setAttribute("aria-live", "polite");
  const header = create("div", "reg-b00-progress-head");
  const counter = create("span", "reg-b00-counter");
  const title = create("span", "reg-b00-progress-title");
  header.append(counter, title);
  const track = create("div", "reg-b00-progress-track");
  track.setAttribute("aria-hidden", "true");
  const trackOne = document.createElement("span");
  const trackTwo = document.createElement("span");
  track.append(trackOne, trackTwo);
  progress.append(header, track);

  const stepOne = create("div", "reg-b00-step reg-b00-step-one");
  stepOne.id = "reg-b00-step-one";
  const stepTwo = create("div", "reg-b00-step reg-b00-step-two");
  stepTwo.id = "reg-b00-step-two";
  const next = create("button", "btn primary reg-b00-action reg-b00-next");
  next.type = "button";
  const previous = create("button", "btn reg-b00-action reg-b00-prev");
  previous.type = "button";

  // Move the SAME DOM nodes: existing listeners, select options, IDs,
  // visibility code, native validity and submit behavior remain intact.
  stepOneFields.forEach((field) => stepOne.appendChild(field));
  originalChildren.slice(stepOneFields.length).forEach((child) => stepTwo.appendChild(child));
  stepOne.appendChild(next);
  stepTwo.appendChild(previous);
  form.append(stepOne, stepTwo);
  content.insertBefore(progress, content.querySelector("h1") || content.firstChild);

  let step = 1;
  const renderLabels = () => {
    const c = getCopy();
    const school = document.getElementById("reg-is-school-toggle");
    counter.textContent = c.count(step);
    title.textContent = step === 1 ? c.one : school?.checked ? c.two : c.nonSchool;
    next.textContent = c.next;
    previous.textContent = c.previous;
    stepOne.setAttribute("aria-label", c.one);
    stepTwo.setAttribute("aria-label", school?.checked ? c.two : c.nonSchool);
  };
  const setStep = (n, shouldScroll = true) => {
    if (n !== 1 && n !== 2) return;
    // Keep the learner on the actual save/alert screen while submit is in flight.
    if (submit.classList.contains("is-loading")) return;
    step = n;
    stepOne.hidden = step !== 1;
    stepTwo.hidden = step !== 2;
    view.dataset.regB00Step = String(step);
    trackOne.classList.add("is-done");
    trackTwo.classList.toggle("is-done", step === 2);
    renderLabels();
    if (shouldScroll && view.classList.contains("is-active")) {
      try { progress.scrollIntoView({ behavior: "instant", block: "start" }); } catch {}
    }
  };

  const stageOneValid = () => {
    for (const id of ["reg-fullname", "reg-region", "reg-district"]) {
      const element = document.getElementById(id);
      if (!element || element.disabled || !element.checkValidity()) {
        element?.reportValidity?.();
        return false;
      }
    }
    return true;
  };

  next.addEventListener("click", () => {
    if (stageOneValid()) setStep(2);
  });
  previous.addEventListener("click", () => setStep(1));

  // Pressing Enter in the first-step name input must not submit a hidden
  // Step-2 submit button; it navigates using original required-field checks.
  form.addEventListener("keydown", (event) => {
    if (step === 1 && event.key === "Enter" && event.target?.id === "reg-fullname" && !event.isComposing) {
      event.preventDefault();
      next.click();
    }
  });

  // The existing app.js submit handler runs unchanged, but never from Step 1.
  form.addEventListener("submit", (event) => {
    if (step === 1) {
      event.preventDefault();
      event.stopImmediatePropagation();
      next.click();
    }
  }, true);

  // Existing native required-field validation may be triggered by submit
  // on Step 2. Reveal a Step-1 field before the browser tries to focus it.
  form.addEventListener("invalid", (event) => {
    if (step === 2 && stepOne.contains(event.target)) setStep(1);
  }, true);

  language.addEventListener("change", renderLabels);
  document.getElementById("reg-is-school-toggle")?.addEventListener("change", renderLabels);

  // Returning to registration starts at Step 1; no fields or drafts are reset.
  let wasActive = view.classList.contains("is-active");
  const observer = new MutationObserver(() => {
    const active = view.classList.contains("is-active");
    if (active && !wasActive) setStep(1, false);
    wasActive = active;
  });
  observer.observe(view, { attributes: true, attributeFilter: ["class"] });

  form.dataset.b00Enhanced = "1";
  view.classList.add("reg-b00-enhanced");
  setStep(1, false);
})();
