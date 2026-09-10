from pathlib import Path
import re

js_path = Path('exam-prep/exam-prep-ai-ui.js')
js = js_path.read_text()
original = js

match = re.search(
    r'\n  function ensureStyle\(\) \{.*?style\.textContent = `\n(?P<css>.*?)\n    `;\n    document\.head\.appendChild\(style\);\n  \}\n',
    js,
    flags=re.S,
)
if not match:
    raise SystemExit('AI UI style block not found exactly once')
css_payload = match.group('css')
if '.ep-ai-panel{' not in css_payload or '.ep-ai-actions{' not in css_payload or '@media(max-width:680px)' not in css_payload:
    raise SystemExit('AI UI CSS payload is incomplete')

js = js[:match.start()] + '\n' + js[match.end():]
if js.count('    ensureStyle();\n') != 1:
    raise SystemExit(f'Expected one AI ensureStyle call, found {js.count("    ensureStyle();\\n")}')
js = js.replace('    ensureStyle();\n', '', 1)
if 'ensureStyle(' in js or 'ep-ai-ui-style' in js or 'document.createElement("style")' in js:
    raise SystemExit('Runtime AI UI style injection remains')
if js == original:
    raise SystemExit('AI UI JS did not change')
js_path.write_text(js)

css_path = Path('exam-prep/exam-prep-host.css')
host_css = css_path.read_text()
marker = '/* ===== EXAM PREP CENTRALIZED AI UI v1 ===== */'
if marker in host_css:
    raise SystemExit('AI UI CSS marker already exists')
host_css += '\n\n' + marker + '\n' + css_payload.strip() + '\n'
css_path.write_text(host_css)

test_path = Path('.github/scripts/p1_04_ai_ui_regression.js')
test = test_path.read_text()
anchor = "const path = require('path');\n"
if anchor not in test:
    raise SystemExit('P1-04 import anchor missing')
if "const aiSource = fs.readFileSync('exam-prep/exam-prep-ai-ui.js', 'utf8');" in test:
    raise SystemExit('P1-04 AI centralization assertions already present')
checks = """const fs = require('fs');
const aiSource = fs.readFileSync('exam-prep/exam-prep-ai-ui.js', 'utf8');
const hostCss = fs.readFileSync('exam-prep/exam-prep-host.css', 'utf8');
if (aiSource.includes('ensureStyle(') || aiSource.includes('ep-ai-ui-style') || aiSource.includes('document.createElement(\"style\")')) throw new Error('runtime AI UI style injection returned');
if (!hostCss.includes('EXAM PREP CENTRALIZED AI UI v1') || !hostCss.includes('.ep-ai-panel{')) throw new Error('centralized AI UI CSS contract missing');

"""
test = test.replace(anchor, anchor + checks, 1)
test_path.write_text(test)
