"use strict";
const {test}=require("node:test"),assert=require("node:assert/strict"),fs=require("node:fs"),path=require("node:path");
const root=path.resolve(__dirname,"..");
const read=p=>fs.readFileSync(path.join(root,p),"utf8");
const actual=read("index.html");
const html=read("qa/ai-layer-v21-app-look-preview/index.html");
const js=read("qa/ai-layer-v21-app-look-preview/review.js");
const css=read("qa/ai-layer-v21-app-look-preview/review.css");
const part=(s,a,b)=>{const x=s.indexOf(a),y=s.indexOf(b,x);assert.ok(x>=0&&y>x,"missing canonical element "+a);return s.slice(x,y+b.length)};
test("Visual candidate copies actual topbar/nav structural markup rather than inventing a new app shell",()=>{
 const extract=s=>part(s,'<header id="topbar"','</header>')
  .replace('style="display:none"','').replace('aria-label="Top bar"','aria-label="iClub"');
 assert.equal(extract(html),extract(actual));
 assert.equal(part(html,'<nav id="tabbar"','</nav>'),
  part(actual,'<nav id="tabbar"','</nav>'));
 assert.match(html,/body class="iclub-visual-v3"/);
 assert.match(html,/id="view-home"/);
 assert.match(html,/id="view-courses"/);
 assert.match(html,/id="view-ratings"/);
 assert.match(html,/id="view-profile"/);
 assert.doesNotMatch(html,/class="bottom-nav"/);
});
test("Visual candidate uses actual production CSS by root path and loads the real iClub logo",()=>{
 for(const link of ["/style.css","/visual/iclub-visual-v3.css",
  "/visual/iclub-premium-v3.css","/global-ai-ui.css","/logo.png"])
  assert.ok(html.includes(link),link);
 assert.match(read("style.css"),/--primary:\s*#2F6FD6/);
 assert.match(html,/class="iclub-global-ai-panel"/);
 assert.match(html,/class="iclub-global-ai-mark"/);
 assert.doesNotMatch(html,/supabase-js|telegram-web-app|app\.js|i18n\.js/);
});
test("Visual review cannot connect to networks, store user progress, deploy or call a provider",()=>{
 assert.match(html,/connect-src 'none'/);
 assert.match(html,/noindex,nofollow,noarchive/);
 for(const source of [html,js,css]){
  for(const pattern of [/https?:\/\//,/localStorage/,/sessionStorage/,/indexedDB/,/fetch\(/,
  /XMLHttpRequest/,/WebSocket\(/,/navigator\.sendBeacon/,/createClient\(/,
  /service_role/,/window\.open\(/])
   assert.doesNotMatch(source,pattern,String(pattern));
 }
 assert.match(js,/network:false,storage:false/);
 assert.match(js,/stage==="quiz"/);
 assert.match(js,/AI недоступен|AI mavjud emas|AI is unavailable/);
});
test("RU UZ EN approved bottom navigation and accessible landmark names are preserved",()=>{
 for(const t of ["Нижнее меню","Pastki menyu","Bottom navigation"])
  assert.ok(js.includes(t),t);
 for(const k of ["home","courses","ratings","profile"])
  assert.match(html,new RegExp('data-tab="'+k+'"'));
 assert.match(js,/ru:\{/);assert.match(js,/uz:\{/);assert.match(js,/en:\{/);
});
