// QA Preview-only render adaptation. The real global-ai-ui.js stays unchanged.
"use strict";
function patchSyntheticGlobalShell(original){
 if(typeof original!=="string")throw Error("synthetic_shell_missing");
 const anchor="  function quickPrompts(ctx) {\n    const c = copy();";
 if(original.split(anchor).length!==2||
  original.includes("QA_SYNTHETIC_REVIEW_PROMPTS"))
  throw Error("synthetic_shell_source_drift");
 const injection=[
  '    // QA_SYNTHETIC_REVIEW_PROMPTS: never imported into real app.',
  '    if(window.__ICLUB_AI_V21_SYNTHETIC_ONLY__===true &&',
  '       activeViewName()==="courses" &&',
  '       document.querySelector(\'#courses-practice-review.is-active [data-iclub-ai-v21-selected="true"]\')){',
  '      return [{key:"topic_main",label:c.topicMain},',
  '       {key:"topic_simple",label:c.topicSimple}];',
  '    }'
 ].join("\n");
 return original.replace(anchor,anchor+"\n"+injection);
}
module.exports={patchSyntheticGlobalShell};
