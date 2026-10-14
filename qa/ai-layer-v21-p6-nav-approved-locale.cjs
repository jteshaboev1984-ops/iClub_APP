"use strict";
// §79 approved product copy for bottom navigation, only in detached QA/Preview.
// Original app HTML/translator remain untouched; this helper has NO UI import.
const decisions=require("./ai-layer-v21-owner-product-decisions-20261014.json");
const {makeAccessibleNavPreview}=require("./ai-layer-v21-p6-nav-a11y-preview.cjs");
const allowed=Object.freeze(["ru","uz","en"]);
function approvedLabel(locale){
 if(!allowed.includes(locale)||decisions.accessibility?.productApproved!==true||
  decisions.scope!=="QA_AND_PROTECTED_PREVIEW_PREPARATION_ONLY"||
  decisions.release?.productionDeployApproved!==false)
  throw Error("qa_only_or_invalid_locale");
 const v=decisions.accessibility.landmarkLabels?.[locale];
 if(typeof v!=="string"||!v||/[<>"&]/.test(v))throw Error("invalid_landmark");
 return v;
}
function makeApprovedAccessibleNavPreview(source,locale){
 const label=approvedLabel(locale);
 const original=makeAccessibleNavPreview(source);
 const marker='id="tabbar" class="tabbar" aria-label="Bottom navigation"';
 if(original.html.split(marker).length!==2)throw Error("nav_landmark_source_changed");
 const out=original.html.replace(marker,
  'id="tabbar" class="tabbar" aria-label="'+label+'"');
 return Object.freeze({html:out,locale,landmark:label,modifiedButtons:4,
  liveAppChanged:false,releaseAllowed:false});
}
// Called by an eventual *authorized* Preview language-change hook, NOT by the
// shipping app. Existing per-button accessible names follow translated text.
function syncApprovedNavLandmark(document,locale){
 const label=approvedLabel(locale);
 const nav=document?.getElementById?.("tabbar");
 if(!nav||!nav.querySelectorAll)throw Error("missing_nav");
 const buttons=[...nav.querySelectorAll("button[data-tab]")];
 if(buttons.length!==4||buttons.some(x=>x.hasAttribute("aria-label")||
  !x.querySelector(".tab-txt[data-i18n]")||
  x.querySelector(".tab-ico")?.getAttribute("aria-hidden")!=="true"))
  throw Error("nav_source_reaudit_required");
 nav.setAttribute("aria-label",label);
 return Object.freeze({ok:true,locale,reviewOnly:true,releaseAllowed:false});
}
module.exports={approvedLabel,makeApprovedAccessibleNavPreview,syncApprovedNavLandmark};
