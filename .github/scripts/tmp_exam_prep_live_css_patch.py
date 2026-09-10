from pathlib import Path
import re

js_path = Path('exam-prep/exam-prep-live.js')
js = js_path.read_text()
original = js

match = re.search(
    r'\n  function ensureStyle\(\) \{.*?style\.textContent = `\n(?P<css>.*?)\n    `;\n    document\.head\.appendChild\(style\);\n  \}\n',
    js,
    flags=re.S,
)
if not match:
    raise SystemExit('Live-flow style block not found exactly once')

css_payload = match.group('css')
if '.ep-live{' not in css_payload or '.ep-live-card{' not in css_payload or '@media(max-width:680px)' not in css_payload:
    raise SystemExit('Live-flow CSS payload is incomplete')

js = js[:match.start()] + '\n' + js[match.end():]
old_mount = '    ensureStyle(); renderLoading(); const profile = await internal.api.examProfile();'
new_mount = '    renderLoading(); const profile = await internal.api.examProfile();'
if js.count(old_mount) != 1:
    raise SystemExit(f'Expected one live ensureStyle mount call, found {js.count(old_mount)}')
js = js.replace(old_mount, new_mount, 1)
if 'ensureStyle(' in js or 'ep-live-flow-style' in js or 'document.createElement("style")' in js:
    raise SystemExit('Runtime live-flow style injection remains')
if js == original:
    raise SystemExit('Live flow JS did not change')
js_path.write_text(js)

css_path = Path('exam-prep/exam-prep-host.css')
host_css = css_path.read_text()
marker = '/* ===== EXAM PREP CENTRALIZED LIVE FLOW v1 ===== */'
if marker in host_css:
    raise SystemExit('Live-flow CSS marker already exists')
host_css += '\n\n' + marker + '\n' + css_payload.strip() + '\n'
css_path.write_text(host_css)

test_path = Path('.github/scripts/p0_17_live_diagnostic_regression.js')
test = test_path.read_text()
anchor = "const path = require('path');\n"
if anchor not in test:
    raise SystemExit('P0-17 import anchor missing')
if "const liveSource = fs.readFileSync('exam-prep/exam-prep-live.js', 'utf8');" in test:
    raise SystemExit('P0-17 centralization assertions already present')
checks = """const fs = require('fs');
const liveSource = fs.readFileSync('exam-prep/exam-prep-live.js', 'utf8');
const hostCss = fs.readFileSync('exam-prep/exam-prep-host.css', 'utf8');
if (liveSource.includes('ensureStyle(') || liveSource.includes('ep-live-flow-style') || liveSource.includes('document.createElement(\"style\")')) throw new Error('runtime live-flow style injection returned');
if (!hostCss.includes('EXAM PREP CENTRALIZED LIVE FLOW v1') || !hostCss.includes('.ep-live-card{')) throw new Error('centralized live-flow CSS contract missing');

"""
test = test.replace(anchor, anchor + checks, 1)
test_path.write_text(test)
