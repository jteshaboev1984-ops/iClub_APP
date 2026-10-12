// iClub AI Layer v2.1 — TEMPORARY in-memory response receipt, QA ONLY.
// No database, browser storage, provider, timers, network or legacy Tutor access.
// Server must call retrieve only after a NEW authorization, assessment and
// source-version check. Short-lived reply is never kept as a permanent transcript.
"use strict";
const DEFAULT_TTL_MS = 120000;
const FAIL = (reason)=>({ok:false,reason});
class EphemeralReplyReceipts {
  constructor({ttlMs=DEFAULT_TTL_MS,maxEntries=256}={}) {
    if(!Number.isSafeInteger(ttlMs)||ttlMs<1000||ttlMs>300000)throw Error("invalid ttl");
    if(!Number.isSafeInteger(maxEntries)||maxEntries<1||maxEntries>10000)throw Error("invalid capacity");
    this.ttlMs=ttlMs;this.maxEntries=maxEntries;this.entries=new Map();
  }
  prune(nowMs){
    if(!Number.isSafeInteger(nowMs)||nowMs<0)throw Error("invalid time");
    for(const [key,value]of this.entries)if(nowMs>=value.expiresAt)this.entries.delete(key);
  }
  store({requestId,userId,sessionId,fingerprint,route,reply,nowMs}){
    this.prune(nowMs);
    if(!this._valid(requestId,userId,sessionId,fingerprint,route)||
       typeof reply!=="string"||!reply.trim()||reply.length>8000)return FAIL("invalid_receipt");
    const existing=this.entries.get(requestId);
    if(existing)return existing.userId===userId&&existing.sessionId===sessionId&&
      existing.fingerprint===fingerprint&&existing.route===route&&existing.reply===reply
      ?{ok:true,duplicate:true}:FAIL("receipt_collision");
    if(this.entries.size>=this.maxEntries)return FAIL("receipt_capacity_full");
    this.entries.set(requestId,{requestId,userId,sessionId,fingerprint,route,reply,expiresAt:nowMs+this.ttlMs});
    return {ok:true,duplicate:false};
  }
  async retrieve({requestId,userId,sessionId,fingerprint,route,nowMs,revalidate}){
    this.prune(nowMs);
    const e=this.entries.get(requestId);
    if(!e)return FAIL("receipt_unavailable");
    // Return no answer, including when an ID belongs to another learner.
    if(!this._valid(requestId,userId,sessionId,fingerprint,route)||
       e.userId!==userId||e.sessionId!==sessionId||
       e.fingerprint!==fingerprint||e.route!==route)return FAIL("receipt_unavailable");
    if(typeof revalidate!=="function")return FAIL("context_unverified");
    let safe=false;
    try{safe=(await revalidate({userId,sessionId,requestId,route,fingerprint}))===true;}
    catch{return FAIL("context_unverified");}
    if(!safe)return FAIL("context_unverified");
    // No source keys, usage weights, audit records, or other private data.
    return {ok:true,reply:e.reply,alreadyProcessed:true};
  }
  clearSession(userId,sessionId){
    for(const [key,r]of this.entries)if(r.userId===userId&&r.sessionId===sessionId)this.entries.delete(key);
  }
  _valid(id,user,session,fp,route){
    const str=x=>typeof x==="string"&&x.length>=6&&x.length<=200;
    return str(id)&&str(user)&&str(session)&&str(fp)&&["prepared","generated"].includes(route);
  }
}
module.exports={EphemeralReplyReceipts,DEFAULT_TTL_MS};
