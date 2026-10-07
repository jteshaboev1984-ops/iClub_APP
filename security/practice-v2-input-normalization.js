(() => {
  "use strict";

  const UNICODE_MINUS = /[−–—]/g;
  const NUMERIC = /^\s*[+-]?(?:\d+(?:[.,]\d+)?|[.,]\d+)(?:[eE][+-]?\d+)?\s*$/;

  document.addEventListener("input", (event) => {
    const input = event.target;
    if (!(input instanceof HTMLInputElement) || input.id !== "practice-input") return;

    const raw = String(input.value || "");
    if (!/[−–—]/.test(raw)) return;

    const normalized = raw.replace(UNICODE_MINUS, "-");
    if (!NUMERIC.test(normalized)) return;

    const start = input.selectionStart;
    const end = input.selectionEnd;
    input.value = normalized;

    if (start !== null && end !== null) {
      try { input.setSelectionRange(start, end); } catch {}
    }
  }, true);
})();
