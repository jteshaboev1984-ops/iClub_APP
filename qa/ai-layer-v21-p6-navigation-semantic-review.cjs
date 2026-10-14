"use strict";
// §73 isolated editorial/accessible-name inspection.
// Never publishes, approves, translates or changes the existing app.
const LOCALES=Object.freeze(["ru","uz","en"]);
const VIEWS=Object.freeze(["home","courses","ratings","profile","about","support"]);
const TAB_KEYS=Object.freeze({
 home:"tab_home",courses:"tab_study",ratings:"tab_ratings",profile:"tab_profile"
});
const fail=reason=>({status:"NO_GO",reviewOnly:true,copyIntegrity:false,reason});
function label(i18n,locale,key){
 const start=i18n.indexOf(locale+": {");
 const next=locale==="ru"?"uz: {":locale==="uz"?"en: {":null;
 const end=next?i18n.indexOf(next,start+1):i18n.length;
 if(start<0||end<=start||!/^[a-z][a-z0-9_]*$/.test(key))return null;
 const found=new RegExp("(?:^|\\n)\\s*"+key+":\\s*\"([^\"\\n]+)\"").exec(i18n.slice(start,end));
 return found?found[1]:null;
}
function quoted(text,locale){
 return locale==="en"?"“"+text+"”":"«"+text+"»";
}
function checkNavigationEditorial({draft,inventory,html,app,i18n}={}){
 if(!draft||draft.status!=="EDITORIAL_DRAFT_NOT_APPROVED"||
  draft.releaseAllowed!==false||draft.localePolicy!=="all_three_required_no_auto_translation"||
  !draft.editorialControls||draft.editorialControls.approvedBy!==null||
  draft.editorialControls.approvedAt!==null||
  ["contentCorrectnessVerified","languageReviewVerified","accessibilityVerified",
   "releaseApproved","rightsApproved"].some(k=>draft.editorialControls[k]!==false))
   return fail("draft_must_remain_unapproved");
 if(!inventory||inventory.releaseAllowed!==false||
  !Array.isArray(draft.entrypoints)||draft.entrypoints.length!==6||
  !Array.isArray(inventory.views)||inventory.views.length!==6||
  !VIEWS.every((view,i)=>draft.entrypoints[i].targetView===view))
   return fail("route_inventory_invalid");
 if(typeof html!=="string"||typeof app!=="string"||typeof i18n!=="string")
   return fail("missing_current_sources");
 const discrepancies=[];
 let checked=0;
 const seen=new Set();
 for(const item of draft.entrypoints){
  const view=item.targetView,found=inventory.views.find(x=>x.view===view);
  if(!found||seen.has(view)||item.id!=="nav_"+view||
   !item.replies||Object.keys(item.replies).sort().join(",")!=="en,ru,uz")
   return fail("route_or_locale_drift");
  seen.add(view);
  let targetKey=item.labelKey;
  if(TAB_KEYS[view]){
   if(item.kind!=="tab"||item.entryView!==null||targetKey!==TAB_KEYS[view]||
    item.selector!=='[data-tab="'+view+'"]')return fail("tab_contract_drift");
   const match=new RegExp('<button\\b([^>]*\\bdata-tab="'+view+'"[^>]*)>([\\s\\S]*?)<\\/button>').exec(html);
   if(!match||!match[2].includes('data-i18n="'+targetKey+'"'))
    return fail("visible_tab_binding_changed");
   const aria=/\baria-label="([^"]+)"/.exec(match[1]);
   // Two forms are reviewed: CURRENT app has a literal aria-label; a detached
   // preview may rely on the exact translated visible child. Neither grants
   // release permission. A native Chromium AX-tree test is still mandatory.
   if(!aria&&(!match[2].includes('class="tab-ico" aria-hidden="true"')||
    !match[2].includes('class="tab-txt"')))
    return fail("missing_native_tab_name_source");
   for(const locale of LOCALES){
    const shown=label(i18n,locale,targetKey);
    if(!shown)return fail("missing_i18n_caption");
    if(aria&&aria[1]!==shown)
     discrepancies.push({view,locale,visibleLabel:shown,accessibleName:aria[1]});
   }
  }else{
   const entry=view==="about"?"home":"profile";
   const action=view==="about"?"open-about":"open-support";
   const expectedKey=view==="about"?"profile_settings_about":"profile_support_title";
   if(item.kind!=="global"||item.entryView!==entry||
    targetKey!==expectedKey||item.selector!=='[data-action="'+action+'"]'||
    !html.includes('data-action="'+action+'"')||
    !app.includes('action === "'+action+'"'))
    return fail("global_route_contract_drift");
  }
  for(const locale of LOCALES){
   const copy=item.replies[locale];
   const target=label(i18n,locale,targetKey);
   if(typeof copy!=="string"||!target||copy.length<12||copy.length>180||
    copy!==copy.trim()||!copy.endsWith(".")||
    /[\r\n\t<>]|(?:api[_ -]?key|mastery|exam[_ -]?score|source[_ -]?hash)/i.test(copy)||
    !copy.includes(quoted(target,locale)))
    return fail("learner_copy_or_target_label_drift");
   if(item.entryView){
    const entryLabel=label(i18n,locale,TAB_KEYS[item.entryView]);
    if(!entryLabel||!copy.includes(quoted(entryLabel,locale)))
     return fail("parent_route_label_drift");
   }
   checked++;
  }
 }
 const navTag=/<nav\b[^>]*\bid="tabbar"[^>]*>/.exec(html);
 const navAria=navTag&&/\baria-label="([^"]+)"/.exec(navTag[0]);
 return Object.freeze({
  status:"NO_GO",reviewOnly:true,copyIntegrity:true,
  checkedRoutes:seen.size,checkedReplies:checked,locales:[...LOCALES],
  accessibilityIssueCount:discrepancies.length,
  accessibilityIssues:discrepancies,
  tabbarAccessibleName:navAria?navAria[1]:null,
  independentLanguageAndAccessibilityReview:"REQUIRED",
  contentApproval:false,rightsApproval:false,sourcePublication:false,
  betaPermission:false,homePlannerApproval:false
 });
}
module.exports={checkNavigationEditorial};
