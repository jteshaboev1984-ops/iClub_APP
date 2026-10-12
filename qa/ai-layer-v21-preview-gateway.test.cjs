// Deterministic, offline, preview-only test matrix. Run:
// node --test qa/ai-layer-v21-preview-gateway.test.cjs
'use strict';
const assert=require('node:assert/strict');
const {test}=require('node:test');
const {PreviewGateway,PreviewLedger,PERIOD_MS,RESERVATION_TTL_MS}=require('./ai-layer-v21-preview-gateway.cjs');
const source=(over={})=>({
 surface:'exam_prep',subject:'mathematics',feature:'theory',topic:'P1_01',locale:'ru',
 sourceId:'qa-p1-01',version:'qa-v1',approved:true,rightsApproved:true,readinessPassed:true,conflict:false,
 generationAllowed:true,variants:{topic_main:'Подготовленное проверенное объяснение'},
 aliases:{'объясни тему':'topic_main'},syntheticGeneratedReply:'Искусственный ответ без платного провайдера',...over
});
const context=(over={})=>({surface:'exam_prep',subject:'mathematics',feature:'theory',topic:'P1_01',capabilityEnabled:true,...over});
const user=(plan='plus',id='learner-001')=>({userId:id,plan});
const request=(id,over={})=>({requestId:id,user:user(),context:context(),question:{text:'объясни тему',resolvedLocale:'ru'},nowMs:100,...over});
const qa=()=>new PreviewGateway({sources:[source()]});
const success=x=>assert.equal(x.ok,true,x.reason);
test('Remaining 2: generated 3 rejected, two prepared 1 allowed',()=>{
 const g=qa();for(let i=0;i<7;i++)success(g.request(request('prepared-'+i)));
 assert.equal(g.ledger.inspect('learner-001','plus',100).remaining,2);
 assert.equal(g.request(request('generated-1',{question:{text:'Новый пример для решения',resolvedLocale:'ru'}})).reason,'route_insufficient');
 assert.equal(g.modelCallAttempts,0);
 success(g.request(request('prepared-seven')));success(g.request(request('prepared-eight')));
 assert.equal(g.ledger.inspect('learner-001','plus',100).remaining,0);
});
test('Exact prepared alias; distinct open question uses generation',()=>{
 const g=qa();assert.equal(g.request(request('exact-1')).route,'prepared');
 assert.equal(g.request(request('custom-1',{question:{text:'Какова нестандартная ситуация?',resolvedLocale:'ru'}})).route,'generated');
 assert.equal(g.modelCallAttempts,1);
});
test('Prepared prompt ID rejects arbitrary added content, unknown variant denied',()=>{
 const g=qa();
 assert.equal(g.request(request('bad-extra',{question:{promptKey:'topic_main',text:'Секретный ключ',resolvedLocale:'ru'}})).reason,'invalid_prompt_context');
 assert.equal(g.request(request('bad-prompt',{question:{promptKey:'unapproved',text:'',resolvedLocale:'ru'}})).reason,'in_development');
 success(g.request(request('good-prompt',{question:{promptKey:'topic_main',text:'',resolvedLocale:'ru'}})));
});
test('Unknown topic, wrong screen or unready source fail closed',()=>{
 const g=qa();
 assert.equal(g.request(request('wrong-topic',{context:context({topic:'P1_02'})})).reason,'in_development');
 assert.equal(g.request(request('wrong-surface',{context:context({surface:'profile'})})).reason,'in_development');
 assert.equal(new PreviewGateway({sources:[source({approved:false})]}).request(request('not-approved')).reason,'in_development');
});
test('A Russian source does not authorize English and malformed locale is denied',()=>{
 const g=qa();
 assert.equal(g.request(request('not-en',{question:{text:'Explain this',resolvedLocale:'en'}})).reason,'in_development');
 assert.equal(g.request(request('bad-lang',{question:{text:'Test',resolvedLocale:'zz'}})).reason,'locale_unverified');
});
test('Source contradiction and rights failure deny all responses',()=>{
 for(const v of [{conflict:true},{rightsApproved:false},{readinessPassed:false}]){
  const g=new PreviewGateway({sources:[source(v)]});
  assert.equal(g.request(request('blocked')).ok,false);assert.equal(g.modelCallAttempts,0);
 }
});
test('Exam, live Tour, incomplete Practice, locked Tour archive fail before usage',()=>{
 const g=qa();
 assert.equal(g.request(request('exam-123',{context:context({protectedAssessment:true})})).reason,'protected_assessment');
 assert.equal(g.request(request('tour-123',{context:context({activeTour:true})})).reason,'protected_assessment');
 assert.equal(g.request(request('practice',{context:context({surface:'practice',practiceCompleted:false})})).reason,'practice_not_finished');
 assert.equal(g.request(request('archive',{context:context({surface:'tour_archive',archiveUnlocked:false})})).reason,'archive_locked');
 assert.equal(g.ledger.inspect('learner-001','plus',100).committed,0);
});
test('Free plan: no generation, exactly 3 prepared',()=>{
 const g=qa(),u=user('free','learner-free');
 assert.equal(g.request(request('free-gen',{user:u,question:{text:'Other application',resolvedLocale:'ru'}})).reason,'generation_not_entitled');
 for(let i=0;i<3;i++)success(g.request(request('free-'+i,{user:u})));
 assert.equal(g.request(request('free-fourth',{user:u})).reason,'route_insufficient');
});
test('All full-budget mixed combinations work for Plus and Pro',()=>{
 for(const plan of ['plus','pro']) {
  const cap=plan==='plus'?9:14;
  for(let gen=0;gen<=Math.floor(cap/3);gen++){
   const u=user(plan,'learner-'+plan+'-'+gen),g=qa();
   for(let i=0;i<gen;i++)success(g.request(request('gen-'+plan+'-'+gen+'-'+i,{user:u,question:{text:'Уникальный запрос '+i,resolvedLocale:'ru'}})));
   for(let i=0;i<cap-3*gen;i++)success(g.request(request('prep-'+plan+'-'+gen+'-'+i,{user:u})));
   assert.equal(g.ledger.inspect(u.userId,plan,100).remaining,0);
   assert.equal(g.modelCallAttempts,gen);
  }
 }
});
test('No model call or usage when provider budget exhausted',()=>{
 const g=qa();
 assert.equal(g.request(request('budget',{budgetAllowed:false,question:{text:'Новый вопрос',resolvedLocale:'ru'}})).reason,'provider_budget_unavailable');
 assert.equal(g.modelCallAttempts,0);assert.equal(g.ledger.inspect('learner-001','plus',100).remaining,9);
});
test('Provider timeout releases 3-unit reservation',()=>{
 const g=qa();
 assert.equal(g.request(request('time-out',{provider:'timeout',question:{text:'Новый вопрос',resolvedLocale:'ru'}})).reason,'provider_timeout');
 assert.equal(g.ledger.inspect('learner-001','plus',100).remaining,9);
 success(g.request(request('after-fail')));assert.equal(g.ledger.inspect('learner-001','plus',100).remaining,8);
});
test('Invalid model reply and blank prepared reply cannot consume quota',()=>{
 for(const [variant,query] of [[{syntheticGeneratedReply:' '},{text:'Новый вопрос',resolvedLocale:'ru'}],[{variants:{topic_main:' '}},{text:'объясни тему',resolvedLocale:'ru'}]]){
  const g=new PreviewGateway({sources:[source(variant)]});
  assert.equal(g.request(request('invalid-output',{question:query})).reason,'output_validation_failed');
  assert.equal(g.ledger.inspect('learner-001','plus',100).remaining,9);
 }
});
test('Successful retries replay reply; never charge or call provider twice',()=>{
 const g=qa(),x=request('retry-123',{question:{text:'Новый вопрос',resolvedLocale:'ru'}});
 const a=g.request(x),b=g.request(x);success(a);success(b);
 assert.equal(b.duplicate,true);assert.equal(a.reply,b.reply);
 assert.equal(g.modelCallAttempts,1);assert.equal(g.ledger.inspect('learner-001','plus',100).committed,3);
});
test('Request id cannot be replayed under a different user or route',()=>{
 const g=qa();success(g.request(request('reused-123')));
 assert.equal(g.request(request('reused-123',{user:user('plus','learner-other')})).ok,false);
 assert.equal(g.request(request('reused-123',{question:{text:'Другой вопрос',resolvedLocale:'ru'}})).ok,false);
});
test('User balances do not leak or mix',()=>{
 const g=qa();success(g.request(request('user-a123',{user:user('plus','learner-a')})));
 assert.equal(g.ledger.inspect('learner-b','plus',100).committed,0);
});
test('First successful response starts the five-hour window, not a failure',()=>{
 const g=qa();
 g.request(request('failed-100',{provider:'error',question:{text:'Нестандартное применение',resolvedLocale:'ru'}}));
 assert.equal(g.ledger.inspect('learner-001','plus',100).resetAt,null);
 success(g.request(request('success-200',{nowMs:200})));
 assert.equal(g.ledger.inspect('learner-001','plus',200).resetAt,200+PERIOD_MS);
 assert.equal(g.ledger.inspect('learner-001','plus',200+PERIOD_MS).remaining,9);
});
test('Pending reservations block overspend but refund leaves cheap route available',()=>{
 const l=new PreviewLedger();
 for(const id of ['reservation-one','reservation-two','reservation-three'])success(l.reserve({userId:'learner-aaa',plan:'plus',requestId:id,requestFingerprint:id,route:'generated',nowMs:100}));
 assert.equal(l.reserve({userId:'learner-aaa',plan:'plus',requestId:'excess-prep',requestFingerprint:'x',route:'prepared',nowMs:100}).reason,'usage_busy');
 success(l.release('reservation-one'));
 success(l.reserve({userId:'learner-aaa',plan:'plus',requestId:'cheap-prep',requestFingerprint:'y',route:'prepared',nowMs:100}));
});
test('Expired reservation is cleaned and never backcharged',()=>{
 const l=new PreviewLedger();
 success(l.reserve({userId:'learner-aaa',plan:'plus',requestId:'expires-123',requestFingerprint:'x',route:'generated',nowMs:0}));
 assert.equal(l.inspect('learner-aaa','plus',RESERVATION_TTL_MS+1).remaining,9);
 assert.equal(l.finalize('expires-123','too late',RESERVATION_TTL_MS+1).reason,'request_already_released');
});
test('In-flight last-moment reservation defers five-hour period reset',()=>{
 const l=new PreviewLedger();
 success(l.reserve({userId:'learner-aaa',plan:'plus',requestId:'first-request',requestFingerprint:'x',route:'prepared',nowMs:0}));
 success(l.finalize('first-request','done',0));
 success(l.reserve({userId:'learner-aaa',plan:'plus',requestId:'last-request',requestFingerprint:'y',route:'generated',nowMs:PERIOD_MS-10}));
 assert.equal(l.inspect('learner-aaa','plus',PERIOD_MS).reason,'prior_period_busy');
 success(l.release('last-request'));
 assert.equal(l.inspect('learner-aaa','plus',PERIOD_MS).remaining,9);
});
test('Plan changes during an active period cannot mint extra allowance',()=>{
 const l=new PreviewLedger();
 success(l.reserve({userId:'learner-aaa',plan:'plus',requestId:'plan-request',requestFingerprint:'x',route:'prepared',nowMs:0}));
 success(l.finalize('plan-request','ok',0));
 assert.equal(l.inspect('learner-aaa','pro',1).reason,'plan_transition_requires_review');
});

