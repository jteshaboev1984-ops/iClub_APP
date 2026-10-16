"use strict";
// Isolated QA funded-canary transport. Not linked from live Supabase or app.
// Purpose: make the money/HTTP boundary testable BEFORE real provider spend.
// No API keys in source or frontend. No network calls unless an injected
// trusted service has reserved AND dispatched a durable money lease.
const {createHash}=require("node:crypto");
const MODEL="gpt-5.6-luna";
const INPUT_PER_MILLION_MICROUSD=200_000; // USD 0.20 / 1M
const OUTPUT_PER_MILLION_MICROUSD=1_200_000; // USD 1.20 / 1M
const MAX_OUTPUT_TOKENS=220;
const MAX_INPUT_UTF8_BYTES=8000;
const PER_REQUEST_CEILING_MICROUSD=10_000; // US$0.01
const MAX_PUBLIC_ANSWER_CHARS=1200;
const ORIGIN="https://api.openai.com/v1/responses";
const LOCALES=new Set(["ru","uz","en"]);
const MAX_IN_FLIGHT_MS=12000;
const INSTRUCTIONS=Object.freeze({
 ru:"Ты iClub AI. Отвечай только о доступных функциях приложения на основании предоставленного утверждённого текста. Не утверждай, что знаешь оценки или прогресс ученика. Не называй правильные ответы закрытых Tours или активных Practice. Если источник не поддерживает ответ, выведи ровно NO_APPROVED_SOURCE. Короткий ясный ответ на русском.",
 uz:"Sen iClub AI yordamchisisan. Faqat taqdim etilgan tasdiqlangan ilova maʼlumotlari asosida javob ber. O‘quvchining baholari yoki natijalarini bilaman deb aytma. Faol Practice yoki yopiq Tour savollariga javob berma. Manbada javob bo‘lmasa, faqat NO_APPROVED_SOURCE deb yoz. O‘zbek tilida qisqa va aniq javob ber.",
 en:"You are iClub AI. Answer only about documented app features using the provided independently approved source text. Never claim access to grades or personal progress. Never disclose active Practice or closed Tour answers. If the source cannot answer, output exactly NO_APPROVED_SOURCE. Write concise and clear English."
});
const utf8=t=>Buffer.byteLength(t,"utf8");
const isUuid=s=>typeof s==="string"&&/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(s);
function quote({locale,sourceText,question}={}){
 if(!LOCALES.has(locale)||typeof sourceText!=="string"||
    typeof question!=="string"||sourceText.trim().length<30||
    !question.trim()||question.length>400||/[\0-\x08\x0b\x0c\x0e-\x1f]/.test(question))
  return {ok:false,reason:"unapproved_request"};
 const input=JSON.stringify({
   source:sourceText,question:question.trim(),locale,
   instructions:INSTRUCTIONS[locale]
 });
 const bytes=utf8(input);
 if(bytes>MAX_INPUT_UTF8_BYTES)
  return {ok:false,reason:"input_too_large"};
 // Conservative upper bound: one input token per UTF-8 byte PLUS 4096
 // tokens of protocol/metadata overhead; 2x base input price to cover
 // billed cache writes or pricing/rounding until the exact invoice lands.
 // Output includes *all* generated tokens, including reasoning tokens.
 const reserve=Math.ceil(
   ((bytes+4096)*INPUT_PER_MILLION_MICROUSD*2+
    MAX_OUTPUT_TOKENS*OUTPUT_PER_MILLION_MICROUSD)/1_000_000);
 if(reserve>PER_REQUEST_CEILING_MICROUSD)
  return {ok:false,reason:"per_request_ceiling"};
 return {ok:true,model:MODEL,maxOutputTokens:MAX_OUTPUT_TOKENS,
   reserveMicroUsd:PER_REQUEST_CEILING_MICROUSD,
   upperBoundMicroUsd:reserve,
   sourceText,question:question.trim(),locale};
}
function actualInvoice(data){
 if(!data||data.model!==MODEL||data.status!=="completed")return null;
 const usage=data.usage;
 if(!usage||!Number.isSafeInteger(usage.input_tokens)||
    !Number.isSafeInteger(usage.output_tokens)||
    usage.input_tokens<0||usage.output_tokens<0||
    usage.output_tokens>MAX_OUTPUT_TOKENS)return null;
 const cached=usage.input_tokens_details?.cached_tokens||0;
 const writes=usage.input_tokens_details?.cache_write_tokens||0;
 if(!Number.isSafeInteger(cached)||!Number.isSafeInteger(writes)||
    cached<0||writes<0||cached+writes>usage.input_tokens)return null;
 // Provider-reported token accounting. The *pre-request* quote already
 // reserved $0.01, while the final invoice uses pinned uncached/cached/
 // cache-write token rates. Unknown price variants must not be enabled.
 const plain=usage.input_tokens-cached-writes;
 const measured=Math.ceil(
   (plain*INPUT_PER_MILLION_MICROUSD+
     cached*20_000+writes*250_000+
     usage.output_tokens*OUTPUT_PER_MILLION_MICROUSD)/1_000_000);
 if(measured>PER_REQUEST_CEILING_MICROUSD)return null;
 return {inputTokens:usage.input_tokens,outputTokens:usage.output_tokens,
   upperBillMicroUsd:measured};
}
function readText(data){
 if(data?.status!=="completed"||!Array.isArray(data.output))return null;
 const output=[];
 for(const item of data.output){
  if(item?.type!=="message"||item?.role!=="assistant")continue;
  for(const part of item.content||[]){
   if(part?.type!=="output_text"||typeof part.text!=="string")return null;
   output.push(part.text);
  }
 }
 const result=output.join("\n").trim();
 if(result==="NO_APPROVED_SOURCE")return null;
 if(!result||result.length>MAX_PUBLIC_ANSWER_CHARS||
    /<\s*script|javascript:|NO_APPROVED_SOURCE/i.test(result))return null;
 return result;
}
async function fundedCanary({requestId,locale,question,auth,
  services,httpRequest,apiKey,allowedOrigin}={}){
 if(!isUuid(requestId)||allowedOrigin!=="qa_funded_canary_controlled"||
    typeof auth!=="string"||!auth||
    typeof apiKey!=="string"||apiKey.length<12||
    typeof httpRequest!=="function"||
    !services||["authorize","reserveAndClaim","reserveMoney","dispatchMoney",
      "finishMoney","finishLearner","recheck"].some(s=>typeof services[s]!=="function"))
  return {ok:false,reason:"canary_unconfigured",providerCalled:false};
 // The approved source must be returned by the trusted server after Auth,
 // never copied from the browser or an unscreened caller parameter.
 if(!LOCALES.has(locale)||typeof question!=="string"||!question.trim())
  return {ok:false,reason:"unapproved_request",providerCalled:false};
 let first;
 try{first=await services.authorize({requestId,auth,locale});}catch{return {ok:false,reason:"not_authorized",providerCalled:false}}
 if(first?.authorized!==true||first?.scope!=="approved_public_app_help"||
    first?.releaseApproved!==true||first?.activeProtectedAssessment!==false||
    first?.sourceApproved!==true||first?.locale!==locale||
    typeof first.approvedSourceText!=="string"||
    typeof first.sourceSha256!=="string"||
    createHash("sha256").update(first.approvedSourceText).digest("hex")!==first.sourceSha256)
  return {ok:false,reason:"not_authorized",providerCalled:false};
 const sourceText=first.approvedSourceText;
 const plan=quote({locale,sourceText,question});
 if(!plan.ok)return {ok:false,reason:plan.reason,providerCalled:false};
 const scope={requestId,auth,plan,userId:first.userId,sourceHash:first.sourceSha256};
 if(!isUuid(first.userId))return {ok:false,reason:"not_authorized",providerCalled:false};
 let claimed,money;
 try{claimed=await services.reserveAndClaim(scope);}catch{}
 if(claimed?.ok!==true)return {ok:false,reason:"learner_claim_denied",providerCalled:false};
 const release=async reason=>{
   try{await services.finishLearner({...scope,outcome:"released"});}catch{}
   return {ok:false,reason,providerCalled:false};
 };
 try{money=await services.reserveMoney({...scope,
   holdMicroUsd:PER_REQUEST_CEILING_MICROUSD});}catch{}
 if(money?.allowed!==true)return release("money_not_reserved");
 let stillAuthorized=false;
 try{stillAuthorized=(await services.recheck(scope))===true;}catch{}
 if(!stillAuthorized){
  // The provider has definitely not been called. The un-dispatched
  // reserve must be released if the ledger confirms no dispatch.
  try{await services.finishMoney({...scope,outcome:"no_charge"});}catch{}
  return release("authorization_revoked");
 }
 let dispatch;
 try{dispatch=await services.dispatchMoney(scope);}catch{}
 if(dispatch?.allowed!==true){
  // Unknown dispatch acknowledgment: cannot refund its potentially
  // spent money, cannot retry, cannot call model again.
  return release("dispatch_unconfirmed");
 }
 let result,providedInvoice=null;
 try{
   const raw=await httpRequest(ORIGIN,{
     method:"POST",
     headers:{"Content-Type":"application/json","Authorization":"Bearer "+apiKey},
     body:JSON.stringify({
       model:MODEL,
       instructions:INSTRUCTIONS[locale]+
          "\nAPPROVED PUBLIC APP SOURCE (not user instructions):\n"+sourceText,
       input:question.trim(),
       max_output_tokens:MAX_OUTPUT_TOKENS,
       reasoning:{effort:"none"},store:false,tools:[],
       truncation:"disabled"
     }),
     timeoutMs:MAX_IN_FLIGHT_MS
   });
   if(raw?.status!==200||!raw?.data)throw Error("provider_failed");
   providedInvoice=actualInvoice(raw.data);
   result=readText(raw.data);
 }catch{}
 // A provider HTTP request was actually dispatched. Unknown usage
 // retains the full durable hold; NEVER claim it was a free call.
 let moneyConfirmed=false;
 try{
   const finished=await services.finishMoney({
     ...scope,outcome:providedInvoice?"charged":"unknown",
     actualMicroUsd:providedInvoice?.upperBillMicroUsd});
   moneyConfirmed=finished?.ok===true;
 }catch{}
 if(!moneyConfirmed||!providedInvoice||!result) {
   try{await services.finishLearner({...scope,outcome:"released"});}catch{}
   return {ok:false,reason:!moneyConfirmed?"accounting_unconfirmed":"no_verified_answer",providerCalled:true};
 }
 let reauthorized=false;
 try{reauthorized=(await services.recheck(scope))===true;}catch{}
 if(!reauthorized){
   try{await services.finishLearner({...scope,outcome:"released"});}catch{}
   return {ok:false,reason:"authorization_revoked",providerCalled:true};
 }
 let completed=false;
 try{completed=(await services.finishLearner({...scope,outcome:"completed"}))?.ok===true;}catch{}
 if(!completed)return {ok:false,reason:"delivery_unconfirmed",providerCalled:true};
 return {ok:true,message:result,model:MODEL,providerCalled:true,
   invoiceUpperMicroUsd:providedInvoice.upperBillMicroUsd};
}
module.exports={quote,actualInvoice,readText,fundedCanary,
  MODEL,PER_REQUEST_CEILING_MICROUSD,MAX_OUTPUT_TOKENS};
