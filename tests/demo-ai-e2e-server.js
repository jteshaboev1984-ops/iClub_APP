'use strict';

const http = require('http');
const fs = require('fs');
const path = require('path');

process.env.DEMO_AI_GENERATED_ENABLED = 'true';
process.env.OPENAI_API_KEY = 'playwright-test-key';
process.env.DEMO_AI_SESSION_SECRET = 'playwright-demo-secret';
process.env.DEMO_AI_SESSION_LIMIT = '100';
process.env.DEMO_AI_DAILY_BUDGET = '200';
process.env.DEMO_AI_TIMEOUT_MS = '4000';
process.env.VERCEL_GIT_COMMIT_SHA = process.env.GITHUB_SHA || 'local-playwright';

const nativeFetch = global.fetch;
global.fetch = async (input, init) => {
  const url = String(input?.url || input || '');
  if (url === 'https://api.openai.com/v1/responses') {
    const body = JSON.parse(String(init?.body || '{}'));
    const sourceText = body?.input?.[0]?.content?.[0]?.text || '';
    const sourceRef = sourceText.includes('[allocative_vs_productive]')
      ? 'allocative_vs_productive'
      : (sourceText.match(/^\[([^\]]+)\]/m)?.[1] || 'allocative_vs_productive');
    return new Response(JSON.stringify({
      output_text: JSON.stringify({
        short: 'A firm can minimise average cost while still charging a price above marginal cost.',
        simple: 'Minimum average cost shows productive efficiency. Allocative efficiency additionally requires P = MC.',
        example: 'A firm at minimum AC with P > MC is productively efficient but not allocatively efficient.',
        check: 'Which separate condition is required for allocative efficiency?',
        check_answer: 'Price must equal marginal cost: P = MC.',
        source_ref: sourceRef
      })
    }), { status: 200, headers: { 'Content-Type': 'application/json' } });
  }
  return nativeFetch(input, init);
};

const diagnosticAi = require('../api/diagnostic-ai');
const diagnosticSelftest = require('../api/diagnostic-ai-selftest');
const root = path.resolve(__dirname, '..');
const port = Number(process.env.PORT || 4173);
let apiRequestCounter = 0;

const mime = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.webp': 'image/webp',
  '.woff2': 'font/woff2'
};

function parseBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let size = 0;
    req.on('data', chunk => {
      size += chunk.length;
      if (size > 1_000_000) {
        reject(new Error('request_too_large'));
        req.destroy();
        return;
      }
      chunks.push(chunk);
    });
    req.on('end', () => {
      if (!chunks.length) return resolve({});
      try { resolve(JSON.parse(Buffer.concat(chunks).toString('utf8'))); }
      catch (error) { reject(error); }
    });
    req.on('error', reject);
  });
}

async function runHandler(handler, req, res) {
  try {
    apiRequestCounter += 1;
    req.headers['x-forwarded-for'] = `198.51.100.${(apiRequestCounter % 200) + 1}`;
    if (req.method !== 'GET' && req.method !== 'HEAD') req.body = await parseBody(req);
    await handler(req, res);
  } catch (error) {
    if (res.writableEnded) return;
    res.statusCode = 500;
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    res.end(JSON.stringify({ error: 'e2e_server_error', detail: String(error?.message || error) }));
  }
}

function serveStatic(req, res, pathname) {
  const requested = pathname === '/' ? '/diagnostic-demo.html' : pathname;
  const decoded = decodeURIComponent(requested);
  const absolute = path.resolve(root, `.${decoded}`);
  if (!absolute.startsWith(root + path.sep)) {
    res.statusCode = 403;
    return res.end('Forbidden');
  }
  fs.stat(absolute, (error, stats) => {
    if (error || !stats.isFile()) {
      res.statusCode = 404;
      return res.end('Not found');
    }
    res.statusCode = 200;
    res.setHeader('Content-Type', mime[path.extname(absolute).toLowerCase()] || 'application/octet-stream');
    res.setHeader('Cache-Control', 'no-store');
    fs.createReadStream(absolute).pipe(res);
  });
}

const server = http.createServer(async (req, res) => {
  const parsed = new URL(req.url, `http://${req.headers.host || `127.0.0.1:${port}`}`);
  if (parsed.pathname === '/api/diagnostic-ai') return runHandler(diagnosticAi, req, res);
  if (parsed.pathname === '/api/diagnostic-ai-selftest') return runHandler(diagnosticSelftest, req, res);
  return serveStatic(req, res, parsed.pathname);
});

server.listen(port, '127.0.0.1', () => {
  process.stdout.write(`Demo AI E2E server listening on http://127.0.0.1:${port}\n`);
});

for (const signal of ['SIGTERM', 'SIGINT']) {
  process.on(signal, () => server.close(() => process.exit(0)));
}
