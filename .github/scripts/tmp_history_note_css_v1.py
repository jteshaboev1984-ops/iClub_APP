from pathlib import Path

css_path = Path('exam-prep/exam-prep-host.css')
css = css_path.read_text(encoding='utf-8').rstrip()
marker = '/* P1-05 previous-practice note — external presentation */'
if marker not in css:
    css += '''

/* P1-05 previous-practice note — external presentation */
#exam-prep-host-root .ep-history-note {
  display: grid;
  gap: 4px;
  padding: 9px 10px;
  border: 1px solid rgba(127, 127, 127, .12);
  border-radius: 10px;
  background: rgba(127, 127, 127, .055);
}

#exam-prep-host-root .ep-history-note strong {
  font-size: 11px;
  line-height: 1.3;
}

#exam-prep-host-root .ep-history-note span {
  min-width: 0;
  font-size: 11px;
  line-height: 1.45;
  opacity: .74;
  overflow-wrap: break-word;
}
'''
css_path.write_text(css.rstrip() + '\n', encoding='utf-8')

test_path = Path('.github/scripts/p1_05_history_note_regression.js')
test = test_path.read_text(encoding='utf-8')
style_anchor = "  await page.goto('http://iclub.test/');\n"
style_line = "  await page.addStyleTag({ path: path.resolve('exam-prep/exam-prep-host.css') });\n"
if style_line not in test:
    if test.count(style_anchor) != 1:
        raise SystemExit('page goto anchor mismatch')
    test = test.replace(style_anchor, style_anchor + style_line, 1)

assertion_anchor = "  assert(p1Text.includes('does not change confirmed progress or exam readiness'), 'P1 history note must explicitly remain non-crediting');\n"
assertion_block = '''  assert(await page.locator('#ep-history-note-style').count() === 0, 'history note must not inject a runtime style element');
  const p1Style = await page.locator('[data-ep-history-note="P1"]').evaluate(el => {
    const s = getComputedStyle(el);
    return { display: s.display, radius: s.borderRadius, overflowWrap: s.overflowWrap };
  });
  assert(p1Style.display === 'grid', 'history note external stylesheet must be applied');
  assert(p1Style.radius === '10px', 'history note external stylesheet must preserve geometry');
  assert(['break-word', 'anywhere'].includes(p1Style.overflowWrap), 'history note must remain language-safe');
'''
if 'history note must not inject a runtime style element' not in test:
    if test.count(assertion_anchor) != 1:
        raise SystemExit('assertion anchor mismatch')
    test = test.replace(assertion_anchor, assertion_anchor + assertion_block, 1)
test_path.write_text(test, encoding='utf-8')
