/**
 * iClub Exam Prep — draft-only native weekly plan selector v1.
 * NO production import; NO DB writes; NO grading or progress promotion.
 * Input must be a server-verified snapshot; client-provided evidence is not authoritative.
 * Only fully approved, released and all-locales-verified tasks can be proposed.
 */
"use strict";
function buildPlan(input) {
  "use strict";
  const supportedPapers = Object.freeze({AS:["P1","P2"],staged:["P3","P4"],linear:["P1","P2","P3","P4"]});
  const papersByKind = {P1:"mcq",P2:"written",P3:"mcq",P4:"written"};
  const kinds = new Set(["diagnostic","theory","mcq","written","correction","retest","mixed","timed","paper"]);
  if (!input || input.program_key!=="economics_9708" || input.program_version!=="economics_2026_2028_v1")
    throw new Error("unsupported_program_version");
  if (!Object.prototype.hasOwnProperty.call(supportedPapers,input.route)) throw new Error("invalid_exam_route");
  if (!Array.isArray(input.target_papers) || !input.target_papers.length ||
      new Set(input.target_papers).size!==input.target_papers.length ||
      input.target_papers.some(p=>!supportedPapers[input.route].includes(p)))
    throw new Error("invalid_paper_selection");
  if (!["en","ru","uz"].includes(input.locale)) throw new Error("invalid_locale");
  const budget=input.budget||{};
  const positive=n=>Number.isSafeInteger(n)&&n>0;
  if (!positive(budget.total_student_minutes) || !positive(budget.economics_minutes) ||
    budget.economics_minutes>budget.total_student_minutes) throw new Error("invalid_time_budget");
  if (!positive(input.max_items) || input.max_items>30) throw new Error("invalid_item_limit");
  if (!input.paper_state || typeof input.paper_state!=="object" || !Array.isArray(input.catalog))
    throw new Error("missing_server_plan_facts");
  if (!Array.isArray(input.focus) || !Array.isArray(input.corrections) || !Array.isArray(input.retests))
    throw new Error("missing_evidence_backed_recommendations");
  for (const paper of input.target_papers) {
    const state=input.paper_state[paper];
    if (!state || !Number.isInteger(state.stage) || state.stage<0 || state.stage>6 ||
      typeof state.diagnostic_verified!=="boolean") throw new Error("invalid_paper_state");
  }
  const available=input.catalog.filter(x=>{
    if (!x || !kinds.has(x.kind) || !input.target_papers.includes(x.paper_code) ||
        x.program_key!==input.program_key || x.program_version!==input.program_version ||
        typeof x.task_key!=="string" || !x.task_key.trim() ||
        typeof x.task_version!=="string" || !x.task_version.trim() ||
        !positive(x.estimated_minutes)) return false;
    if (x.status!=="approved" || x.mapping_status!=="approved" || x.release_enabled!==true ||
        x.source_ready!==true || x.security_ready!==true ||
        !x.locales || !["ru","uz","en"].every(l=>x.locales[l]===true)) return false;
    if (x.link_role!=="direct" && !(x.kind==="theory" && x.link_role==="prerequisite"))
      return false;
    if (["mcq","diagnostic","retest","mixed","timed","paper"].includes(x.kind) &&
        x.checking_contract!=="server_objective" && x.checking_contract!=="no_automatic_score") return false;
    if (x.kind==="mcq" && papersByKind[x.paper_code]!=="mcq") return false;
    if (x.kind==="written" && papersByKind[x.paper_code]!=="written") return false;
    if (x.kind==="paper" && papersByKind[x.paper_code]==="written" &&
        x.checking_contract!=="no_automatic_score") return false;
    if (x.kind!=="theory" && x.link_role!=="direct") return false;
    return true;
  }).sort((a,b)=>(a.priority??999)-(b.priority??999)||
    String(a.task_key).localeCompare(String(b.task_key))||String(a.task_version).localeCompare(String(b.task_version)));
  const tasks=[], blockers=[], used=new Set();
  const proposalQueues=new Map(input.target_papers.map(p=>[p,[]]));
  let minutes=0;
  function choose(paper,kind,skillKey,reason) {
    const match=available.find(x=>x.paper_code===paper && x.kind===kind &&
      (skillKey===null ? (x.skill_key===null || x.skill_key===undefined) : x.skill_key===skillKey) &&
      !used.has(x.task_key+"|"+x.task_version+"|"+x.paper_code));
    if (!match) {blockers.push({paper_code:paper,kind,skill_key:skillKey,reason:"approved_content_missing"});return;}
    used.add(match.task_key+"|"+match.task_version+"|"+match.paper_code);
    proposalQueues.get(paper).push({
      paper_code:paper,kind,skill_key:match.skill_key??null,
      task_key:match.task_key,task_version:match.task_version,
      estimated_minutes:match.estimated_minutes,
      evidence_rule:match.kind==="written" || match.link_role==="prerequisite" ||
        match.checking_contract==="no_automatic_score" ? "no_mastery_from_navigation" : "server_verification_required",
      purpose:reason
    });
  }
  for (const paper of input.target_papers) {
    const state=input.paper_state[paper];
    if (!state.diagnostic_verified) {
      choose(paper,"diagnostic",null,"diagnose_component");
      continue;
    }
    if (state.stage<2) {
      blockers.push({paper_code:paper,reason:"stage_gate_not_satisfied"});
      continue;
    }
    const scoped=(arr)=>arr.filter(x=>x && x.paper_code===paper && typeof x.skill_key==="string" && x.skill_key.trim());
    const retests=[...new Set(scoped(input.retests).map(x=>x.skill_key))];
    for(const skill of retests) choose(paper,"retest",skill,"delayed_retest");
    const corrections=[...new Set(scoped(input.corrections).map(x=>x.skill_key))];
    for(const skill of corrections) choose(paper,"correction",skill,"correct_verified_error");
    const focus=[...new Set(scoped(input.focus).map(x=>x.skill_key))];
    for(const skill of focus) {
      choose(paper,"theory",skill,"learn_skill");
      choose(paper,papersByKind[paper],skill,"practice_skill");
    }
    if (state.stage>=3) choose(paper,"mixed",null,"mixed_application");
    if (state.stage>=4) choose(paper,"timed",null,"timed_transfer");
    if (state.stage>=5) choose(paper,"paper",null,"paper_rehearsal");
  }
  // Schedule one step per paper per round. Paper ordering is fixed by the
  // authorized exam profile; a dense P1 catalog must not starve P2.
  let more=true;
  while (more) {
    more=false;
    for (const paper of input.target_papers) {
      const queue=proposalQueues.get(paper);
      if (!queue.length) continue;
      more=true;
      const step=queue.shift();
      if (tasks.length>=input.max_items || minutes+step.estimated_minutes>budget.economics_minutes) {
        blockers.push({paper_code:paper,kind:step.kind,skill_key:step.skill_key,reason:"weekly_capacity_reached"});
        continue;
      }
      minutes+=step.estimated_minutes;
      tasks.push(step);
    }
  }
  return Object.freeze({
    contract_version:"native_weekly_plan_draft_v1",
    release_authorized:false, // NEVER a learner-facing or publication authorization.
    state:tasks.length ? "draft_steps_available" : "no_approved_study_steps",
    program_key:input.program_key,program_version:input.program_version,route:input.route,
    target_papers:[...input.target_papers],
    budget_minutes:budget.economics_minutes,planned_minutes:minutes,
    steps:tasks,blockers,
    disclaimer:"Planning candidate only. No mastery, grade, readiness or stage transition is awarded."
  });
}
module.exports=Object.freeze({buildPlan});
