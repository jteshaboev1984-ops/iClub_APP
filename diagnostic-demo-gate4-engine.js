(()=>{'use strict';
const G=window.ICLUB_DEMO_GATE4_DATA;if(!G)return;
const uniq=rows=>[...new Set((rows||[]).filter(Boolean))];
const currentQuestionMap=()=>window.ICLUB_DEMO_V12_DATA?.questions||[];
const normalizeAttempt=a=>({
 id:String(a?.id||'current'),kind:'diagnostic',score:Number(a?.score||0),total:Number(a?.total||currentQuestionMap().length),date:a?.date||null,seconds:Number(a?.seconds||0),
 answers:(a?.answers||[]).map((x,i)=>{
  const q=currentQuestionMap().find(v=>v.id===x.questionId)||{};
  const skillId=G.currentMap[x.questionId]||q.skillId||null;
  const selected=x.selected||null;
  const correct=selected===q.a;
  return {evidenceId:`current:${x.questionId}`,attemptId:String(a?.id||'current'),questionId:x.questionId,order:Number(q.order||i+1),skillId,selected,correct,diagnosisId:selected?G.distractors?.[x.questionId]?.[selected]||null:null,difficulty:q.difficulty||null,qtype:'mcq',timeSpent:Number(x.timeSpent||0),timeLimit:Number(q.seconds||0),newQuestion:true,assisted:false};
 })
});
function statusFor(skillId,currentRows,historicalRows){
 const current=currentRows.filter(x=>x.skillId===skillId&&x.selected);
 const hist=historicalRows.filter(x=>x.skillId===skillId);
 const histWrong=hist.filter(x=>!x.correct);
 const currentWrong=current.filter(x=>!x.correct);
 const currentRight=current.filter(x=>x.correct);
 const sameDiagnosis=currentWrong.some(c=>histWrong.some(h=>h.diagnosisId&&c.diagnosisId===h.diagnosisId));
 let status='insufficient',reason='no_independent_check',repeatedError=false,positiveSignal=false;
 if(currentWrong.length){status='needs_verification';reason=histWrong.length?'historical_error_repeated':'current_error';repeatedError=!!histWrong.length;}
 else if(currentRight.length>=2){status='current_session';reason='multiple_current_correct';positiveSignal=true;}
 else if(currentRight.length===1&&histWrong.length){status='new_question';reason='historical_error_correct_on_new_question';positiveSignal=true;}
 else if(currentRight.length===1){status='needs_verification';reason='single_correct_signal';positiveSignal=true;}
 else if(histWrong.length){status='needs_verification';reason='historical_error_not_rechecked';}
 else if(hist.some(x=>x.correct)){status='insufficient';reason='historical_correct_without_new_check';}
 const evidence=[...hist,...current].map(x=>x.evidenceId);
 const confidence=repeatedError?(sameDiagnosis||histWrong.length>1?'high':'medium'):(status==='current_session'?'medium':positiveSignal?'medium':'low');
 return {skillId,status,reason,repeatedError,positiveSignal,sameDiagnosis,confidence,evidence,current,history:hist,historicalWrongCount:histWrong.length,currentRightCount:currentRight.length,currentWrongCount:currentWrong.length};
}
function pairState(pairId,skillStates){
 const ids=G.pairs[pairId]||[],rows=ids.map(id=>skillStates.find(x=>x.skillId===id)).filter(Boolean);
 const tested=rows.filter(x=>x.currentRightCount+x.currentWrongCount>0);
 const right=tested.filter(x=>x.currentRightCount>0&&!x.currentWrongCount).length;
 const wrong=tested.filter(x=>x.currentWrongCount>0).length;
 return {pairId,skills:ids,tested:right+wrong,right,wrong,confirmedCurrent:tested.length>=2&&wrong===0,hasRepeated:rows.some(x=>x.repeatedError),evidence:uniq(rows.flatMap(x=>x.evidence))};
}
function chooseTargeted(skillStates){
 const unresolved=skillStates.filter(s=>s.repeatedError||s.currentWrongCount||s.reason==='historical_error_not_rechecked');
 const positive=skillStates.filter(s=>s.positiveSignal&&!s.repeatedError);
 const priority=new Map();
 unresolved.forEach(s=>priority.set(s.skillId,s.repeatedError?100:s.currentWrongCount?85:65));
 positive.forEach(s=>{if(!priority.has(s.skillId))priority.set(s.skillId,35)});
 const historicalCore=['profit_maximisation_condition','external_private_cost','public_good_characteristics','price_taker_meaning','contestability_meaning'];
 historicalCore.forEach(id=>{if(!priority.has(id))priority.set(id,55)});
 return G.reinforcement.filter(q=>priority.has(q.skillId)).map(q=>({...q,priority:priority.get(q.skillId)})).sort((a,b)=>b.priority-a.priority||a.order-b.order).slice(0,6);
}
function compute(input={}){
 const current=normalizeAttempt(input.currentAttempt||{});
 const histAttempts=G.attempts||[];
 const tour4=histAttempts.find(x=>x.id==='tour4')||{answers:[],coverage:[]};
 const practice4=histAttempts.find(x=>x.id==='practice4')||{answers:[],coverage:[]};
 const historicalRows=histAttempts.flatMap(a=>a.answers||[]);
 const skillIds=uniq([...Object.keys(G.skills||{}),...historicalRows.map(x=>x.skillId),...current.answers.map(x=>x.skillId)]);
 const skills=skillIds.map(id=>statusFor(id,current.answers,historicalRows));
 const pairs=Object.keys(G.pairs||{}).map(id=>pairState(id,skills));
 const tour4Errors=(tour4.answers||[]).filter(x=>!x.correct);
 const p4Coverage=new Set(practice4.coverage||[]);
 const currentCoverage=new Set(current.answers.filter(x=>x.selected).map(x=>x.skillId));
 const unverifiedErrors=tour4Errors.filter(e=>!p4Coverage.has(e.skillId)&&!currentCoverage.has(e.skillId)).map(e=>({skillId:e.skillId,evidenceId:e.evidenceId,diagnosisId:e.diagnosisId}));
 const repeated=skills.filter(x=>x.repeatedError&&x.currentWrongCount>0);
 const improved=skills.filter(x=>x.positiveSignal&&x.currentRightCount>0);
 const targeted=chooseTargeted(skills);
 const currentAnswered=current.answers.filter(x=>x.selected).length;
 const practice4Overlap=uniq((tour4.coverage||[]).filter(id=>p4Coverage.has(id)));
 const practice4ErrorOverlap=uniq(tour4Errors.filter(e=>p4Coverage.has(e.skillId)).map(e=>e.skillId));
 const whatCan=[];
 const whatCannot=[];
 const evidenceClaims=[];
 if(practice4.score===practice4.total){
  whatCan.push({id:'coverage_mismatch',params:{tour4Skills:(tour4.coverage||[]).length,practice4Skills:(practice4.coverage||[]).length,overlap:practice4Overlap.length,errorOverlap:practice4ErrorOverlap.length,unverified:unverifiedErrors.length},evidence:['tour4','practice4',...tour4Errors.map(x=>x.evidenceId),...(practice4.answers||[]).map(x=>x.evidenceId)]});
 }
 repeated.forEach(s=>whatCan.push({id:'repeated_error',skillId:s.skillId,diagnosisId:s.current.find(x=>!x.correct)?.diagnosisId||null,evidence:s.evidence}));
 improved.forEach(s=>whatCan.push({id:'positive_signal',skillId:s.skillId,evidence:s.evidence}));
 const efficiency=pairs.find(x=>x.pairId==='efficiency_conditions');
 if(efficiency?.confirmedCurrent)whatCan.push({id:'efficiency_pair_current_session',pairId:'efficiency_conditions',evidence:efficiency.evidence});
 if(currentAnswered===0)whatCannot.push({id:'no_current_check'});
 whatCannot.push({id:'not_overall_level'});
 if(improved.length)whatCannot.push({id:'not_mastered_from_one_correct',skills:improved.map(x=>x.skillId)});
 if(unverifiedErrors.length)whatCannot.push({id:'practice4_did_not_close_history',count:unverifiedErrors.length,skills:uniq(unverifiedErrors.map(x=>x.skillId))});
 whatCannot.push({id:'no_guessing_claim_from_time'});
 const confidence=currentAnswered===0?'insufficient':repeated.length>=2?'high':repeated.length||improved.length?'medium':'insufficient';
 const brief=currentAnswered===0?'historical_only':repeated.length>=2?'close_concepts_repeated':repeated.length===1?'one_pattern_repeated':improved.length>=3?'broad_positive_signal':improved.length?'mixed_positive_signal':'insufficient_current';
 whatCan.forEach(x=>evidenceClaims.push({claimId:x.id,evidenceIds:uniq(x.evidence||[])}));
 const invalid=[];
 if(tour4.score!==6||tour4.total!==20)invalid.push('tour4_summary_mismatch');
 if(practice4.score!==10||practice4.total!==10)invalid.push('practice4_summary_mismatch');
 if(tour4Errors.length!==14)invalid.push('tour4_error_count_mismatch');
 if(G.reinforcement.some(q=>q.activeTour))invalid.push('targeted_contains_active_tour');
 if(new Set(G.reinforcement.map(q=>q.id)).size!==G.reinforcement.length)invalid.push('duplicate_targeted_id');
 return {engineVersion:G.version,valid:invalid.length===0,validationErrors:invalid,profileId:'demo_sardor',historicalSummary:{attempts:histAttempts.map(a=>({id:a.id,kind:a.kind,no:a.no,score:a.score,total:a.total,date:a.date,role:a.role,coverageCount:(a.coverage||[]).length})),tour4Errors:tour4Errors.length,practice4OverlapSkills:practice4Overlap,practice4ErrorOverlapSkills:practice4ErrorOverlap,unverifiedTour4Errors:unverifiedErrors},currentAttemptSummary:{id:current.id,score:current.score,total:current.total,answered:currentAnswered,correct:current.answers.filter(x=>x.correct).length,wrong:current.answers.filter(x=>x.selected&&!x.correct).length},skills,pairs,repeatedErrors:repeated.map(x=>x.skillId),positiveSignals:improved.map(x=>x.skillId),whatCanBeConcluded:whatCan,whatCannotBeConcluded:whatCannot,targetedQuestionIds:targeted.map(x=>x.id),targetedSet:targeted,confidence,briefConclusion:brief,claimEvidence:evidenceClaims};
}
window.ICLUB_DEMO_DIAGNOSTIC_ENGINE={version:G.version,compute,normalizeAttempt};
})();