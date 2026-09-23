'use strict';
// Auditable branch-only transformation. No writes unless --apply is supplied.
const fs = require('node:fs');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const uiPath = 'exam-prep/exam-prep-progress-ux-ui.js';
const cssPath = 'exam-prep/exam-prep-progress-ux.css';
const ui = fs.readFileSync(uiPath,'utf8');
const css = fs.readFileSync(cssPath,'utf8');
const blobSha = content => crypto.createHash('sha1')
  .update(`blob ${Buffer.byteLength(content)}\0`).update(content).digest('hex');
assert.equal(blobSha(ui),'01aa708cb06fbe8e398c2a525ae72c0feedec5b5',
  'Progress UI changed: inspect the new source before patching.');
assert.equal(blobSha(css),'05ea2819632d4eb84257e9affd5f9596241c223e',
  'Progress CSS changed: inspect the new source before patching.');
let next = ui;
function replace(before,after,label) {
  const at = next.indexOf(before);
  assert(at >= 0 && next.indexOf(before, at+before.length) === -1,`Audit anchor missing or ambiguous: ${label}`);
  next = next.slice(0,at) + after + next.slice(at+before.length);
}
const helper = `  // Only the server's exact goal/plan/action binding can promote a frozen goal
  // into a primary action. If any binding fails, do not hide the existing UI.
  async function promoteGoalActions(card, section, entries, component, state, c) {
    if (window.iClubExamPrepWeeklyFlowEnabled !== true || !state.hasPlan) return;
    const flow = internal.weeklyFlowApi;
    if (!flow || flow.version !== 'weekly_flow_adapter_v1' || flow.allowed(component)) return;
    const buttons = Array.from(card.querySelectorAll('[data-ep-live-plan-item]'));
    const claimed = entries.filter(entry => entry.goal.actionPriorityOrder !== null);
    if (claimed.length !== buttons.length || new Set(claimed.map(entry => entry.goal.actionPriorityOrder)).size !== claimed.length) return;
    const bound = buttons.map(button => {
      const priority = Number(button.dataset.epLivePlanItem);
      const matching = claimed.filter(entry => entry.goal.actionPriorityOrder === priority);
      return matching.length === 1 ? { button, entry: matching[0], priority } : null;
    });
    if (bound.some(entry => !entry)) return;
    const planResult = await internal.api?.weeklyPlan?.(component);
    const planId = planResult?.ok && planResult.data?.plan_id;
    if (typeof planId !== 'string') return;
    const decisions = await Promise.all(bound.map(({entry}) => flow.goal(component,entry.goal.goalId,planId)));
    if (!card.isConnected || !card.contains(section) || !allowed()) return;
    if (decisions.some((result,index) => {
      if (!result?.ok) return true;
      const status = result.data?.status;
      if (!['ready','resume','waiting','content_exhausted','stale'].includes(status)) return true;
      if (status === 'ready' || status === 'resume') {
        const binding = bound[index];
        return result.data?.goal_id !== binding.entry.goal.goalId ||
          result.data?.plan_id !== planId ||
          result.data?.component_code !== component ||
          result.data?.priority_order !== binding.priority;
      }
      return false;
    })) return;
    bound.forEach(({button,entry},index) => {
      const status = decisions[index].data.status;
      if ((status === 'ready' || status === 'resume') && !button.disabled) {
        const action = node('button','ep-live-btn ep-pux-goal-action',
          ({ru:'Продолжить цель',uz:'Maqsadni davom ettirish',en:'Continue goal'})[lang()]);
        action.type = 'button';
        action.dataset.epPuxGoalAction = entry.goal.goalId;
        action.addEventListener('click', () => {
          if (allowed() && card.contains(button) && !button.disabled) button.click();
        });
        entry.row.append(action);
      } else if (status === 'content_exhausted') {
        entry.row.append(node('small','ep-pux-note',({
          ru:'Эти вопросы уже выполнены. Для новой проверки нужны другие задания. Предыдущий результат сохранён.',
          uz:'Bu savollar avval bajarilgan. Yangi tekshiruv uchun boshqa topshiriqlar kerak. Oldingi natija saqlangan.',
          en:'These questions were completed already. A new check needs different questions. Your previous result is saved.'
        })[lang()]));
      } else if (status === 'waiting' || button.disabled) {
        entry.row.append(node('small','ep-pux-note',({
          ru:'Следующее задание пока недоступно.',uz:'Keyingi topshiriq hozircha mavjud emas.',en:'The next task is not available yet.'
        })[lang()]));
      } else if (status === 'stale') {
        entry.row.append(node('small','ep-pux-note',c.changed));
      }
    });
    // Keep original bound buttons in DOM, with their original listeners and Core
    // contracts. The single goal-card CTA delegates to the already guarded native
    // handler; hiding rows does not erase or alter student history.
    card.querySelectorAll('.ep-live-plan-item').forEach(row => {
      row.hidden = true;
      row.style.display = 'none';
    });
    section.querySelector('.ep-pux-section-caption')?.remove();
    section.dataset.epPuxPrimaryGoals = 'verified';
  }
`;
replace('  function showPlan(card, data, component) {',helper+'  async function showPlan(card, data, component) {','helper and async showPlan');
replace('    latestPlan.set(component,state);\n    const section = node(\'section\',\'ep-pux-panel ep-pux-week\');',
  '    latestPlan.set(component,state);\n    const actionRows = [];\n    const section = node(\'section\',\'ep-pux-panel ep-pux-week\');','action rows');
replace('        list.append(row);\n      }\n      section.append(list);',
  '        list.append(row);\n        actionRows.push({goal,row});\n      }\n      section.append(list);','collect rendered goal rows');
replace(`      const notice = card.querySelector('.ep-live-notice');
      if (notice) notice.before(section); else card.append(section);
    }
  }
  function showCompletion(`,
`      const notice = card.querySelector('.ep-live-notice');
      if (notice) notice.before(section); else card.append(section);
    }
    await promoteGoalActions(card,section,actionRows,component,state,c);
  }
  function showCompletion(`,'safe final promotion');
replace("    else if (kind === 'plan') showPlan(target,data,component);",
        "    else if (kind === 'plan') await showPlan(target,data,component);",'async plan dispatch');
const nextCss = css + `
/* Optional verified primary weekly goal. Native duplicate rows stay hidden only
   after an exact server-to-card match; flag OFF renders exactly as before. */
#exam-prep-host-root .ep-pux-goal-action {
  width: 100%;
  min-width: 0;
  max-width: 100%;
  min-height: 44px;
  margin-top: 4px;
  white-space: normal;
  text-align: center;
}
#exam-prep-host-root .ep-live-plan-item[hidden] { display: none !important; }
`;
assert(next.includes('async function showPlan(') && next.includes('await showPlan(target,data,component)'));
if (process.argv.includes('--apply')) {
  fs.writeFileSync(uiPath,next);
  fs.writeFileSync(cssPath,nextCss);
  console.log('Applied audited Progress UI and CSS to isolated checkout only.');
} else {
  console.log('Validated Progress UI and CSS exact patch anchors; unchanged.');
}
