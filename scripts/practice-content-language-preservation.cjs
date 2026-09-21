'use strict';
// Source-derived isolated browser-handler regression. Never connects to Supabase.
const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const source = fs.readFileSync('app.js', 'utf8');
const localization = fs.readFileSync('i18n.js', 'utf8');
const start = source.indexOf('const contentLangWrap = document.getElementById("profile-settings-content-language");');
const end = source.indexOf('    // --- Pinned list ---', start);
assert.ok(start > 0 && end > start, 'Cannot isolate current content-language settings handler');
const handler = source.slice(start, end);
assert.doesNotMatch(handler, /resetProgress\s*\(|reset_practice_progress_safe_v4|localStorage\.removeItem|\.delete\s*\(/,
  'Changing question language must never delete Practice, Tours, drafts or cached evidence');
assert.match(handler, /\.update\s*\(\s*\{\s*language_code:\s*nextLang\s*\}\s*\)/,
  'Update only the content-language column, not a whole user profile');
assert.match(handler, /\.eq\s*\(\s*["']id["']\s*,\s*uid\s*\)/,
  'Language update must be scoped to authenticated user');
assert.match(handler, /if\s*\(error\s*\|\|\s*!data\s*\|\|\s*data\.language_code\s*!==\s*nextLang\)/,
  'Missing/failed database acknowledgement must prevent local language change');
assert.equal((source.match(/practiceApi\.resetProgress\s*\(/g) || []).length, 0,
  'No other UI route may invoke destructive Practice reset');
const translations = {
  ru: ['Меняет язык заданий в турах и практике. Все результаты и ответы сохраняются.',
    'Изменить язык заданий? Ваши результаты и ответы сохранятся.',
    'Язык заданий изменён. Весь прогресс сохранён.'],
  uz: ['Turlar va amaliyotdagi savollar tili o‘zgaradi. Barcha natijalar va javoblar saqlanadi.',
    'Savollar tilini o‘zgartirasizmi? Natijalar va javoblar saqlanadi.',
    'Savollar tili o‘zgartirildi. Barcha natijalar saqlandi.'],
  en: ['Changes the language of questions in Tours and Practice. All results and answers stay saved.',
    'Change the question language? Your results and answers will be preserved.',
    'Question language updated. All progress has been preserved.']
};
for (const [lang, values] of Object.entries(translations)) {
  for (const value of values) assert.ok(localization.includes(JSON.stringify(value)), `${lang} translation missing: ${value}`);
}
for (const old of [
  'Смена этого языка удалит весь прогресс', 'Смена языка туров и практики удалит весь прогресс',
  'Прогресс сброшен.', 'Bu tilni o‘zgartirish barcha progressni',
  'o‘zgartirish barcha progressni o‘chiradi.', 'Progress o‘chirildi.',
  'Changing this language will delete all progress', 'Changing the tours and practice language will delete all progress',
  'Progress has been reset.'
]) assert.ok(!localization.includes(old), `Misleading destructive-language text remains: ${old}`);

// Registration warning and cache keys must agree with non-destructive settings.
const htmlSource = fs.readFileSync('index.html','utf8');
assert.ok(htmlSource.includes('i18n.js?v=practicepreserve1'));
assert.ok(htmlSource.includes('app.js?v=support4-p0legacysaveoff1-p014host1-practicepreserve1'));
assert.ok(htmlSource.includes('Язык заданий можно изменить позже — результаты и ответы сохранятся.'));
for (const old of [
  'Важно: смена языка после регистрации сбросит прогресс.',
  'Muhim: ro‘yxatdan o‘tgandan so‘ng tilni o‘zgartirish progressni o‘chiradi.',
  'Important: changing the language after registration will reset progress.'
]) assert.ok(!localization.includes(old) && !htmlSource.includes(old), 'Obsolete data-loss registration warning');
for (const text of [
  'Язык заданий можно изменить позже — результаты и ответы сохранятся.',
  'Savollar tilini keyin ham o‘zgartirishingiz mumkin — natijalar va javoblar saqlanadi.',
  'You can change the question language later without losing results or answers.'
]) assert.ok(localization.includes(text), 'Registration translation missing: '+text);

async function exercise({next='uz',initial='ru',accept=true,uid='synthetic-user',dbError=null,missingRow=false}={}) {
  let profile = { language: initial, uiLanguage:'en', keeper:'practice-progress' };
  const local = new Map([['state','tour-history'],['practiceDraft','unsent-written-work'],['events','audit-history'],['credentials','earned-badges'],['myRecs','recommendations']]);
  const before = Array.from(local.entries());
  let resetCalls=0, dbCalls=0, confirms=0, writes=0, renders=0;
  const toasts=[];
  const button={dataset:{lang:next},classList:{toggle(){}},onclick:null};
  const result={error:dbError, data:missingRow?null:{id:uid,language_code:next}};
  const db={from(table){assert.equal(table,'users'); return {update(payload){
    dbCalls++;assert.deepEqual(JSON.parse(JSON.stringify(payload)),{language_code:next});
    return {eq(col,value){assert.equal(col,'id');assert.equal(value,uid);return {
      select(fields){assert.equal(fields,'id,language_code');return {
        async maybeSingle(){return result;}
      };}
    };}};
  }};}};
  const context={
    document:{getElementById(id){return id==='profile-settings-content-language'?{querySelectorAll(){return [button];}}:null;}},
    profile,loadProfile(){return {...profile};},
    async uiConfirm(){confirms++;return accept;},
    async getAuthUid(){return uid;},
    window:{sb:db,i18n:{getLang(){return 'en';}}},
    getPracticeSafeApi(){resetCalls++;throw Error('destructive API invoked');},
    localStorage:{removeItem(){throw Error('unexpected local deletion');}},
    saveProfile(p){writes++;profile={...p};},
    t(key){return key;},showToast(s){toasts.push(s);},trackEvent(){},clearAboutTeamResolvedCache(){},
    renderHome(){renders++;},renderProfileMain(){renders++;},renderProfileSettings(){renders++;},
    state:{tab:'profile'}
  };
  vm.runInNewContext(handler,context,{timeout:1000,filename:'content-language-handler.js'});
  assert.equal(typeof button.onclick,'function');
  await button.onclick();
  assert.deepEqual(Array.from(local.entries()),before,'Changing language erased local work');
  assert.equal(resetCalls,0);
  const success=accept && next!==initial && !!uid && !dbError && !missingRow;
  assert.equal(profile.language,success?next:initial);
  assert.equal(profile.uiLanguage,'en');
  assert.equal(profile.keeper,'practice-progress');
  assert.equal(writes,success?1:0);
  assert.equal(dbCalls,accept && next!==initial && !!uid?1:0);
  assert.equal(confirms,next===initial?0:1);
  assert.equal(renders,success?3:0);
  assert.equal(toasts.at(-1),success?'toast_lang_updated':(accept && next!==initial?'save_failed_try_again':undefined));
}
(async()=>{
  await exercise();
  await exercise({next:'en'});
  await exercise({next:'ru'});
  await exercise({accept:false});
  await exercise({uid:null});
  await exercise({dbError:new Error('synthetic failure')});
  await exercise({missingRow:true});
  console.log('GREEN 7 synthetic settings interactions: language-only server update, acknowledgement, cancellation, no auth, DB failure, missing row, no Practice/Tour/local data loss, RU/UZ/EN text.');
})().catch(error=>{console.error(error);process.exitCode=1;});
