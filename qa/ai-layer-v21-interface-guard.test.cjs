// Run from repo root: node --test qa/ai-layer-v21-interface-guard.test.cjs
// Offline source and behavior contract. Does NOT call Supabase, Vercel or AI.
'use strict';
const {test}=require('node:test');
const assert=require('node:assert/strict');
const vm=require('node:vm');
const fs=require('node:fs');
const js=fs.readFileSync('global-ai-ui.js','utf8');
const css=fs.readFileSync('global-ai-ui.css','utf8');
const start=js.indexOf('  function reconcileShell(');
const end=js.indexOf('  function reconcileTourBlock(',start);
assert.ok(start>0 && end>start,'Cannot find controlled shell lifecycle function');
const shellCode=js.slice(start,end);
function scenario({visible=true,eligible=true,blocked=true,announceBlock=false}={}) {
 const button={hidden:false,attrs:new Map(),setAttribute(n,v){this.attrs.set(n,v);},removeAttribute(n){this.attrs.delete(n);}};
 const host={hidden:false},events=[];
 const state={bootstrap:{visible},serverBlocked:blocked,examPrepBlocked:false,tourBlocked:false,lastBlocked:false,context:{threadKey:'general'}};
 const scope={state,isEligibleView:()=>eligible,currentBlocked:()=>state.serverBlocked||state.examPrepBlocked||state.tourBlocked,
   closePanel:()=>events.push('closed'),root:()=>host,ensureShell:()=>host,mark:()=>button,
   resolveContext:()=>state.context,copy:()=>({open:'Open iClub AI',assessmentStart:'AI unavailable during exam'}),
   renderPanel:()=>events.push('rendered'),showToast:t=>events.push('toast:'+t),
   document:{documentElement:{classList:{add:()=>{},remove:()=>{}}}}
 };
 vm.runInNewContext(shellCode+'; reconcileShell({announceBlock: '+String(announceBlock)+'});',scope);
 return {button,host,events,state};
}
test('During protected assessment the floating mark is hidden, not dimmed',()=>{
 const x=scenario({blocked:true,announceBlock:true});
 assert.equal(x.button.hidden,true);
 assert.equal(x.button.attrs.get('aria-expanded'),'false');
 assert.ok(x.events.includes('closed'));
 assert.ok(x.events.some(e=>e.startsWith('toast:')));
});
test('After assessment the mark is visible again',()=>{
 const x=scenario({blocked:false});assert.equal(x.button.hidden,false);
 assert.equal(x.button.attrs.get('aria-label'),'Open iClub AI');
});
test('App-disabled Global AI shell is fully hidden',()=>{
 const x=scenario({visible:false});assert.equal(x.host.hidden,true);
 assert.ok(x.events.includes('closed'));
});
test('Unsupported app screen leaves shell hidden',()=>{
 const x=scenario({eligible:false});assert.equal(x.host.hidden,true);
});
test('Author CSS overrides mark display when hidden',()=>{
 assert.ok(css.includes('.iclub-global-ai-mark[hidden]'));
 assert.match(css,/\.iclub-global-ai-mark\[hidden\]\s*\{\s*display:\s*none\s*!important;/);
});
test('Insufficient expensive-route budget does not invoke global exhaustion',()=>{
 const marker=js.indexOf('if (reason === "route_insufficient")');
 const legacy=js.indexOf('if (reason === "usage_exhausted")',marker);
 assert.ok(marker>0 && legacy>marker);
 const branch=js.slice(marker,legacy);
 assert.ok(branch.includes('routeInsufficient'));
 assert.ok(!branch.includes('setUsageExhausted('));
 for(const locale of ['Для этого ответа','Bu javob uchun','There is not enough allowance'])assert.ok(js.includes(locale));
});
test('Global UI code still refuses action during protected assessment',()=>{
 assert.match(js,/if \(state\.busy \|\| currentBlocked\(\) \|\| state\.usageExhausted \|\| !state\.context\) return;/);
 assert.match(js,/if \(currentBlocked\(\)\)\s*\{\s*showToast/);
});

test('Unpublished topic displays proofread three-language In development notice',()=>{
 for(const text of [
  'В разработке. AI-помощь по этой теме пока готовится.',
  'Ishlab chiqilmoqda. Bu mavzu bo‘yicha AI yordami hali tayyorlanmoqda.',
  'In development. AI help for this topic is being prepared.'
 ])assert.ok(js.includes(text),text);
});
test('Not-ready mode is not treated as exhausted quota or a provider answer',()=>{
 const from=js.indexOf('if (["in_development", "subject_not_ready"');
 const to=js.indexOf('} catch {',from);
 assert.ok(from>0&&to>from);
 const part=js.slice(from,to);
 assert.ok(part.includes('copy().inDevelopment'));
 assert.ok(part.includes('data.mode === "in_development"'));
 assert.ok(!part.includes('setUsageExhausted('));
 assert.ok(!part.includes('topicMain'));
});
