import { pathToFileURL } from 'node:url';

await import(
  pathToFileURL(process.cwd() + '/scripts/p0-02-tour-safe-cutover.mjs').href + `?v=${Date.now()}`
);
