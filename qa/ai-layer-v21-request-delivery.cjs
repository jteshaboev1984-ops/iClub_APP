// iClub AI v2.1: mock-only request receipt integration. Never production-routed.
// This module never imports legacy exam-prep-ai, Supabase or provider clients.
"use strict";
const {EphemeralReplyReceipts}=require("./ai-layer-v21-reply-receipts.cjs");
const fail=reason=>({ok:false,reason});
const allowedText=x=>typeof x==="string"&&x.length>=6&&x.length<=200;
class SyntheticRequestDelivery {
  constructor({execute,authorize,resolveIdentity,receipts=new EphemeralReplyReceipts(),maxCompletedIds=2048}={}) {
    if(typeof execute!=="function"||typeof authorize!=="function"||typeof resolveIdentity!=="function")
      throw Error("missing trusted synthetic dependencies");
    if(!Number.isSafeInteger(maxCompletedIds)||maxCompletedIds<1||maxCompletedIds>10000)
      throw Error("invalid completed request capacity");
    this.execute=execute;this.authorize=authorize;this.resolveIdentity=resolveIdentity;
    this.receipts=receipts;this.maxCompletedIds=maxCompletedIds;
    this.completedIds=new Map();this.inFlightIds=new Set();
  }
  async submit(request) {
    const {requestId,sessionId,principal,nowMs}=request||{};
    if(!allowedText(requestId)||!allowedText(sessionId)||!allowedText(principal?.userId)||
       !Number.isSafeInteger(nowMs)||nowMs<0)return fail("invalid_request");
    // Must be the SERVER-VERIFIED academic context, route and source version.
    // Never trust a browser-provided route/fingerprint.
    let auth;
    try{auth=await this.authorize({request,stage:"preflight"});}
    catch{return fail("context_unverified");}
    if(auth!==true)return fail("context_unverified");
    let identity;
    try{identity=await this.resolveIdentity({request});}
    catch{return fail("identity_unverified");}
    if(!identity||!allowedText(identity.fingerprint)||!["prepared","generated"].includes(identity.route))
      return fail("identity_unverified");
    const {fingerprint,route}=identity;
    const revalidate=async()=>await this.authorize({request,stage:"replay_or_delivery"})===true;
    // Reply must never cross user, session, route or version-bound fingerprint.
    const existing=this.completedIds.get(requestId);
    if(existing) {
      if(existing.userId!==principal.userId||existing.sessionId!==sessionId||
         existing.route!==route||existing.fingerprint!==fingerprint)return fail("request_identity_mismatch");
      const receipt=await this.receipts.retrieve({requestId,userId:principal.userId,
        sessionId,route,fingerprint,nowMs,revalidate});
      // Cache expiry cannot authorize repeating a paid request.
      return receipt.ok ? receipt : (receipt.reason==="receipt_unavailable"
        ? fail("already_processed_receipt_expired"):receipt);
    }
    if(this.inFlightIds.has(requestId))return fail("request_in_progress");
    // Never evict completed IDs to make room: eviction could cause a second
    // provider charge. Backpressure BEFORE model execution when at capacity.
    if(this.completedIds.size+this.inFlightIds.size>=this.maxCompletedIds)
      return fail("idempotency_capacity_full");
    this.inFlightIds.add(requestId);
    try {
      // Explicit second authorization AFTER the reservation decision would
      // live inside a real Edge handler; synthetic pipeline already rechecks.
      const stillAllowed=await revalidate();
      if(!stillAllowed)return fail("context_unverified");
      let result;
      try{result=await this.execute({request});}
      catch{return fail("request_failed");}
      if(!result?.ok||typeof result.reply!=="string"||!result.reply.trim())
        return fail(result?.reason||"response_not_delivered");
      // A completed provider call/charge MUST NEVER be attempted a second time,
      // even when receipt storage fails or is too full. Record first.
      this.completedIds.set(requestId,{userId:principal.userId,sessionId,route,fingerprint});
      const remembered=this.receipts.store({requestId,userId:principal.userId,sessionId,
        fingerprint,route,reply:result.reply,nowMs});
      if(!remembered.ok)return fail("already_processed_receipt_unavailable");
      const safe=await this.receipts.retrieve({requestId,userId:principal.userId,
        sessionId,route,fingerprint,nowMs,revalidate});
      return safe.ok?{ok:true,reply:safe.reply,alreadyProcessed:false}:safe;
    } finally {
      this.inFlightIds.delete(requestId);
    }
  }
  clearSession(userId,sessionId){
    this.receipts.clearSession(userId,sessionId);
    // Intentionally KEEP completed-ID tombstones for the mock server lifetime.
    // Otherwise clearing chat could trigger a second paid model request.
  }
}
module.exports={SyntheticRequestDelivery};
