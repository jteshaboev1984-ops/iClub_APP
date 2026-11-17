/* UX #531 source-compatibility contract — zero DB/network/telemetry.
   Run: node qa/ux531-academy-ui-parity.cjs */
'use strict';
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict'),vm=require('node:vm');
const root=path.join(__dirname,'..');
const read=name=>fs.readFileSync(path.join(root,name),'utf8');
const html=read('index.html'),app=read('app.js'),i18n=read('i18n.js');
const css=read('visual/iclub-academy-ux531-b02b03.css');
const shell=read('visual/iclub-academy-v55-shell-b01.css');
const interactions=read('visual/iclub-academy-ux531-interactions.js');
for(const [file,code] of [['app.js',app],['i18n.js',i18n],['interactions',interactions]])
  assert.doesNotThrow(()=>new vm.Script(code,{filename:file}),file+' is syntactically invalid');
for(const id of [
  'topbar','tabbar','view-home','home-competitive-list','home-study-list','home-extra-block',
  'view-courses','courses-all-subjects','courses-filter-row','subjects-grid',
  'courses-subject-hub','subject-hub-title','subject-hub-meta','subject-hub-mentor-btn',
  'subject-hub-exam-prep-entry','subject-hub-exam-prep-placeholder','exam-prep-host-root'
]){
  const count=(html.match(new RegExp('id="'+id+'"','g'))||[]).length;
  assert.equal(count,1,'unique source id: '+id);
}
for(const action of [
 'open-subject-mentor','open-practice','open-tours','open-exam-prep','open-lessons',
 'open-books','open-my-recommendations','open-certificates','open-archive','open-all-subjects',
 'open-about','open-news','open-community'
])assert.match(html,new RegExp('data-action="'+action+'"'),'missing original route: '+action);
for(const key of ['preparation','materials','achievements']){
 assert.match(html,new RegExp('id="academy-hub-tab-'+key+'"'),'tab '+key);
 assert.match(html,new RegExp('id="academy-hub-pane-'+key+'"'),'pane '+key);
 assert.match(html,new RegExp('data-academy-pane="'+key+'"'),'pane state '+key);
}
assert.equal((html.match(/class="academy-view-zone"/g)||[]).length,2,'Home/Subjects intros');
assert.match(html,/<div class="subject-hub-head">/,'original hub heading');
assert.match(css,/--academy-header-body:156px/,'shared header height');
for(const s of ['#home-competitive-list','#home-study-list'])
 assert.match(css,new RegExp(s),'rail source selector '+s);
assert.match(css,/#home-competitive-list,[\s\S]*?#home-study-list\{[\s\S]*?display:flex!important[\s\S]*?scroll-snap-type:x mandatory/,
 'Both subject families must keep horizontal swipe');
assert(interactions.includes("{id:'home-competitive-list',child:'.home-competitive-card'}"),
 'Competitive swipe and dots preserved');
assert(interactions.includes("{id:'home-study-list',child:'.home-pinned-tile'}"),
 'Pinned Study swipe and dots preserved');
assert.match(css,/linear-gradient\(137deg,#174aab 0%,#3071e1 100%\)/,
 'Same deep-blue background applies to every Competitive card');
assert.match(css,/linear-gradient\(137deg,#5689d2 0%,#6196dd 55%,#74a2e1 100%\)/,
 'Lighter blue applies only to pinned Study');
assert.match(interactions,/MutationObserver/,'live render support required');
assert.match(interactions,/aria-selected/,'accessible hub tab state');
assert.doesNotMatch(interactions.replace(/\/\*[\s\S]*?\*\//g,''),/\.from\(|localStorage\.|\.rpc\(|supabase|startPractice|reset_subject_progress/i,'visual script must not touch user data');
assert.match(app,/pinned\.forEach\(\(s, idx\) => \{/,'all pinned subjects must be shown');
assert.doesNotMatch(app,/pinned\.slice\(0, 4\)/,'no silent four-item cap');
for(const t of ['home','courses','ratings','profile'])
 assert.match(html,new RegExp('data-tab="'+t+'"'),'original tab '+t);
assert.match(html,/id="courses-filter-row"/,'existing mode switch');
assert.match(app,/if \(compNow >= 2\)/,'Competitive 2-subject cap preserved');
assert.match(app,/reset_subject_progress/,'original confirmation/reset pathway present');
assert.match(app,/window\.iClubCommercialAccessUI\?\.guardLegacyToggle/,'commercial guard present');
assert.match(app,/window\.iClubPracticeDraftIdentityV1/,'practice owner guard present');
for(const key of ['tab_study','courses_title','academy_home_subtitle','academy_subjects_subtitle','academy_hub_prepare','academy_hub_materials','academy_hub_achievements'])
 assert.equal((i18n.match(new RegExp('\\b'+key+':','g'))||[]).length,3,'trilingual key '+key);
assert.match(i18n,/tab_study: "Предметы"/);
assert.match(i18n,/tab_study: "Fanlar"/);
assert.match(i18n,/tab_study: "Subjects"/);
assert.match(shell,/#view-ratings\.is-active/);
assert.match(shell,/#view-profile\.is-active/);
console.log('PASS: UX531 B01–B03 source parity, three languages, both swipe rails with uniform Competitive and lighter pinned Study palette.');
console.log('NOTE: not a browser, auth, JWT/PostgREST, production or release test.');
