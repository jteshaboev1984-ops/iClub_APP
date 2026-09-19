'use strict';
// Branch-only source transform. No database access, credentials, deployments or production writes.
// This file does NOT edit anything unless --apply is explicitly supplied.
const fs = require('node:fs');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const path = 'exam-prep/exam-prep-live.js';
const source = fs.readFileSync(path, 'utf8');
function gitBlobSha(content) {
  return crypto.createHash('sha1').update(`blob ${Buffer.byteLength(content)}\0`).update(content).digest('hex');
}
assert.equal(gitBlobSha(source), '0ee0a11c787eb08a649425b93d665042ffa50a5e',
  'Native Exam Prep has changed; STOP and re-audit rather than overwrite new work.');
let next = source;
function replaceOnce(before, after, label) {
  const first = next.indexOf(before);
  assert(first >= 0, `Missing audited anchor: ${label}`);
  assert.equal(next.indexOf(before, first + before.length), -1, `Ambiguous anchor: ${label}`);
  next = next.slice(0, first) + after + next.slice(first + before.length);
}
replaceOnce(`  async function openPlan(component) {
    clearTimer(); renderLoading();
    let planResult = await internal.api.weeklyPlan(component);
    if (!planResult?.ok) { renderError(); return; }
    let plan = planResult.data;
    if (!plan?.plan_id) {
      const generated = await internal.api.generateWeeklyPlan(component, "normal");
      if (!generated?.ok) { renderError(); return; }
      planResult = await internal.api.weeklyPlan(component); plan = planResult?.data;
    }
    if (!planResult?.ok || !plan?.plan_id) { renderError(copy().noPlan); return; }
    renderPlan(component, plan);
  }`, `  async function openPlan(component) {
    clearTimer(); renderLoading();
    // The new weekly flow is an explicit OFF-by-default cutover. Never fall back to
    // a plan-changing legacy RPC if its audited server contract is unavailable.
    if (window.iClubExamPrepWeeklyFlowEnabled === true) {
      const flow = internal.weeklyFlowApi;
      if (!flow || flow.version !== 'weekly_flow_adapter_v1' || flow.allowed(component)) {
        renderError(); return;
      }
      const ensured = await flow.plan(component);
      if (!ensured?.ok) { renderError(); return; }
      if (ensured.data?.status === 'resume_first') {
        const recovery = ensured.data.recovery;
        if (!['resume','ready_to_finalize'].includes(recovery?.status) || !recovery?.session_id) {
          renderError(); return;
        }
        state.returnView = { kind: 'plan', component };
        await loadSession(recovery.session_id);
        return;
      }
      const read = await internal.api.weeklyPlan(component);
      if (!read?.ok || !read.data?.plan_id || read.data.plan_id !== ensured.data?.plan_id) {
        renderError(); return;
      }
      renderPlan(component, read.data);
      return;
    }
    let planResult = await internal.api.weeklyPlan(component);
    if (!planResult?.ok) { renderError(); return; }
    let plan = planResult.data;
    if (!plan?.plan_id) {
      const generated = await internal.api.generateWeeklyPlan(component, "normal");
      if (!generated?.ok) { renderError(); return; }
      planResult = await internal.api.weeklyPlan(component); plan = planResult?.data;
    }
    if (!planResult?.ok || !plan?.plan_id) { renderError(copy().noPlan); return; }
    renderPlan(component, plan);
  }`, 'openPlan');
