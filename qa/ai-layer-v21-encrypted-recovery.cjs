// iClub AI §34 — QA-only encrypted lost-response recovery SPIKE.
// NOT included in any deployed Edge function. No real persistent storage,
// no preconfigured secret, no browser access and no academic content.
"use strict";
const {createHash,randomBytes,createCipheriv,createDecipheriv,timingSafeEqual}=require("node:crypto");
const MIN_TTL_MS=1000, DEFAULT_TTL_MS=120000,MAX_TTL_MS=300000;
const sha=x=>createHash("sha256").update(x).digest("hex");
const allowed=new Set(["prepared","generated"]);
const validString=x=>typeof x==="string"&&x.length>=6&&x.length<=200;
const validIdentity=i=>i&&validString(i.requestId)&&validString(i.userId)&&
 validString(i.sessionId)&&/^[a-f0-9]{64}$/.test(i.requestFingerprint)&&
 /^[a-f0-9]{64}$/.test(i.sourceHash)&&Number.isSafeInteger(i.revision)&&i.revision>=0&&
 ["ru","uz","en"].includes(i.locale)&&allowed.has(i.route);
const identityHash=i=>sha(JSON.stringify([
 i.requestId,i.userId,i.sessionId,i.requestFingerprint,
 i.sourceHash,i.revision,i.locale,i.route
]));
const fail=reason=>({ok:false,reason});
class EncryptedRecoveryPrototype {
 constructor({rows,keys,currentKeyId,ttlMs=DEFAULT_TTL_MS,now=()=>Date.now()}={}){
  // Caller-provisioned backend-owned keyring, never supplied by learner.
  if(!(rows instanceof Map)||!(keys instanceof Map)||typeof now!=="function"||
   !Number.isSafeInteger(ttlMs)||ttlMs<MIN_TTL_MS||ttlMs>MAX_TTL_MS||
   !validString(currentKeyId)||!Buffer.isBuffer(keys.get(currentKeyId))||
   keys.get(currentKeyId).length!==32)throw Error("unconfigured_recovery_storage_or_key");
  this.rows=rows;this.keys=keys;this.currentKeyId=currentKeyId;
  this.ttlMs=ttlMs;this.now=now;
 }
 async store({identity,reply,validateFinalized}={}){
  if(!validIdentity(identity)||typeof reply!=="string"||!reply.trim()||
   Buffer.byteLength(reply,"utf8")>8000)return fail("invalid_receipt");
  // The original quota + delivery tombstone MUST be completed. Never store
  // unfinalized provider text or make a charge while storing a receipt.
  if(typeof validateFinalized!=="function")return fail("settlement_unverified");
  let finalized=false;
  try{finalized=await validateFinalized(identity)===true;}catch{}
  if(!finalized)return fail("settlement_unverified");
  if(this.rows.has(identity.requestId))return fail("request_already_recorded");
  const nonce=randomBytes(12);
  const started=this.now();
  if(!Number.isSafeInteger(started)||started<0)return fail("invalid_time");
  const aad=identityHash(identity);
  const cipher=createCipheriv("aes-256-gcm",this.keys.get(this.currentKeyId),nonce);
  cipher.setAAD(Buffer.from(aad,"hex"));
  const ciphertext=Buffer.concat([cipher.update(reply,"utf8"),cipher.final()]);
  const record=Object.freeze({
   keyId:this.currentKeyId,
   identityDigest:aad,
   nonce:nonce.toString("base64url"),
   ciphertext:ciphertext.toString("base64url"),
   authTag:cipher.getAuthTag().toString("base64url"),
   expiresAt:started+this.ttlMs,
   // No user ID, session, prompt, source body, transcript, plan or token totals.
  });
  if(this.rows.has(identity.requestId))return fail("request_already_recorded");
  this.rows.set(identity.requestId,record);
  return {ok:true};
 }
 async recover({identity,revalidate,validateFinalized}={}){
  if(!validIdentity(identity))return fail("receipt_unavailable");
  const row=this.rows.get(identity.requestId);
  if(!row)return fail("receipt_unavailable");
  const nowMs=this.now();
  if(!Number.isSafeInteger(nowMs)||nowMs>=row.expiresAt){
   this.rows.delete(identity.requestId);
   return fail("receipt_unavailable");
  }
  const wanted=Buffer.from(identityHash(identity),"hex");
  const got=Buffer.from(row.identityDigest||"","hex");
  if(wanted.length!==got.length||!timingSafeEqual(wanted,got))
   return fail("receipt_unavailable");
  if(typeof revalidate!=="function"||typeof validateFinalized!=="function")
   return fail("context_unverified");
  let safe=false,settled=false;
  try{
   safe=await revalidate(identity)===true;
   settled=await validateFinalized(identity)===true;
  }catch{}
  if(!safe||!settled)return fail("context_unverified");
  const key=this.keys.get(row.keyId);
  if(!Buffer.isBuffer(key)||key.length!==32)return fail("recovery_key_unavailable");
  let reply;
  try{
   const decipher=createDecipheriv("aes-256-gcm",key,
    Buffer.from(row.nonce,"base64url"));
   decipher.setAAD(wanted);
   decipher.setAuthTag(Buffer.from(row.authTag,"base64url"));
   reply=Buffer.concat([decipher.update(Buffer.from(row.ciphertext,"base64url")),
    decipher.final()]).toString("utf8");
  }catch{return fail("receipt_unavailable");}
  if(!reply.trim()||Buffer.byteLength(reply,"utf8")>8000)
   return fail("receipt_unavailable");
  // NO provider call. NO billing retry. NO exposing internal identifiers.
  return {ok:true,alreadyProcessed:true,reply};
 }
 prune(){
  const t=this.now();
  for(const [id,row] of this.rows)if(t>=row.expiresAt)this.rows.delete(id);
 }
}
module.exports={EncryptedRecoveryPrototype,DEFAULT_TTL_MS};
