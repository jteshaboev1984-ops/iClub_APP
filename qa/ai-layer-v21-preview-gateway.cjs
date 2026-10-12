// iClub AI Layer v2.1 — strictly offline, mock-only contract prototype.
// Not imported by production UI. No networking, storage, auth, DB or provider access.
'use strict';
const TEST_POLICIES = Object.freeze({free: 3, plus: 9, pro: 14});
const WEIGHTS = Object.freeze({prepared: 1, generated: 3});
const PERIOD_MS = 5 * 60 * 60 * 1000;
const RESERVATION_TTL_MS = 90 * 1000;
const VALID_LOCALES = new Set(['ru', 'uz', 'en']);
const KNOWN_SURFACES = new Set(['general','home','profile','lesson','exam_prep','practice','tour_archive','video']);
function identityKey(parts) { return parts.map(v => String(v || '').trim().toLowerCase()).join('|'); }
function normalizeQuestion(s) { return String(s || '').trim().replace(/\s+/g, ' ').toLowerCase(); }
function validId(s) { return typeof s === 'string' && /^[a-z0-9-]{6,100}$/i.test(s); }
function fail(reason, extra = {}) { return {ok:false,reason,...extra}; }

class PreviewLedger {
  constructor() { this.periods = new Map(); this.reservations = new Map(); }
  _expirePending(userId, nowMs) {
    for (const r of this.reservations.values()) {
      if (r.userId === userId && r.status === 'reserved' && nowMs >= r.expiresAt) {
        r.status='released';
        r.period.reserved-=r.weight;
      }
    }
  }
  _period(userId, plan, nowMs) {
    this._expirePending(userId, nowMs);
    if (!Object.hasOwn(TEST_POLICIES, plan)) return null;
    let p = this.periods.get(userId);
    if (p && p.plan !== plan) return {error:'plan_transition_requires_review'};
    if (p && p.startedAt !== null && nowMs >= p.startedAt + PERIOD_MS) {
      if (p.reserved > 0) return {error:'prior_period_busy'};
      p = undefined;
    }
    if (!p) { p = {plan, startedAt:null, committed:0, reserved:0}; this.periods.set(userId, p); }
    return p;
  }
  inspect(userId,plan,nowMs) {
    const p = this._period(userId,plan,nowMs);
    if (!p || p.error) return fail(p?.error || 'unknown_plan');
    return {ok:true,remaining:TEST_POLICIES[plan]-p.committed-p.reserved,
      committed:p.committed,reserved:p.reserved,
      resetAt:p.startedAt===null?null:p.startedAt+PERIOD_MS};
  }
  reserve({userId,plan,requestId,requestFingerprint,route,nowMs}) {
    if (!validId(userId) || !validId(requestId) || !requestFingerprint || !Object.hasOwn(WEIGHTS,route)) return fail('invalid_request');
    const original = this.reservations.get(requestId);
    if (original) {
      if (original.userId!==userId || original.plan!==plan || original.requestFingerprint!==requestFingerprint || original.route!==route) return fail('request_reuse_mismatch');
      if (original.status==='completed') return {ok:true,duplicate:true,alreadyCompleted:true,reply:original.reply};
      return original.status==='reserved'?fail('request_in_progress'):fail('request_already_released');
    }
    if (plan==='free' && route==='generated') return fail('generation_not_entitled');
    const p = this._period(userId,plan,nowMs);
    if (!p || p.error) return fail(p?.error||'unknown_plan');
    const remaining = TEST_POLICIES[plan]-p.committed-p.reserved,weight=WEIGHTS[route];
    if (remaining<weight) {
      if (p.reserved>0 && TEST_POLICIES[plan]-p.committed>=weight) return fail('usage_busy',{remaining});
      return fail('route_insufficient',{remaining,resetAt:p.startedAt===null?null:p.startedAt+PERIOD_MS});
    }
    p.reserved+=weight;
    this.reservations.set(requestId,{userId,plan,requestFingerprint,route,weight,period:p,status:'reserved',reply:null,expiresAt:nowMs+RESERVATION_TTL_MS});
    return {ok:true,duplicate:false,remaining:remaining-weight};
  }
  finalize(requestId,reply,nowMs) {
    const r=this.reservations.get(requestId);
    if (!r) return fail('reservation_missing');
    if (r.status==='completed') return {ok:true,duplicate:true,reply:r.reply};
    if (r.status==='released') return fail('request_already_released');
    if (nowMs >= r.expiresAt) { this.release(requestId); return fail('reservation_expired'); }
    if (typeof reply!=='string' || !reply.trim()) return fail('invalid_reply');
    const p=r.period;
    if (p.reserved<r.weight || p.committed+r.weight>TEST_POLICIES[r.plan]) throw Error('meter invariant violation');
    p.reserved-=r.weight;p.committed+=r.weight;
    if (p.startedAt===null) p.startedAt=nowMs;
    r.status='completed';r.reply=reply;
    return {ok:true,duplicate:false,reply,resetAt:p.startedAt+PERIOD_MS};
  }
  release(requestId) {
    const r=this.reservations.get(requestId);
    if (!r) return fail('reservation_missing');
    if (r.status==='completed') return fail('completed_cannot_refund');
    if (r.status==='released') return {ok:true,duplicate:true};
    r.period.reserved-=r.weight;r.status='released';return {ok:true,duplicate:false};
  }
}