replaceOnce(`  async function launchPlanItem(component, planId, priorityOrder) {
    if (state.busy) return; state.busy = true; renderLoading();
    const auth = await internal.api.authorizePlanItem(planId, priorityOrder);
    if (!auth?.ok || !auth.data?.authorization_id) { state.busy = false; renderError(); return; }
    const started = await internal.api.startSession(auth.data.authorization_id, key("ep-plan-session")); state.busy = false;
    if (!started?.ok || !started.data?.session_id) { renderError(); return; }
    state.returnView = { kind: "plan", component }; await loadSession(started.data.session_id);
  }`, `  async function launchPlanItem(component, planId, priorityOrder) {
    if (state.busy) return; state.busy = true; renderLoading();
    if (window.iClubExamPrepWeeklyFlowEnabled === true) {
      const flow = internal.weeklyFlowApi;
      const progress = typeof internal.progressUxApi?.progress === 'function'
        ? await internal.progressUxApi.progress(component) : null;
      const matching = Array.isArray(progress?.data?.goals) ? progress.data.goals.filter(goal =>
        goal.component_code === component && goal.action_priority_order === priorityOrder) : [];
      if (!flow || flow.allowed(component) || !progress?.ok || matching.length !== 1) {
        state.busy = false; renderError(); return;
      }
      const selected = matching[0];
      const authorization = await flow.authorize(component, selected.goal_id, planId);
      if (!authorization?.ok) { state.busy = false; renderError(); return; }
      if (authorization.data?.status === 'resume_existing_session_first' || authorization.data?.status === 'resume') {
        const sessionId = authorization.data?.recovery?.session_id || authorization.data?.session_id;
        state.busy = false;
        if (!sessionId) { renderError(); return; }
        state.returnView = { kind: 'plan', component }; await loadSession(sessionId); return;
      }
      if (authorization.data?.status !== 'authorized' || !authorization.data?.authorization_id) {
        state.busy = false;
        const seen = authorization.data?.status === 'content_exhausted';
        renderError(seen ? ({ ru:'Этот набор уже выполнен. Для новой проверки нужны другие задания. Предыдущие ответы сохранены.',
          uz:'Bu savollar avval bajarilgan. Yangi tekshiruv uchun boshqa topshiriqlar kerak. Oldingi javoblar saqlangan.',
          en:'You have already completed these questions. A new check needs different questions. Your earlier answers are saved.' })[state.language] : null);
        return;
      }
      const started = await flow.start(component, authorization.data.authorization_id, key('ep-plan-session'));
      state.busy = false;
      const sessionId = started?.ok ? started.data?.session_id :
        (started?.reason === 'start_outcome_unknown' ? started.recovery?.session_id : null);
      if (!sessionId || (started?.ok && !['started','resume','resume_existing_session_first'].includes(started.data?.status))) {
        renderError(); return;
      }
      state.returnView = { kind: 'plan', component };
      await loadSession(sessionId);
      return;
    }
    const auth = await internal.api.authorizePlanItem(planId, priorityOrder);
    if (!auth?.ok || !auth.data?.authorization_id) { state.busy = false; renderError(); return; }
    const started = await internal.api.startSession(auth.data.authorization_id, key("ep-plan-session")); state.busy = false;
    if (!started?.ok || !started.data?.session_id) { renderError(); return; }
    state.returnView = { kind: "plan", component }; await loadSession(started.data.session_id);
  }`, 'launchPlanItem');
replaceOnce(`      else { await internal.api.generateWeeklyPlan(component, "normal"); state.notice = copy().completedTask; await openPlan(component); }`,
`      else {
        if (window.iClubExamPrepWeeklyFlowEnabled !== true) {
          await internal.api.generateWeeklyPlan(component, "normal");
          state.notice = copy().completedTask;
        } else {
          state.notice = ({ ru:'Занятие сохранено. Недельный план не изменён.',
            uz:'Mashg‘ulot saqlandi. Haftalik reja o‘zgarmadi.',
            en:'Session saved. Your weekly plan has not changed.' })[state.language];
        }
        await openPlan(component);
      }`, 'finalization plan retention');
assert(!next.includes('else { await internal.api.generateWeeklyPlan(component, "normal"); state.notice = copy().completedTask;'),
  'Unconditional finalization regeneration remains');
if (process.argv.includes('--apply')) {
  fs.writeFileSync(path, next);
  console.log('Applied three exact native cutover replacements to isolated branch checkout.');
} else {
  console.log('Validated three exact native cutover replacements; source NOT modified.');
}
