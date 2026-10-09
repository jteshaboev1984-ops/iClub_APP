'use strict';
/* Read-only Mathematics P1/P5 AI contract. Runs against verified Preview output. */
const fs=require('node:fs'),path=require('node:path');
const get=p=>fs.readFileSync(path.join(__dirname,p),'utf8');
const g=get('supabase/functions/global-ai/index.ts');
const e=get('supabase/functions/exam-prep-ai/index.ts');
const c=get('dist/global-ai-ui.js');
const u=get('dist/exam-prep/exam-prep-ai-ui.js');
const h=get('dist/index.html');
let checks=0;
function ok(test,description){checks++;if(!test)throw Error('Math AI contract: '+description);}
const gate=g.indexOf('guard = await rpc("get_iclub_global_ai_guard_service_v1"');
const route=g.indexOf('if (routeClass === "generated")',gate);
const start=g.indexOf('if (adapterCode !== "math_exam_prep_v1"',route);
const provider=g.indexOf('const provider = await callOpenAIProvider(',start);
ok(gate>=0&&gate<route&&route<start&&start<provider,'Global AI provider gated by learner+Math route');
const end=g.indexOf(') {',start);
const match=g.slice(start,end+1).match(/^if \(([\s\S]*)\)$/);
ok(!!match,'Math route gate parseable');
const deny=new Function('adapterCode','subjectKey','scopeCode','componentCode','skillCode','return ('+match[1]+')');
const cases=[
['mathematics','exam_prep','P1','P1-CIR-01',false],
['mathematics','exam_prep','P5','P5-BIN-01',false],
['biology','exam_prep','P1','P1-CIR-01',true],
['economics','exam_prep','P1','P1-CIR-01',true],
['chemistry','exam_prep','P5','P5-BIN-01',true],
['informatics','exam_prep','P5','P5-BIN-01',true],
['mathematics','global','P1','P1-CIR-01',true],
['mathematics','exam_prep','P1','P5-BIN-01',true],
['mathematics','exam_prep','P3','P3-AAA-01',true],
['mathematics','exam_prep','P1','P1-CIR-1',true]
];
for(const [s,scope,p,skill,denied] of cases)
 ok(deny('math_exam_prep_v1',s,scope,p,skill)===denied,'scope '+s+'/'+p+'/'+skill);
ok(deny('unknown','mathematics','exam_prep','P1','P1-CIR-01'),'unapproved adapter rejected');
ok(g.indexOf('approved_source_missing',start)<provider,'no-source blocks provider');
ok(g.indexOf('reserveProviderCall(',start)<provider,'budget reserved before provider');
ok(g.includes('validateGeneratedMessage({'),'provider output validation');
const eg=e.indexOf('guard = await rpc("get_exam_prep_ai_guard_v1"');
const er=e.indexOf('if (!guard?.allowed)',eg);
const ep=e.indexOf('const provider = await callOpenAIProvider(',er);
ok(eg>=0&&eg<er&&er<ep,'Exam Prep AI gate before provider');
ok(e.includes('new Set(["P1", "P5"])')&&e.includes('new Set(["ru", "uz", "en"])'),'P1/P5 and RU/UZ/EN allowlisted');
ok(c.includes('threadKey: "math-exam-prep-" + componentCode'),'separate P1/P5 threads');
ok(c.includes('function activeCoursesScreen()')&&c.includes('function contextualTutorAvailable()'),'correct course screen / Tutor priority');
ok(c.includes('state.threads.clear()')&&c.includes('handleAuthScopeChange(event, session)'),'temporary chats cleared on auth change');
ok(c.includes('PROTECTED_EXAM_PREP_TYPES')&&c.includes('if (currentBlocked())'),'protected assessment blocks chat');
ok(u.includes('isProtectedAssessment(root)')&&u.includes('function canShow()'),'Exam Prep contextual Tutor guards');
ok(h.includes('global-ai-ui.js?v=stage06ctx2'),'QA html uses updated chat');
console.log('STAGE08_MATH_AI_CONTRACT_OK checks='+checks+' route_cases='+cases.length+' provider_calls=0 learner_writes=0');