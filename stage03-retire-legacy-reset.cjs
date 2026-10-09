'use strict';
// Preview-only retirement of an obsolete local progress reset.
// The final production source change must retire it as well.
const fs=require('node:fs'),path=require('node:path');
const source=path.join(__dirname,'dist','security','practice-v2-local-reset.js');
const htmlFile=path.join(__dirname,'dist','index.html');
const previous=fs.readFileSync(source,'utf8');
const html=fs.readFileSync(htmlFile,'utf8');
if(!previous.includes('iclub_math_practice_v2_local_reset_20261007_v1') ||
   !previous.includes('storage.removeItem(DRAFT_KEY)') ||
   !previous.includes('globalThis.iclubMathPracticeV2ResetAfterPublish = (client) => {'))
  throw Error('Unexpected Practice v2 reset source; refusing patch');
const currentPin='security/practice-v2-local-reset.js?v=mathv2postpublish1';
if(html.split(currentPin).length!==2)
  throw Error('Unexpected Practice v2 reset pin');
const safe=[
  '(() => {',
  '  "use strict";',
  '  // Preserve existing Mathematics Practice progress after v2 publication.',
  '  globalThis.iclubMathPracticeV2ResetAfterPublish = async () => false;',
  '})();',''
].join('\n');
new Function(safe);
if(/\b(localStorage|sessionStorage|removeItem|setItem|clear)\b/.test(safe))
  throw Error('Retired reset must not read or write browser state');
fs.writeFileSync(source,safe,'utf8');
fs.writeFileSync(htmlFile,html.replace(currentPin,
  'security/practice-v2-local-reset.js?v=stage03retired1'),'utf8');
console.log('STAGE03_MATH_RESET_RETIRED storage_access=0 deletion=0');
