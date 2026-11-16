/* Accept EXACTLY the two event-order fixes to the archived approved B00 adapter. */
"use strict";
const assert=require("node:assert/strict");
const fs=require("node:fs");
const baseline=fs.readFileSync(process.argv[2],"utf8");
const actual=fs.readFileSync("registration-b00-ui.js","utf8");
const patches=[
  ["  document.getElementById(\"reg-subject-chips\")?.addEventListener(\"click\", () => queueMicrotask(updateSubjectCounter));","  // Read after app.js has synchronously applied the chip choice to hidden\n  // selects; microtasks may otherwise run between event listeners (off-by-one).\n  document.getElementById(\"reg-subject-chips\")?.addEventListener(\"click\", () => {\n    requestAnimationFrame(updateSubjectCounter);\n  });"],
  ["    queueMicrotask(() => {\n      document.dispatchEvent(new CustomEvent(\"reg-subjects-i18n-updated\"));\n      updateSubjectCounter();\n    });","    requestAnimationFrame(() => {\n      document.dispatchEvent(new CustomEvent(\"reg-subjects-i18n-updated\"));\n      updateSubjectCounter();\n    });"]
];
let expected=baseline;
for(const [from,to] of patches){
  assert.equal(expected.split(from).length-1,1,"B00 baseline differs from approved adapter");
  expected=expected.replace(from,to);
}
assert.equal(actual,expected,"B00 adapter changed beyond two authorized counter sync fixes");
console.log("PASS approved B00 adapter untouched except exact counter event-order fixes");
