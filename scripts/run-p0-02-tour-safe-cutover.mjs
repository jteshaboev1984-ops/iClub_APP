import fs from 'node:fs';
import { pathToFileURL } from 'node:url';

const sourcePath = 'scripts/p0-02-tour-safe-cutover.mjs';
const runtimePath = 'scripts/.p0-02-tour-safe-cutover-runtime.mjs';
let source = fs.readFileSync(sourcePath, 'utf8');

function replaceLiteral(from, to, label, expectedCount = 1) {
  const count = source.split(from).length - 1;
  if (count !== expectedCount) {
    throw new Error(`${label}: expected exactly ${expectedCount} literal(s), found ${count}`);
  }
  source = source.split(from).join(to);
}

replaceLiteral("'  // duration/score summary (used for local + DB)'", "'// duration/score summary (used for local + DB)'", 'duration marker');
replaceLiteral("'  // Save attempt locally (for stats/trend). Does not affect future DB integration.'", "'// Save attempt locally (for stats/trend). Does not affect future DB integration.'", 'save marker', 2);
replaceLiteral("'       // DB finalize (only active tours)'", "'// DB finalize (only active tours)'", 'finalize marker');
replaceLiteral("'  } catch {}\\n\\n  // result meta'", "'} catch {}\\n\\n  // result meta'", 'result marker');

fs.writeFileSync(runtimePath, source);
try {
  await import(pathToFileURL(process.cwd() + '/' + runtimePath).href + `?v=${Date.now()}`);
} finally {
  try { fs.unlinkSync(runtimePath); } catch {}
}
