// QA-only exact typed app-help matching, NOT an LLM, source publication,
// production entitlement, free semantic classifier, or billing shortcut.
// A typed question must match a public-iClub navigation question EXACTLY;
// substring/fuzzy matching could leak into academic or personal assistance.
(function(root){
 "use strict";
 const LOCALES=["ru","uz","en"];
 const ACCESSIBLE=new Set([
   "support_help","ratings_help","practice_rules","tour_rules",
   "catalog_help","about_help","certificates_help","books_help",
   "notifications_help","community_help","recs_help",
   "archive_help","video_help","home_next","subject_study"
 ]);
 const mapping={
  ru:{
   support_help:["как обратиться в поддержку","как получить помощь в iclub"],
   ratings_help:["как работает рейтинг","как считается рейтинг"],
   practice_rules:["как работает practice","что такое practice"],
   tour_rules:["как работают туры","как работают tours"],
   catalog_help:["как начать обучение","где найти предметы"],
   about_help:["что такое iclub","расскажи об iclub"],
   certificates_help:["как получить сертификат","где посмотреть сертификаты"],
   books_help:["как пользоваться книгами","где книги"],
   notifications_help:["как работают уведомления","где уведомления"],
   community_help:["как пользоваться сообществом","где сообщество"],
   recs_help:["как работают рекомендации","где мои рекомендации"],
   archive_help:["когда доступен архив","когда откроется архив"],
   video_help:["как открыть видеоуроки","где видеоуроки"],
   home_next:["что делать дальше","с чего начать в iclub"],
   subject_study:["как изучать предмет"]
  },
  uz:{
   support_help:["qanday yordam so‘rayman","yordamga qanday murojaat qilaman"],
   ratings_help:["reyting qanday ishlaydi","reyting qanday hisoblanadi"],
   practice_rules:["practice qanday ishlaydi"],
   tour_rules:["tours qanday ishlaydi","turlar qanday ishlaydi"],
   catalog_help:["o‘qishni qanday boshlayman","fanlarni qayerdan topaman"],
   about_help:["iclub nima","iclub haqida aytib ber"],
   certificates_help:["sertifikatni qanday olaman","sertifikatlar qayerda"],
   books_help:["kitoblardan qanday foydalanaman","kitoblar qayerda"],
   notifications_help:["bildirishnomalar qanday ishlaydi"],
   community_help:["hamjamiyatdan qanday foydalanaman"],
   recs_help:["tavsiyalar qanday ishlaydi","tavsiyalarim qayerda"],
   archive_help:["arxiv qachon ochiladi","arxiv qachon mavjud"],
   video_help:["video darslarni qanday ochaman","video darslar qayerda"],
   home_next:["keyingi qadam nima","qayerdan boshlayman"],
   subject_study:["fanni qanday o‘rganaman"]
  },
  en:{
   support_help:["how do i contact support","how can i get support"],
   ratings_help:["how do leaderboards work","how is the leaderboard calculated"],
   practice_rules:["how does practice work","what is practice"],
   tour_rules:["how do tours work"],
   catalog_help:["how do i start learning","where can i find subjects"],
   about_help:["what is iclub","tell me about iclub"],
   certificates_help:["how do i earn certificates","where are my certificates"],
   books_help:["how do i use books","where are the books"],
   notifications_help:["how do notifications work"],
   community_help:["how do i use community"],
   recs_help:["how do recommendations work","where are my recommendations"],
   archive_help:["when does the archive open"],
   video_help:["how do i open video lessons","where are video lessons"],
   home_next:["what should i do next","where do i start"],
   subject_study:["how do i study this subject"]
  }
 };
 const normalize=v=>{
  if(typeof v!=="string"||v.length<3||v.length>150||/[<>\\\r\n\u0000-\u001f]/.test(v))
   return null;
  // Harmless typography, casing, spaces and final punctuation only.
  // DO NOT strip entire phrases or match by prefix/keyword.
  const out=v.normalize("NFKC").toLocaleLowerCase()
   .replace(/['’ʻ]/g,"‘").replace(/\s+/g," ").trim()
   .replace(/[?!.\u061f]+$/g,"").trim();
  return out.length>=3?out:null;
 };
 const lookup=new Map();
 for(const lang of LOCALES){
  for(const [key,phrases] of Object.entries(mapping[lang])){
   if(!ACCESSIBLE.has(key))throw Error("Unsupported public app help");
   for(const phrase of phrases){
    const canonical=normalize(phrase);
    const id=lang+"|"+canonical;
    if(!canonical||lookup.has(id))throw Error("Ambiguous QA help alias: "+id);
    lookup.set(id,key);
   }
  }
 }
 function resolve(body){
  if(!body||typeof body!=="object"||Array.isArray(body)||
     ![null,undefined,""].includes(body.prompt_key))return null;
  if(!LOCALES.includes(body.locale))return null;
  if(!["global","",undefined].includes(body.scope_code))return null;
  if(["practice-quiz","tour-quiz","exam_prep_skill"].includes(body.screen_code))
   return null;
  const q=normalize(body.user_text);
  if(!q)return null;
  const matched=lookup.get(body.locale+"|"+q)||null;
  if(matched==="subject_study"){
    // This is navigation guidance, not mathematical or academic solving.
    // The real app must already be on a verified known subject hub.
    if(body.screen_code!=="subject-hub"||
       !["mathematics","biology","chemistry","economics","informatics"]
        .includes(body.subject_key))return null;
  }
  return matched;
 }
 const api=Object.freeze({resolve,normalize});
 if(typeof module!=="undefined"&&module.exports)module.exports=api;
 else if(root&&root.__ICLUB_AI_QA_PREVIEW__?.noProductionWrites===true)
  Object.defineProperty(root,"__ICLUB_AI_QA_TYPED_APP_HELP__",{
   configurable:false,writable:false,enumerable:false,value:api
  });
})(typeof window!=="undefined"?window:null);
