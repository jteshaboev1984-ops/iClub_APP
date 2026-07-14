'use strict';

const { defineConfig } = require('@playwright/test');

module.exports = defineConfig({
  testDir: './tests',
  testMatch: /demo-ai-e2e\.spec\.js/,
  timeout: 120_000,
  expect: { timeout: 12_000 },
  fullyParallel: false,
  workers: 1,
  retries: 0,
  reporter: [
    ['list'],
    ['json', { outputFile: 'test-results/demo-ai-e2e-results.json' }]
  ],
  use: {
    baseURL: 'http://127.0.0.1:4173',
    actionTimeout: 12_000,
    navigationTimeout: 30_000,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'on'
  },
  webServer: {
    command: 'node tests/demo-ai-e2e-server.js',
    url: 'http://127.0.0.1:4173/api/diagnostic-ai',
    timeout: 120_000,
    reuseExistingServer: false
  }
});
