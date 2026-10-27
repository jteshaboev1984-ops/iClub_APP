// Only a focused PC3 admission/response test: no network, DB or provider calls.
import {verifiedSummary,makeProviderBody,validateQuestion,
 sourceSufficientForQuestion,verifiedProviderResponse,MODEL,TOKEN_CAP}
 from "./practice_freeform_pc3_core.ts";
const eq=(condition:boolean,message:string)=>{
 if(!condition)throw Error(message);
};
Deno.test("verified 7/10 supports result-question-only prompt",()=>{
 const input={ok:true,context:{intent:"practice_result",locale:"ru",
  attempt_ref:501,subject_key:"mathematics",completed:true,
  total:10,correct:7,incorrect:3,unattempted:0,percentage:70,
  reviewable_error_ordinals:[2,6,9],
  available_actions:["review_attempt","correct_mistakes"]}};
 const context=verifiedSummary(input,"practice_result","ru");
 eq(!!context,"Server facts rejected");
 eq(!Object.hasOwn(context!,"reviewable_error_ordinals"),
    "Private wrong-question positions leaked into freeform prompt");
 const body=makeProviderBody("Почему мой результат 70%?",context!,"ru");
 eq(body?.model===MODEL&&body.max_output_tokens===TOKEN_CAP,
    "Unexpected model/caps");
 eq(!JSON.stringify(body).includes('"attempt_ref"'),
    "Attempt identifier should never go to the model");
});
Deno.test("unknown academic concepts or wrong-question explanations refuse before model",()=>{
 eq(!sourceSufficientForQuestion("Реши задачу №6 и скажи правильный ответ"),
  "Wrong question was admitted without academic source");
 eq(!sourceSufficientForQuestion("Why was question 6 wrong?"),
  "English problem-specific request was admitted");
 eq(!sourceSufficientForQuestion("Masalani yechib ber, natija qanday?"),
  "Uzbek academic problem was admitted");
 eq(sourceSufficientForQuestion("Что означает результат 70%?"),
  "Result-only query should be allowed");
 eq(!validateQuestion("<script>alert(1)</script>"),
  "Untrusted HTML accepted");
});
Deno.test("provider charge is bounded and refusal is handled as a deliverable",()=>{
 const sample={status:"completed",model:"gpt-5.4-mini",usage:{
  input_tokens:320,output_tokens:58},output:[{
   type:"message",role:"assistant",status:"completed",
   content:[{type:"output_text",text:
     "Результат 70% означает 7 верных ответов из 10. Проверьте три ошибки."}]
 }]};
 const response=verifiedProviderResponse(sample);
 eq(response?.actual_microusd===501,"Incorrect existing price calculation");
 eq(verifiedProviderResponse({...sample,usage:{
  input_tokens:320,output_tokens:385}})===null,
  "Exceeded 384-token cap");
 eq(verifiedProviderResponse({...sample,model:"gpt-5.6-luna"})===null,
  "Nonapproved model accepted");
 eq(verifiedProviderResponse({...sample,output:[{
  type:"message",role:"assistant",content:[{
   type:"output_text",text:"Вопрос №6 неверен из-за деления на ноль."}]
 }]})===null,"Unverified per-question claim accepted");
});
