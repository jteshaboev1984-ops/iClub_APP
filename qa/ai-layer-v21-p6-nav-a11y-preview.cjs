"use strict";
// §74 preview-only transform. Do NOT overwrite index.html/app.js/i18n.js.
// Keep the visible tab captions as the single source for the accessible name.
const TAB_MAP=Object.freeze({
 home:"tab_home",courses:"tab_study",ratings:"tab_ratings",profile:"tab_profile"
});
function makeAccessibleNavPreview(original){
 if(typeof original!=="string")throw Error("source_required");
 const navStart=original.indexOf('<nav id="tabbar"');
 const navEnd=original.indexOf("</nav>",navStart);
 if(navStart<0||navEnd<=navStart||original.indexOf('<nav id="tabbar"',navStart+1)!==-1)
  throw Error("tabbar_source_drift");
 let region=original.slice(navStart,navEnd+6);
 for(const [view,key] of Object.entries(TAB_MAP)){
  const re=new RegExp('(<button\\b[^>]*\\bdata-tab="'+view+'"[^>]*)(>\\s*<span[\\s\\S]*?data-i18n="'+key+'"[\\s\\S]*?<\\/button>)');
  const matched=region.match(re);
  if(!matched||matched.length<3||!matched[1].includes('aria-label="'))
   throw Error("nav_button_drift_"+view);
  const before=matched[1];
  const attr=/\saria-label="[^"]*"/g;
  const labels=before.match(attr);
  if(!labels||labels.length!==1)throw Error("unexpected_accessible_name_"+view);
  // Use the existing translated .tab-txt descendant and aria-hidden icon;
  // no new translations, widgets, click handlers or hidden contents.
  const adjusted=before.replace(attr,"");
  region=region.replace(matched[0],adjusted+matched[2]);
 }
 for(const view of Object.keys(TAB_MAP)){
  const start=new RegExp('<button\\b[^>]*\\bdata-tab="'+view+'"[^>]*>').exec(region);
  if(!start||/\baria-label=/.test(start[0]))throw Error("aria_override_remains");
 }
 const out=original.slice(0,navStart)+region+original.slice(navEnd+6);
 if(out.length>=original.length)throw Error("unexpected_length_change");
 return Object.freeze({html:out,modifiedButtons:4,unmodifiedOriginal:true,
  routeKeys:Object.keys(TAB_MAP),stillNeedsLandmarkReview:true,releaseAllowed:false});
}
module.exports={makeAccessibleNavPreview};
