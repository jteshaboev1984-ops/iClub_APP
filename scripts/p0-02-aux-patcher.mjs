export function assert(ok, msg) {
  if (!ok) throw new Error(msg);
}

function scanMatchingDelimiter(src, open, openChar, closeChar) {
  assert(src[open] === openChar, `${openChar} expected at ${open}`);
  let depth = 0, mode = 'code', quote = '', escaped = false, tpl = 0;
  for (let i = open; i < src.length; i++) {
    const ch = src[i], nx = src[i + 1] || '';
    if (mode === 'line') { if (ch === '\n') mode = 'code'; continue; }
    if (mode === 'block') { if (ch === '*' && nx === '/') { mode = 'code'; i++; } continue; }
    if (mode === 'string') {
      if (escaped) { escaped = false; continue; }
      if (ch === '\\') { escaped = true; continue; }
      if (ch === quote) { mode = 'code'; quote = ''; }
      continue;
    }
    if (mode === 'template') {
      if (escaped) { escaped = false; continue; }
      if (ch === '\\') { escaped = true; continue; }
      if (ch === '`' && tpl === 0) { mode = 'code'; continue; }
      if (ch === '$' && nx === '{') { tpl++; i++; continue; }
      if (tpl > 0) { if (ch === '{') tpl++; else if (ch === '}') tpl--; }
      continue;
    }
    if (ch === '/' && nx === '/') { mode = 'line'; i++; continue; }
    if (ch === '/' && nx === '*') { mode = 'block'; i++; continue; }
    if (ch === '"' || ch === "'") { mode = 'string'; quote = ch; continue; }
    if (ch === '`') { mode = 'template'; tpl = 0; continue; }
    if (ch === openChar) depth++;
    else if (ch === closeChar) {
      depth--;
      if (depth === 0) return i;
    }
  }
  throw new Error(`unmatched ${openChar} at ${open}`);
}

export function matchingBrace(src, open) {
  return scanMatchingDelimiter(src, open, '{', '}');
}

export function matchingParen(src, open) {
  return scanMatchingDelimiter(src, open, '(', ')');
}

export function range(source, name) {
  const re = new RegExp(`\\b(?:async\\s+)?function\\s+${name}\\s*\\(`, 'g');
  const hits = Array.from(source.matchAll(re));
  assert(hits.length === 1, `${name}: expected one declaration, got ${hits.length}`);
  const start = hits[0].index;
  const paramsOpen = source.indexOf('(', start);
  assert(paramsOpen >= 0, `${name}: parameter list not found`);
  const paramsClose = matchingParen(source, paramsOpen);
  const open = source.indexOf('{', paramsClose + 1);
  assert(open >= 0, `${name}: opening brace not found`);
  const end = matchingBrace(source, open) + 1;
  return { start, end, text: source.slice(start, end) };
}

export function replaceNamed(source, name, code) {
  const r = range(source, name);
  return source.slice(0, r.start) + code.trim() + source.slice(r.end);
}