class PreviewGateway {
  constructor({sources=[]}={}) {
    this.ledger=new PreviewLedger();
    this.sources=new Map();this.modelCallAttempts=0;
    for (const src of sources) {
      const k=identityKey([src.surface,src.subject,src.feature,src.topic,src.locale]);
      if (this.sources.has(k)) throw Error('ambiguous duplicate source');
      this.sources.set(k,Object.freeze({...src,variants:Object.freeze({...src.variants}),aliases:Object.freeze({...src.aliases})}));
    }
  }
  request({requestId,user,context,question,nowMs=0,provider='success',budgetAllowed=true}) {
    // This interface is a server-owned MOCK contract. Never expose 'context' or 'user' as
    // authority sourced directly from a browser in the future real implementation.
    if (!user || !context || !question || !Number.isFinite(nowMs) || !validId(requestId)) return fail('invalid_request');
    if (!validId(user.userId) || !Object.hasOwn(TEST_POLICIES,user.plan)) return fail('invalid_identity');
    // Protected work blocks every route BEFORE source lookup, cache, metering or model.
    if (context.protectedAssessment===true || context.activeTour===true) return fail('protected_assessment');
    if (context.surface==='practice' && context.practiceCompleted!==true) return fail('practice_not_finished');
    if (context.surface==='tour_archive' && context.archiveUnlocked!==true) return fail('archive_locked');
    if (!KNOWN_SURFACES.has(context.surface) || context.capabilityEnabled!==true) return fail('in_development');
    if (!VALID_LOCALES.has(question.resolvedLocale)) return fail('locale_unverified');
    const k=identityKey([context.surface,context.subject,context.feature,context.topic,question.resolvedLocale]);
    const src=this.sources.get(k);
    if (!src || src.approved!==true || src.rightsApproved!==true || src.readinessPassed!==true || !src.version || !src.sourceId) return fail('in_development');
    if (src.conflict===true) return fail('source_conflict');
    const normalized=normalizeQuestion(question.text);
    if (normalized.length>2000) return fail('input_too_long');
    if (!normalized && !question.promptKey) return fail('empty_input');
    let variant=null;
    if (question.promptKey) {
      if (normalized && (!Object.hasOwn(src.aliases,normalized) || src.aliases[normalized]!==question.promptKey)) return fail('invalid_prompt_context');
      if (typeof question.promptKey!=='string' || !Object.hasOwn(src.variants,question.promptKey)) return fail('in_development');
      variant=question.promptKey;
    } else if (Object.hasOwn(src.aliases,normalized)) {
      variant=src.aliases[normalized];
      if (!Object.hasOwn(src.variants,variant)) return fail('source_incomplete');
    }
    // No fuzzy matching: arbitrary text must go through approved sourced model path.
    const route=variant?'prepared':'generated';
    if (route==='generated' && src.generationAllowed!==true) return fail('in_development');
    if (route==='generated' && user.plan==='free') return fail('generation_not_entitled');
    if (route==='generated' && budgetAllowed!==true) return fail('provider_budget_unavailable');
    const fingerprint=JSON.stringify([user.userId,user.plan,k,question.promptKey||'',normalized,route,src.version]);
    const reservation=this.ledger.reserve({userId:user.userId,plan:user.plan,requestId,requestFingerprint:fingerprint,route,nowMs});
    if (!reservation.ok) return reservation;
    if (reservation.alreadyCompleted) return {ok:true,duplicate:true,route,reply:reservation.reply};
    let reply;
    if (route==='prepared') reply=src.variants[variant];
    else {
      this.modelCallAttempts++;
      if (provider!=='success') { this.ledger.release(requestId); return fail(provider==='timeout'?'provider_timeout':'provider_failure'); }
      reply=src.syntheticGeneratedReply; // Mock only. NEVER model-generated academic output.
    }
    if (typeof reply!=='string'||!reply.trim()||reply.length>3000) {
      this.ledger.release(requestId);return fail('output_validation_failed');
    }
    const done=this.ledger.finalize(requestId,reply,nowMs);
    return {...done,route,sourceId:src.sourceId};
  }
}
module.exports={PreviewGateway,PreviewLedger,TEST_POLICIES,WEIGHTS,PERIOD_MS,RESERVATION_TTL_MS};
