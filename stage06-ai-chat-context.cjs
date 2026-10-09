'use strict';
// Stage06 QA-only: correct context, quick prompts and P1/P5 thread isolation.
const fs=require('node:fs');
const path=require('node:path');
const file=path.join(__dirname,'dist','global-ai-ui.js');
let code=fs.readFileSync(file,'utf8');
const edits=[["      threadKey: \"mathematics\",\n      subjectKey: \"mathematics\",\n      scopeCode: \"exam_prep\",","      threadKey: \"math-exam-prep-\" + componentCode,\n      subjectKey: \"mathematics\",\n      scopeCode: \"exam_prep\","],["  function resolveContext() {\n    const view = activeViewName();\n    if (view === \"courses\") {","  function activeCoursesScreen() {\n    const current = document.querySelector('.stack-screen.is-active[data-stack=\"courses\"]');\n    return String(current?.dataset?.screen || \"\").trim().toLowerCase();\n  }\n\n  function resolveContext() {\n    const view = activeViewName();\n    const screen = view === \"courses\" ? activeCoursesScreen() : \"\";\n    if (view === \"courses\" && screen && screen !== \"all-subjects\") {"],["    const view = activeViewName();\n    if ([\"profile\", \"ratings\", \"certificates\", \"archive\"].includes(view)) {","    const view = activeViewName();\n    const screen = view === \"courses\" ? activeCoursesScreen() : \"\";\n    if (screen.startsWith(\"practice-\")) {\n      return [\n        { key: \"app_help_practice\", label: c.appPractice },\n        { key: \"app_help_results\", label: c.appResults },\n        { key: \"app_help_here\", label: c.appHere }\n      ];\n    }\n    if (screen.startsWith(\"tour-\")) {\n      return [\n        { key: \"app_help_tours\", label: c.appTours },\n        { key: \"app_help_results\", label: c.appResults },\n        { key: \"app_help_here\", label: c.appHere }\n      ];\n    }\n    if ([\"profile\", \"ratings\", \"certificates\", \"archive\"].includes(view)) {"],["    const subjectTitle = document.getElementById(\"subject-hub-title\");\n    if (subjectTitle) {","    document.querySelectorAll('.stack-screen[data-stack=\"courses\"]').forEach((screen) => {\n      state.viewObserver.observe(screen, { attributes: true, attributeFilter: [\"class\"] });\n    });\n    const subjectTitle = document.getElementById(\"subject-hub-title\");\n    if (subjectTitle) {"]];
for(let i=0;i<edits.length;i++){
const [oldText,newText]=edits[i];
const p=code.indexOf(oldText);
if(p<0||code.indexOf(oldText,p+1)!==-1)throw Error('Stage06 context anchor '+i);
code=code.slice(0,p)+newText+code.slice(p+oldText.length);
}
new Function(code);
fs.writeFileSync(file,code,'utf8');
const index=path.join(__dirname,'dist','index.html');
let html=fs.readFileSync(index,'utf8');
const pin='global-ai-ui.js?v=globalaichat1';
if(html.split(pin).length!==2)throw Error('Stage06 pin mismatch');
html=html.replace(pin,'global-ai-ui.js?v=stage06ctx2');
fs.writeFileSync(index,html,'utf8');
console.log('STAGE06_AI_CONTEXT_READY p1_p5_separate=1 course_screens=1 prompts=1 observers=1');