test('Server context changes before generated provider: no call, no charge',()=>{
 const g=qa();
 const input=request('race-before-provider',{context:context({serverRecheck:(stage)=>false}),question:{text:'Новый пример',resolvedLocale:'ru'}});
 assert.equal(g.request(input).reason,'context_changed');
 assert.equal(g.modelCallAttempts,0);
 assert.equal(g.ledger.inspect('learner-001','plus',100).remaining,9);
});
test('New protected exam after provider started prevents delivery and learner charge',()=>{
 const g=qa(),calls=[];
 const input=request('race-after-provider',{context:context({serverRecheck:(stage)=>{
  calls.push(stage);return stage==='before_provider';
 }}),question:{text:'Новый пример',resolvedLocale:'ru'}});
 assert.equal(g.request(input).reason,'context_changed');
 assert.deepEqual(calls,['before_provider','before_delivery']);
 assert.equal(g.modelCallAttempts,1); // provider expense may have occurred
 assert.equal(g.ledger.inspect('learner-001','plus',100).remaining,9);
});
test('No processed prepared answer after protection is enabled before delivery',()=>{
 const g=qa();
 const input=request('race-prepared',{context:context({serverRecheck:(stage)=>stage==='before_provider'})});
 assert.equal(g.request(input).reason,'context_changed');
 assert.equal(g.ledger.inspect('learner-001','plus',100).committed,0);
});
test('A server recheck exception denies and releases reservation',()=>{
 const g=qa();
 const input=request('guard-throws',{context:context({serverRecheck:()=>{throw Error('guard backend unavailable');}})});
 assert.equal(g.request(input).reason,'context_changed');
 assert.equal(g.ledger.inspect('learner-001','plus',100).remaining,9);
});

test('An already charged answer cannot be replayed after server context becomes protected',()=>{
 const g=qa();let protectedNow=false;
 const input=request('replay-protected',{context:context({serverRecheck:()=>!protectedNow}),
   question:{text:'Новый пример',resolvedLocale:'ru'}});
 const first=g.request(input);assert.equal(first.ok,true);
 protectedNow=true;
 const retry=g.request(input);
 assert.equal(retry.reason,'context_changed');
 assert.equal(g.modelCallAttempts,1);
 assert.equal(g.ledger.inspect('learner-001','plus',100).committed,3);
});
test('Safe retry with unchanged server authority returns same answer once',()=>{
 const g=qa(),input=request('replay-authorized',{context:context({serverRecheck:()=>true}),
  question:{text:'Новый пример',resolvedLocale:'ru'}});
 const first=g.request(input),second=g.request(input);
 assert.equal(first.ok,true);assert.equal(second.ok,true);
 assert.equal(second.duplicate,true);assert.equal(second.reply,first.reply);
 assert.equal(g.modelCallAttempts,1);
 assert.equal(g.ledger.inspect('learner-001','plus',100).committed,3);
});
