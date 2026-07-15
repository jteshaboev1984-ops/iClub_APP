'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const read = name => fs.readFileSync(path.join(root, name), 'utf8');

const loader = read('diagnostic-demo-chat-focus.js');
const css = read('diagnostic-demo-stitch-premium.css');
const core = read('diagnostic-demo-stitch-premium-core.js');
const result = read('diagnostic-demo-stitch-result.js');
const icon = read('iclub-ai-tutor-premium.svg');

assert(loader.includes('diagnostic-demo-stitch-premium.css'), 'premium CSS must be loaded');
assert(loader.includes('diagnostic-demo-stitch-result.js'), 'premium result decorator must be loaded');
assert(loader.includes('diagnostic-demo-stitch-premium-core.js'), 'premium core decorator must be loaded');

assert(css.includes('grid-template-columns:repeat(2,minmax(0,1fr))'), 'AI actions must use a two-column grid');
assert(css.includes('@media(max-width:390px)'), '390 px breakpoint is required');
assert(css.includes('@media(max-width:360px)'), '360 px breakpoint is required');
assert(css.includes('padding-bottom:calc(128px + var(--safe-bottom))'), 'chat must reserve space for the fixed composer');
assert(css.includes('.demo-student-context'), 'premium layer must preserve hidden learner identity contract');

assert(!core.includes('Сардор Каримов'), 'learner name must not appear in premium UI code');
assert(!core.includes('Sardor Karimov'), 'learner name must not appear in premium UI code');
assert(!result.includes('Сардор Каримов'), 'learner name must not appear in result UI');
assert(!core.includes('innerHTML'), 'premium renderer must not use innerHTML');
assert(!result.includes('innerHTML'), 'result renderer must not use innerHTML');
assert(core.includes('premium_audit'), 'runtime premium audit must be recorded');

assert(icon.includes('Открытая учебная книга'), 'premium icon must be an academic open-book mark');
assert(!icon.toLowerCase().includes('chat'), 'premium icon must not be a chat-bubble identity');

console.log('Stitch premium static checks passed');
