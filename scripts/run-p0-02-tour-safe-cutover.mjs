import fs from 'node:fs';
import { pathToFileURL } from 'node:url';

const sourcePath = 'scripts/p0-02-tour-safe-cutover.mjs';
const runtimePath = 'scripts/.p0-02-tour-safe-cutover-runtime.mjs';
let source = fs.readFileSync(sourcePath, 'utf8');

function replaceLiteralOnce(from, to, label) {
  const count = source.split(from).length - 1;
  if (count !== 1) throw new Error(`${label}: expected exactly 1 literal, found ${count}`);
  source = source.replace(from, to);
}

replaceLiteralOnce("'  // duration/score summary (used for local + DB)'", "'// duration/score summary (used for local + DB)'", 'duration marker');
replaceLiteralOnce("'  // Save attempt locally (for stats/trend). Does not affect future DB integration.'", "'// Save attempt locally (for stats/trend). Does not affect future DB integration.'", 'save marker');
replaceLiteralOnce("'       // DB finalize (only active tours)'", "'// DB finalize (only active tours)'", 'finalize marker');
replaceLiteralOnce("'  } catch {}\\n\\n  // result meta'", "'} catch {}\\n\\n  // result meta'", 'result marker');

fs.writeFileSync(runtimePath, source);
try {
  await import(pathToFileURL(process.cwd() + '/' + runtimePath).href + `?v=${Date.now()}`);
} finally {
  try { fs.unlinkSync(runtimePath); } catch {}
}
