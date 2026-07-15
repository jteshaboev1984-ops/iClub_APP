(()=>{'use strict';
const $=id=>document.getElementById(id);
let timer=null;
function refresh(delay=35){clearTimeout(timer);timer=setTimeout(()=>window.ICLUB_DEMO_PREMIUM_FIXES?.decorate?.(),delay)}
const start=$('courses-practice-start');
if(start)new MutationObserver(refresh).observe(start,{attributes:true,attributeFilter:['hidden','class']});
const result=$('courses-practice-result');
if(result)new MutationObserver(refresh).observe(result,{attributes:true,attributeFilter:['hidden','class']});
document.addEventListener('click',event=>{
 if(event.target.closest('[data-hub-tab="practice"],#topbar-back,#practice-to-subject-btn,#practice-review-back-btn,#practice-recs-back-btn'))refresh(70);
});
window.addEventListener('pageshow',()=>refresh(80));
refresh(120);
})();