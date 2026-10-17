// Live *operator-only* QA public iClub help. Never reads learner rows,
// grades, points, progress, Practice or Tour answers.
// Source and allowed questions are first-party, versioned and pinned here.
export const PROVIDER_MODEL = "gpt-5.6-luna";
export const MAX_OUTPUT_TOKENS = 220;
export const MAX_INPUT_BYTES = 6000;
export const HOLD_MICROUSD = 10000;
export const ALLOWED_SCREENS = new Set([
 "home","all-subjects","subject-hub","ratings","profile",
 "support","support-topic","about","books","certificates",
 "notifications","community","my-recs","video","tours",
 "tour-rules","practice-start"
]);
const STOP_SCREENS = new Set([
 "practice-quiz","tour-quiz","exam-prep","practice-review",
 "practice-result","tour-review","tour-result"
]);
export const APPROVED_SOURCE = [
 "iClub is a learning app. Bottom navigation contains Home, Study, Leaderboard, Profile.",
 "The Study section provides a subject catalogue and subject pages.",
 "The app has Practice, Tours, books, video lessons and recommendations.",
 "The Leaderboard section shows rankings. Do not infer the signed-in user's rank.",
 "The Profile contains access to Support, achievements and user information.",
 "For help, open Profile, then Support, select a topic and follow the instructions.",
 "During active Practice and Tours the Global AI assistant is not available.",
 "An AI answer never changes scores, finished attempts, certificates or progress.",
 "Do not invent personal scores, unavailable source material, URLs or Tour answers."
].join(" ");
const NORMALIZE=(s:string)=>
 s.normalize("NFKC").toLocaleLowerCase().replace(/[’ʻ']/g,"‘")
 .replace(/\s+/g," ").trim().replace(/[?!.\u061f]+$/g,"").trim();
const FAQ: Record<string,Record<string,string[]>>={
 ru:{
  support_help:["как обратиться в поддержку","как получить помощь в iclub"],
  home_next:["что делать дальше","с чего начать в iclub"],
  catalog_help:["как начать обучение","где найти предметы"],
  ratings_help:["как работает рейтинг","как считается рейтинг"],
  practice_rules:["как работает practice","что такое practice"],
  tour_rules:["как работают туры","как работают tours"],
  books_help:["как пользоваться книгами","где книги"],
  about_help:["что такое iclub","расскажи об iclub"]
 },
 uz:{
  support_help:["qanday yordam so‘rayman","yordamga qanday murojaat qilaman"],
  home_next:["keyingi qadam nima","qayerdan boshlayman"],
  catalog_help:["o‘qishni qanday boshlayman","fanlarni qayerdan topaman"],
  ratings_help:["reyting qanday ishlaydi","reyting qanday hisoblanadi"],
  practice_rules:["practice qanday ishlaydi"],
  tour_rules:["tours qanday ishlaydi","turlar qanday ishlaydi"],
  books_help:["kitoblardan qanday foydalanaman","kitoblar qayerda"],
  about_help:["iclub nima","iclub haqida aytib ber"]
 },
 en:{
  support_help:["how do i contact support","how can i get support"],
  home_next:["what should i do next","where do i start"],
  catalog_help:["how do i start learning","where can i find subjects"],
  ratings_help:["how do leaderboards work","how is the leaderboard calculated"],
  practice_rules:["how does practice work","what is practice"],
  tour_rules:["how do tours work"],
  books_help:["how do i use books","where are the books"],
  about_help:["what is iclub","tell me about iclub"]
 }
};
const QUESTIONS:Record<string,Record<string,string>>={
 ru:{
  support_help:"Как обратиться в поддержку iClub?",
  home_next:"Как начать пользоваться учебными функциями iClub?",
  catalog_help:"Где находится каталог предметов iClub?",
  ratings_help:"Как пользоваться разделом Рейтинг?",
  practice_rules:"Что такое Practice и где его искать?",
  tour_rules:"Что такое Tours и где смотреть информацию о турах?",
  books_help:"Где найти книги в iClub?",
  about_help:"Какие основные возможности предоставляет iClub?"
 },
 uz:{
  support_help:"iClub yordam bo‘limini qanday topaman?",
  home_next:"iClub'da o‘qishni qayerdan boshlayman?",
  catalog_help:"iClub'da fanlarni qayerdan topaman?",
  ratings_help:"iClub reyting bo‘limidan qanday foydalanaman?",
  practice_rules:"Practice nima va qayerda?",
  tour_rules:"Tours nima va qayerda?",
  books_help:"iClub kitoblari qayerda?",
  about_help:"iClub ilovasi qanday imkoniyatlarga ega?"
 },
 en:{
  support_help:"How do I find Support inside iClub?",
  home_next:"Where should I start learning inside iClub?",
  catalog_help:"Where is the iClub subject catalogue?",
  ratings_help:"How do I use the Leaderboard section?",
  practice_rules:"What is Practice and where can I find it?",
  tour_rules:"What is Tours and where can I find it?",
  books_help:"Where can I find books in iClub?",
  about_help:"What is iClub and which app sections does it have?"
 }
};
export type AllowedHelp={key:string;question:string;locale:string;screen:string};
export function classify(body:unknown):AllowedHelp|null{
 if(!body||typeof body!=="object"||Array.isArray(body))return null;
 const b=body as Record<string,unknown>;
 if(typeof b.locale!=="string"||!FAQ[b.locale]||
    typeof b.screen_code!=="string"||!ALLOWED_SCREENS.has(b.screen_code)||
    STOP_SCREENS.has(b.screen_code)||b.scope_code!=="global")return null;
 const key=typeof b.prompt_key==="string"?b.prompt_key:"";
 const text=typeof b.user_text==="string"?b.user_text:"";
 if(text.length>180||/[<>\\\n\r\u0000-\u001f]/.test(text))return null;
 if(key && !(key in QUESTIONS[b.locale]))return null;
 if(key && text && NORMALIZE(text)!==NORMALIZE(QUESTIONS[b.locale][key]) &&
    !FAQ[b.locale][key]?.includes(NORMALIZE(text))) return null;
 if(!key&&!text)return null;
 const chosen=key||Object.entries(FAQ[b.locale]).find(([,aliases])=>
    aliases.some(a=>NORMALIZE(a)===NORMALIZE(text)))?.[0];
 if(!chosen)return null;
 return {key:chosen,question:QUESTIONS[b.locale][chosen],
   locale:b.locale,screen:b.screen_code};
}
export function cost(inputTokens:unknown,outputTokens:unknown):number|null {
 if(!Number.isSafeInteger(inputTokens)||!Number.isSafeInteger(outputTokens)||
     (inputTokens as number)<0||(outputTokens as number)<0||
     (outputTokens as number)>MAX_OUTPUT_TOKENS)return null;
 const amount=Math.ceil((inputTokens as number)*0.25+(outputTokens as number)*1.2);
 return amount<=HOLD_MICROUSD?amount:null;
}
export function extract(data:unknown):string|null {
 if(!data||typeof data!=="object")return null;
 const v=data as Record<string,any>;
 if(v.status!=="completed"||v.model!==PROVIDER_MODEL||
    !Array.isArray(v.output))return null;
 const parts:string[]=[];
 for(const item of v.output){
  if(item.type!=="message"||item.role!=="assistant")continue;
  for(const p of item.content||[]){
   if(p.type!=="output_text"||typeof p.text!=="string")return null;
   parts.push(p.text);
  }
 }
 const answer=parts.join("\n").trim();
 if(!answer||answer.length>800||answer.includes("NO_APPROVED_SOURCE")||
    /<\s*script|javascript:/i.test(answer))return null;
 return answer;
}
