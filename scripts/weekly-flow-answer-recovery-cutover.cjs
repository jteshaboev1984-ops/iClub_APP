'use strict';
// Reviewable, OFF-by-default source cutover; no implicit writes and no production contact.
// Use --apply only on an isolated working tree. GitHub branch promotion is separately gated.
const fs=require('node:fs');
const crypto=require('node:crypto');
const assert=require('node:assert/strict');
const path='exam-prep/exam-prep-live.js';
const source=fs.readFileSync(path,'utf8');
const sha=crypto.createHash('sha1').update(`blob ${Buffer.byteLength(source)}\0${source}`).digest('hex');
const BASE='b340b229de4698a506466397557bf477a86dbb36';
const head='  async function submitAnswer(item) {';
const tail='\n  async function finishTimed(reason) {';
assert.equal(sha,BASE,'Refuse to change an unaudited live client. Re-review exact new source first.');
const begin=source.indexOf(head),end=source.indexOf(tail,begin);
assert(begin>0&&end>begin&&source.indexOf(head,begin+1)===-1&&source.indexOf(tail,end+1)===-1,'One precise answer handler only');
const old=source.slice(begin,end);
assert(old.includes('state.busy = true; clearTimer(); renderLoading();'),'Expected old destructive loading route');
assert(old.includes('internal.api.submitResponse('),'Expected direct submission route');
const replacement=String.raw`  // The guarded weekly route never discards a learner's answer before the
  // server confirms persistence. Read-only reconciliation precedes any retry.
  function answerRecoveryCopy() {
    return ({
      ru: { saving:'Сохраняем ответ…', saved:'Ответ сохранён.', uncertain:'Не удалось подтвердить сохранение. Ваш ответ остаётся на экране. Пока статус не подтверждён, не закрывайте эту страницу.', retryReady:'Сервер пока не показывает сохранённый ответ. Можно повторно отправить ТОТ ЖЕ ответ; другая попытка не создаётся.', check:'Проверить сохранение', retry:'Повторить отправку' },
      uz: { saving:'Javob saqlanmoqda…', saved:'Javob saqlandi.', uncertain:'Javob saqlangani tasdiqlanmadi. Javobingiz ekranda qoldi. Holat aniqlanmaguncha sahifani yopmang.', retryReady:'Server hali saqlangan javobni ko‘rsatmayapti. AYNAN shu javobni qayta yuborishingiz mumkin; yangi urinish ochilmaydi.', check:'Saqlanganini tekshirish', retry:'Qayta yuborish' },
      en: { saving:'Saving answer…', saved:'Answer saved.', uncertain:'We could not confirm that your answer was saved. It remains on screen. Please keep this page open until its status is confirmed.', retryReady:'The server does not show a saved answer yet. You may resend the SAME answer without starting a new attempt.', check:'Check saved answer', retry:'Resend same answer' }
    })[state.language] || answerRecoveryCopyFallback();
  }

  function answerRecoveryCopyFallback() {
    return { saving:'Saving answer…', saved:'Answer saved.', uncertain:'Answer status is not confirmed. Keep this page open.', retryReady:'You may resend the same answer.', check:'Check saved answer', retry:'Resend same answer' };
  }

  function showAnswerRecovery(pending) {
    if (state.pendingSubmission !== pending) return;
    const root=rootEl(), card=root?.querySelector('.ep-live-card');
    if (!card) return;
    root.querySelector('.ep-host-shell')?.removeAttribute('aria-busy');
    root.querySelectorAll('input,textarea,select').forEach(control => { control.disabled=true; });
    const submit=root.querySelector('[data-ep-live-submit]');
    if (submit) { submit.disabled=true; submit.hidden=true; submit.removeAttribute('aria-busy'); }
    const exit=root.querySelector('[data-ep-live-exit]');
    if (exit) exit.disabled=true;
    root.querySelector('[data-ep-answer-recovery]')?.remove();
    const content=answerRecoveryCopy();
    const panel=document.createElement('aside');
    panel.dataset.epAnswerRecovery='true';
    panel.className='ep-live-error';
    panel.setAttribute('role','alert');
    const message=document.createElement('p');
    message.textContent=pending.retryAllowed ? content.retryReady : content.uncertain;
    const actions=document.createElement('div');
    actions.className='ep-live-actions';
    const check=document.createElement('button');
    check.type='button'; check.className='ep-live-btn secondary';
    check.dataset.epAnswerCheck='true'; check.textContent=content.check;
    check.disabled=state.busy;
    check.addEventListener('click',() => reconcilePendingAnswer(pending));
    actions.append(check);
    if (pending.retryAllowed) {
      const retry=document.createElement('button');
      retry.type='button'; retry.className='ep-live-btn';
      retry.dataset.epAnswerRetry='true'; retry.textContent=content.retry;
      retry.disabled=state.busy;
      retry.addEventListener('click',() => {
        if (state.busy || state.pendingSubmission !== pending || !pending.retryAllowed) return;
        pending.retryAllowed=false;
        void sendPendingAnswer(pending);
      });
      actions.append(retry);
    }
    panel.append(message,actions);
    card.append(panel);
  }

  async function reconcilePendingAnswer(pending) {
    if (state.busy || state.pendingSubmission !== pending) return;
    state.busy=true;
    showAnswerRecovery(pending);
    let read=null;
    try { read=await internal.api.getSession(pending.sessionId,state.language); } catch (_) {}
    if (state.pendingSubmission !== pending) { state.busy=false; return; }
    const same=read?.ok && read.data?.session_id===pending.sessionId &&
      read.data?.component_code===pending.component;
    const found=same && Array.isArray(read.data.items) ?
      read.data.items.filter(row => Number(row?.item_order)===pending.itemOrder) : [];
    if (found.length===1 && found[0].answered===true) {
      state.pendingSubmission=null;
      state.busy=false;
      state.notice=answerRecoveryCopy().saved;
      await loadSession(pending.sessionId);
      return;
    }
    pending.retryAllowed=Boolean(found.length===1 && found[0].answered===false && read.data.status==='active');
    state.busy=false;
    showAnswerRecovery(pending);
  }

  async function sendPendingAnswer(pending) {
    if (state.busy || state.pendingSubmission !== pending) return;
    state.busy=true;
    const root=rootEl(), submit=root?.querySelector('[data-ep-live-submit]');
    if (submit) { submit.disabled=true; submit.textContent=answerRecoveryCopy().saving; submit.setAttribute('aria-busy','true'); }
    root?.querySelectorAll('[data-ep-answer-check],[data-ep-answer-retry]').forEach(button => { button.disabled=true; });
    let result;
    try {
      result=await internal.api.submitResponse(pending.sessionId,pending.itemOrder,
        pending.payload,pending.idempotencyKey,pending.elapsedMs,state.language);
    } catch (_) { result={ok:false,reason:'unknown_response'}; }
    if (state.pendingSubmission !== pending) { state.busy=false; return; }
    if (result?.ok) {
      state.pendingSubmission=null;
      state.busy=false;
      const data=result.data || {}, c=copy(), parts=[];
      if (typeof data.is_correct==='boolean') parts.push(data.is_correct?c.correct:c.incorrect);
      if (data.diagnostic_feedback) parts.push(data.diagnostic_feedback);
      else if (data.explanation) parts.push(data.explanation);
      if (data.next_action) parts.push(data.next_action);
      state.notice=parts.filter(Boolean).join(' — ');
      await loadSession(pending.sessionId);
      return;
    }
    // This client-only rejection made no RPC; keep all controls editable.
    if (result?.reason==='understanding_checks_incomplete') {
      state.pendingSubmission=null;
      state.busy=false;
      const screen=rootEl();
      screen?.querySelector('.ep-host-shell')?.removeAttribute('aria-busy');
      screen?.querySelectorAll('input,textarea,select').forEach(control=>{control.disabled=false;});
      screen?.querySelector('[data-ep-answer-recovery]')?.remove();
      const button=screen?.querySelector('[data-ep-live-submit]');
      if (button) {button.hidden=false;button.disabled=false;button.removeAttribute('aria-busy');button.textContent=copy().submit;}
      const exit=screen?.querySelector('[data-ep-live-exit]'); if (exit) exit.disabled=false;
      return;
    }
    state.busy=false;
    // The write may have committed even if its acknowledgment vanished. No auto resend.
    await reconcilePendingAnswer(pending);
  }

  async function submitAnswer(item) {
    if (state.busy || !state.session || state.pendingSubmission) return;
    let payload;
    if (item.item_kind === 'written') {
      const value=rootEl()?.querySelector('textarea[name="ep_live_written_answer"]')?.value?.trim();
      if (!value) return; payload={artifact:{text:value}};
    } else if (String(item.qtype || '').toLowerCase()==='mcq') {
      const chosen=rootEl()?.querySelector('input[name="ep_live_answer"]:checked');
      if (!chosen) return; payload={picked_index:Number(chosen.value)};
    } else {
      const value=rootEl()?.querySelector('input[name="ep_live_text_answer"]')?.value?.trim();
      if (!value) return; payload={answer:value};
    }
    // Diagnostic and timed/paper sessions retain their own existing contracts.
    if (window.iClubExamPrepWeeklyFlowEnabled===true && state.returnView?.kind==='plan'
        && !['diagnostic','timed','paper'].includes(state.session.session_type)) {
      const pending={sessionId:state.session.session_id,component:state.session.component_code,
        itemOrder:Number(item.item_order),payload,idempotencyKey:key('ep-answer'),
        elapsedMs:Math.max(0,Date.now()-state.itemStartedAt),retryAllowed:false};
      state.pendingSubmission=pending;
      await sendPendingAnswer(pending);
      return;
    }
    state.busy=true; clearTimer(); renderLoading();
    const result=await internal.api.submitResponse(state.session.session_id,item.item_order,payload,
      key('ep-answer'),Date.now()-state.itemStartedAt,state.language); state.busy=false;
    if (!result?.ok) { renderError(); return; }
    const data=result.data || {}, c=copy(), parts=[];
    if (typeof data.is_correct==='boolean') parts.push(data.is_correct?c.correct:c.incorrect);
    if (data.diagnostic_feedback) parts.push(data.diagnostic_feedback);
    else if (data.explanation) parts.push(data.explanation);
    if (data.next_action) parts.push(data.next_action);
    state.notice=parts.filter(Boolean).join(' — '); await loadSession(state.session.session_id);
  }
`;
let next=source.slice(0,begin)+replacement+source.slice(end);
const reset='state.session = null; state.returnView = null; state.notice = null; }';
assert.equal(next.split(reset).length,2,'Unique reset call anchor');
next=next.replace(reset,'state.session = null; state.returnView = null; state.notice = null; state.pendingSubmission = null; }');
assert(!next.includes('localStorage')&&!next.includes('sessionStorage'),'Answer drafts must not be written to shared browser storage');
if(process.argv.includes('--apply')) {
  fs.writeFileSync(path,next);
  console.log('Applied exact reviewed answer recovery patch ONLY to native live client in isolated working tree.');
} else {
  console.log('Exact native answer handler and reset anchors verified; no source modified.');
}
