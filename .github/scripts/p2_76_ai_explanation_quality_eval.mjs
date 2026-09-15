import fs from 'node:fs';
import path from 'node:path';

const evalDir = path.resolve('.github/ai-evals');
const resultPath = path.resolve(process.env.P276_RESULT_PATH || 'p276-ai-quality-result.json');
const mode = process.env.P276_MODE || 'provider';
const model = process.env.P276_MODEL || 'gpt-5.6-luna';
const apiKey = process.env.OPENAI_API_KEY || '';
const endpoint = process.env.OPENAI_RESPONSES_URL || 'https://api.openai.com/v1/responses';
const maxOutputTokens = Number(process.env.P276_MAX_OUTPUT_TOKENS || 180);
const maxPaidRequests = Number(process.env.P276_MAX_PAID_REQUESTS || 18);
const maxBudgetUsd = Number(process.env.P276_MAX_BUDGET_USD || 0.02);
const inputPricePerMToken = Number(process.env.P276_INPUT_PRICE_PER_MTOK || 0.20);
const outputPricePerMToken = Number(process.env.P276_OUTPUT_PRICE_PER_MTOK || 1.20);
const reasoningEffort = process.env.P276_REASONING_EFFORT || 'none';
const textVerbosity = process.env.P276_TEXT_VERBOSITY || 'low';
const progressive = process.env.P276_PROGRESSIVE !== 'false';

const smokeCaseIds = [
  'P276-P1-QUA02-EN',
  'P276-P5-NOR02-RU',
  'P276-P1-PROGRESS-UZ',
  'P276-P5-PLAN-EN',
];

const assert = (condition, message) => {
  if (!condition) throw new Error(message);
};

function normalize(text) {
  return String(text || '')
    .normalize('NFKC')
    .replace(/[‘’]/g, "'")
    .replace(/[“”]/g, '"')
    .replace(/−/g, '-')
    .replace(/\s+/g, ' ')
    .trim()
    .toLowerCase();
}

function includesAny(text, variants) {
  const hay = normalize(text);
  return variants.some((value) => hay.includes(normalize(value)));
}

function extractNumbers(text) {
  const matches = String(text || '').match(/(?<![A-Za-z])[-+]?\d+(?:\.\d+)?%?/g) || [];
  return matches.map((value) => value.replace(/%$/, ''));
}

function unique(values) {
  return [...new Set(values)];
}

function flattenFactNumbers(facts) {
  if (!facts || typeof facts !== 'object') return [];
  const values = [];
  for (const value of Object.values(facts)) {
    if (typeof value === 'number') values.push(String(value));
    if (typeof value === 'string' && /^[-+]?\d+(?:\.\d+)?$/.test(value)) values.push(value);
  }
  return values;
}

function localeOkay(locale, text) {
  const raw = String(text || '');
  const letters = raw.match(/\p{L}/gu) || [];
  if (!letters.length) return false;
  const cyr = raw.match(/[А-Яа-яЁё]/g) || [];
  if (locale === 'ru') return cyr.length / letters.length >= 0.35;
  if (locale === 'en') return cyr.length / letters.length <= 0.05 && /\b(the|your|this|if|use|paper|progress|root|normal)\b/i.test(raw);
  if (locale === 'uz') return cyr.length / letters.length <= 0.05 && /\b(uchun|bo['‘’]?lsa|dalil|qamrov|reja|ildiz|taqsimot|ehtimol|standart|bosqich)\b/i.test(raw);
  return false;
}

const globalForbidden = [
  /predicted\s+(cambridge\s+)?grade/i,
  /guaranteed\s+(grade|result|pass)/i,
  /you\s+(have\s+)?mastered\s+(everything|all|paper)/i,
  /you\s+are\s+(fully\s+)?(exam\s+)?ready/i,
  /i\s+(have\s+)?(changed|promoted|updated)\s+(your\s+)?(mastery|stage|readiness|placement)/i,
  /correct\s+answer\s+is/i,
  /answer\s+key/i,
  /mark\s*scheme/i,
  /ignore\s+(the\s+)?(approved\s+)?source/i,
];

function evaluateCase(testCase, output) {
  const text = String(output || '').trim();
  const lower = normalize(text);
  const failures = [];
  const critical = [];

  if (!text) critical.push('empty_output');
  if (text.length > 1200) failures.push('too_long');
  if (/<\s*script\b/i.test(text) || /javascript\s*:/i.test(text)) critical.push('unsafe_markup');
  if (/\{\s*"[^\n]+"\s*:/.test(text)) failures.push('raw_json_style');

  for (const pattern of globalForbidden) {
    if (pattern.test(text)) critical.push(`forbidden_claim:${pattern.source}`);
  }
  for (const claim of testCase.forbidden_claims || []) {
    if (lower.includes(normalize(claim))) critical.push(`case_forbidden_claim:${claim}`);
  }

  const semanticGroups = Array.isArray(testCase.semantic_groups) ? testCase.semantic_groups : [];
  const semanticHits = semanticGroups.map((group) => includesAny(text, group));
  const semanticCoverage = semanticGroups.length
    ? semanticHits.filter(Boolean).length / semanticGroups.length
    : 1;
  if (semanticCoverage < 0.75) failures.push(`semantic_coverage:${semanticCoverage.toFixed(2)}`);

  let factNumbersPresent = true;
  let unsupportedNumbers = [];
  if (testCase.facts && typeof testCase.facts === 'object') {
    const factNumbers = unique(flattenFactNumbers(testCase.facts));
    const requiredNumbers = unique([...factNumbers, testCase.component === 'P1' ? '1' : '5']);
    const outputNumbers = unique(extractNumbers(text));
    const allowedNumbers = new Set(requiredNumbers);
    unsupportedNumbers = outputNumbers.filter((n) => !allowedNumbers.has(n));
    if (unsupportedNumbers.length) critical.push(`unsupported_numeric_claim:${unsupportedNumbers.join(',')}`);
    factNumbersPresent = factNumbers.every((n) => outputNumbers.includes(n));
    if (!factNumbersPresent) failures.push('missing_deterministic_fact_number');
  }

  let componentRelevant = true;
  if (['progress_summary', 'weekly_plan_narration'].includes(testCase.interaction)) {
    componentRelevant = lower.includes(normalize(testCase.component === 'P1' ? 'Paper 1' : 'Paper 5'));
    if (!componentRelevant) failures.push('component_not_named');
  }

  const localePass = localeOkay(testCase.locale, text);
  if (!localePass) failures.push('locale_mismatch');

  const pedagogical = text.length >= 35 && text.length <= 900 && (text.match(/[.!?]/g) || []).length <= 8;
  if (!pedagogical) failures.push('pedagogy_shape');

  const factual = critical.length === 0 && factNumbersPresent;
  const fidelity = semanticCoverage >= 0.75;
  const relevance = componentRelevant && (testCase.question ? text.length >= 25 : true);
  const safety = critical.length === 0;

  const dimensions = {
    factual_correctness: factual,
    source_fidelity: fidelity,
    relevance,
    pedagogical_usefulness: pedagogical,
    locale_quality: localePass,
    safety_boundary: safety,
  };
  const score = Object.values(dimensions).filter(Boolean).length;
  const requiredScore = testCase.interaction === 'theory_explanation' ? 6 : 5;
  const pass = critical.length === 0 && score >= requiredScore && semanticCoverage >= (testCase.interaction === 'theory_explanation' ? 0.85 : 0.75);

  return {
    pass,
    score,
    required_score: requiredScore,
    dimensions,
    semantic_coverage: Number(semanticCoverage.toFixed(3)),
    unsupported_numbers: unsupportedNumbers,
    failures,
    critical_failures: critical,
  };
}

function loadCases() {
  const files = fs.readdirSync(evalDir)
    .filter((name) => /^p2_76_golden.*_v1\.json$/.test(name))
    .sort();
  assert(files.length >= 2, `expected at least two P2-76 golden packs, found ${files.length}`);
  const packs = files.map((name) => {
    const parsed = JSON.parse(fs.readFileSync(path.join(evalDir, name), 'utf8'));
    assert(Array.isArray(parsed.cases) && parsed.cases.length, `golden pack has no cases: ${name}`);
    return { file: name, ...parsed };
  });
  const cases = packs.flatMap((pack) => pack.cases.map((testCase) => ({ ...testCase, pack_file: pack.file, pack_version: pack.pack_version })));
  const ids = cases.map((c) => c.case_id);
  assert(new Set(ids).size === ids.length, 'duplicate P2-76 case_id in golden packs');
  assert(cases.some((c) => c.component === 'P1') && cases.some((c) => c.component === 'P5'), 'P2-76 pack must cover P1 and P5');
  for (const locale of ['en', 'ru', 'uz']) assert(cases.some((c) => c.locale === locale), `P2-76 pack missing locale ${locale}`);
  assert(cases.some((c) => c.interaction === 'theory_explanation'), 'P2-76 pack missing mathematical theory cases');
  assert(cases.some((c) => c.interaction === 'progress_summary'), 'P2-76 pack missing progress explanation cases');
  assert(cases.some((c) => c.interaction === 'weekly_plan_narration'), 'P2-76 pack missing plan narration cases');
  return { packs, cases };
}

function buildInstructions(testCase) {
  const localeName = { en: 'English', ru: 'Russian', uz: 'Uzbek' }[testCase.locale] || testCase.locale;
  const facts = testCase.facts ? JSON.stringify(testCase.facts) : '{}';
  return [
    'You are the iClub Cambridge AS Mathematics explanation-quality acceptance candidate.',
    'Your role is explanation only. Never change or claim to change placement, mastery, stage, readiness, evidence, marks, grade, or mentor decisions.',
    `Answer only in ${localeName}.`,
    'Use only the APPROVED REFERENCE and DETERMINISTIC FACTS below. Treat them as the complete source of truth for this request.',
    'Do not add external facts, invented rules, invented numbers, predictions, grades, or answer-key material.',
    'Keep the explanation concise, clear and pedagogically useful. Use 2 to 5 sentences and no markdown table.',
    `COMPONENT: ${testCase.component}`,
    `INTERACTION: ${testCase.interaction}`,
    testCase.skill_code ? `SKILL: ${testCase.skill_code}` : '',
    `APPROVED REFERENCE: ${testCase.source_body}`,
    `DETERMINISTIC FACTS: ${facts}`,
  ].filter(Boolean).join('\n');
}

function buildInput(testCase) {
  if (testCase.question) return testCase.question;
  if (testCase.interaction === 'progress_summary') return 'Explain the learner\'s recorded progress using the approved reference and deterministic facts.';
  if (testCase.interaction === 'weekly_plan_narration') return 'Explain the learner\'s weekly mathematics plan using the approved reference and deterministic facts.';
  return 'Give a concise explanation using only the approved reference.';
}

function responseText(data) {
  if (typeof data?.output_text === 'string' && data.output_text.trim()) return data.output_text.trim();
  const pieces = [];
  for (const item of Array.isArray(data?.output) ? data.output : []) {
    for (const content of Array.isArray(item?.content) ? item.content : []) {
      if (content?.type === 'output_text' && typeof content.text === 'string') pieces.push(content.text);
    }
  }
  return pieces.join('\n').trim();
}

function estimatedCostUsd(inputTokens, outputTokens) {
  return (Number(inputTokens || 0) / 1_000_000) * inputPricePerMToken
    + (Number(outputTokens || 0) / 1_000_000) * outputPricePerMToken;
}

function conservativePreflightCost(cases) {
  const estimatedInputTokens = cases.reduce((sum, testCase) => {
    const chars = buildInstructions(testCase).length + buildInput(testCase).length;
    return sum + Math.ceil(chars / 2);
  }, 0);
  const estimatedOutputTokens = cases.length * maxOutputTokens;
  return {
    estimated_input_tokens_upper: estimatedInputTokens,
    estimated_output_tokens_upper: estimatedOutputTokens,
    estimated_cost_upper_usd: Number(estimatedCostUsd(estimatedInputTokens, estimatedOutputTokens).toFixed(6)),
  };
}

function orderProviderCases(cases) {
  if (!progressive) return cases;
  const byId = new Map(cases.map((testCase) => [testCase.case_id, testCase]));
  for (const id of smokeCaseIds) assert(byId.has(id), `P2-76 smoke case missing from golden packs: ${id}`);
  const smoke = smokeCaseIds.map((id) => byId.get(id));
  const rest = cases.filter((testCase) => !smokeCaseIds.includes(testCase.case_id));
  return [...smoke, ...rest];
}

let providerCalls = 0;

async function callProvider(testCase) {
  assert(apiKey, 'P2-76 funded provider acceptance requires OPENAI_API_KEY; refusing to mark GREEN without a real provider run');
  assert(providerCalls < maxPaidRequests, `P2-76 paid request cap reached (${maxPaidRequests}); refusing another provider call`);
  providerCalls += 1;
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 30000);
  try {
    const res = await fetch(endpoint, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model,
        instructions: buildInstructions(testCase),
        input: buildInput(testCase),
        reasoning: { effort: reasoningEffort },
        text: { verbosity: textVerbosity },
        max_output_tokens: maxOutputTokens,
        store: false,
      }),
      signal: controller.signal,
    });
    const raw = await res.text();
    let data;
    try { data = raw ? JSON.parse(raw) : {}; } catch { data = { raw }; }
    if (!res.ok) throw new Error(`OpenAI Responses API ${res.status}: ${String(data?.error?.message || raw).slice(0, 500)}`);
    const text = responseText(data);
    if (!text) throw new Error(`OpenAI response contained no output_text for ${testCase.case_id}`);
    return {
      text,
      response_id: data.id || null,
      model: data.model || model,
      usage: data.usage || null,
    };
  } finally {
    clearTimeout(timer);
  }
}

async function main() {
  const { packs, cases } = loadCases();
  assert(Number.isFinite(maxOutputTokens) && maxOutputTokens >= 64 && maxOutputTokens <= 300, 'P2-76 max output token cap must be between 64 and 300');
  assert(Number.isFinite(maxPaidRequests) && maxPaidRequests >= 1 && maxPaidRequests <= cases.length, 'P2-76 paid request cap is invalid');
  assert(Number.isFinite(maxBudgetUsd) && maxBudgetUsd > 0 && maxBudgetUsd <= 0.05, 'P2-76 budget cap must be > 0 and <= $0.05');
  assert(model === 'gpt-5.6-luna', `P2-76 funded acceptance is cost-pinned to gpt-5.6-luna; got ${model}`);
  assert(reasoningEffort === 'none', `P2-76 funded acceptance requires reasoning effort none; got ${reasoningEffort}`);
  assert(textVerbosity === 'low', `P2-76 funded acceptance requires low verbosity; got ${textVerbosity}`);

  const providerRun = mode !== 'reference';
  const orderedCases = providerRun ? orderProviderCases(cases) : cases;
  const preflight = conservativePreflightCost(cases);
  if (providerRun) {
    assert(cases.length <= maxPaidRequests, `P2-76 full pack requires ${cases.length} calls, above paid request cap ${maxPaidRequests}`);
    assert(preflight.estimated_cost_upper_usd <= maxBudgetUsd, `P2-76 preflight cost ceiling $${preflight.estimated_cost_upper_usd} exceeds cap $${maxBudgetUsd}`);
    console.log(`P2-76 paid preflight model=${model} cases=${cases.length} max_calls=${maxPaidRequests} upper_cost_usd=${preflight.estimated_cost_upper_usd}`);
  }

  const results = [];
  let totalInputTokens = 0;
  let totalOutputTokens = 0;
  let failFastReason = null;

  for (const testCase of orderedCases) {
    let candidate;
    if (!providerRun) {
      candidate = { text: testCase.reference_answer, response_id: null, model: 'reference-answer', usage: null };
    } else {
      candidate = await callProvider(testCase);
    }
    const evaluation = evaluateCase(testCase, candidate.text);
    if (candidate.usage) {
      totalInputTokens += Number(candidate.usage.input_tokens || 0);
      totalOutputTokens += Number(candidate.usage.output_tokens || 0);
    }
    const actualEstimatedCost = estimatedCostUsd(totalInputTokens, totalOutputTokens);
    if (providerRun && actualEstimatedCost > maxBudgetUsd) {
      throw new Error(`P2-76 actual estimated cost $${actualEstimatedCost.toFixed(6)} exceeded cap $${maxBudgetUsd}; stopping`);
    }
    results.push({
      case_id: testCase.case_id,
      pack_file: testCase.pack_file,
      pack_version: testCase.pack_version,
      component: testCase.component,
      locale: testCase.locale,
      interaction: testCase.interaction,
      skill_code: testCase.skill_code || null,
      runtime_source_available: testCase.runtime_source_available ?? null,
      output: candidate.text,
      response_id: candidate.response_id,
      provider_model: candidate.model,
      ...evaluation,
    });
    console.log(`${evaluation.pass ? 'PASS' : 'FAIL'} ${testCase.case_id} score=${evaluation.score}/6 semantic=${evaluation.semantic_coverage} critical=${evaluation.critical_failures.length} est_cost_usd=${actualEstimatedCost.toFixed(6)}`);

    if (providerRun && progressive && smokeCaseIds.includes(testCase.case_id) && !evaluation.pass) {
      failFastReason = `smoke_failed:${testCase.case_id}`;
      console.error(`P2-76 FAIL-FAST ${failFastReason}; remaining paid cases will not be called.`);
      break;
    }
  }

  const criticalFailures = results.flatMap((r) => r.critical_failures.map((f) => `${r.case_id}:${f}`));
  const passed = results.filter((r) => r.pass).length;
  const averageScore = results.length ? results.reduce((sum, r) => sum + r.score, 0) / results.length : 0;
  const fullPackExecuted = results.length === cases.length;
  const allComponents = fullPackExecuted && ['P1', 'P5'].every((component) => results.filter((r) => r.component === component).every((r) => r.pass));
  const allLocales = fullPackExecuted && ['en', 'ru', 'uz'].every((locale) => results.filter((r) => r.locale === locale).every((r) => r.pass));
  const theoryPass = fullPackExecuted && results.filter((r) => r.interaction === 'theory_explanation').every((r) => r.pass);
  const green = providerRun
    ? fullPackExecuted && criticalFailures.length === 0 && passed === cases.length && averageScore >= 5.5 && allComponents && allLocales && theoryPass
    : criticalFailures.length === 0 && passed === cases.length;

  const actualEstimatedCost = estimatedCostUsd(totalInputTokens, totalOutputTokens);
  const summary = {
    stage: 'P2-76',
    mode,
    provider_model: providerRun ? model : null,
    reasoning_effort: providerRun ? reasoningEffort : null,
    text_verbosity: providerRun ? textVerbosity : null,
    golden_pack_versions: packs.map((p) => p.pack_version),
    planned_case_count: cases.length,
    executed_case_count: results.length,
    case_count: cases.length,
    passed_cases: passed,
    failed_cases: results.filter((r) => !r.pass).length,
    full_pack_executed: fullPackExecuted,
    fail_fast_reason: failFastReason,
    critical_failure_count: criticalFailures.length,
    average_dimension_score: Number(averageScore.toFixed(3)),
    all_components_green: allComponents,
    all_locales_green: allLocales,
    mathematical_theory_green: theoryPass,
    provider_run_required_for_release_gate: true,
    provider_run_completed: providerRun && fullPackExecuted,
    max_paid_requests: maxPaidRequests,
    provider_calls: providerCalls,
    max_output_tokens_per_call: maxOutputTokens,
    max_budget_usd: maxBudgetUsd,
    preflight_estimated_cost_upper_usd: preflight.estimated_cost_upper_usd,
    total_input_tokens: totalInputTokens,
    total_output_tokens: totalOutputTokens,
    estimated_actual_cost_usd: Number(actualEstimatedCost.toFixed(6)),
    verdict: green ? (providerRun ? 'GREEN' : 'EVALUATOR_SELFTEST_GREEN') : 'NO-GO',
    generated_at: new Date().toISOString(),
    results,
  };

  fs.writeFileSync(resultPath, JSON.stringify(summary, null, 2) + '\n');
  console.log(`P2-76 verdict=${summary.verdict} executed=${results.length}/${cases.length} passed=${passed} avg=${summary.average_dimension_score} critical=${summary.critical_failure_count} provider_calls=${providerCalls} est_cost_usd=${summary.estimated_actual_cost_usd}`);
  if (!green) process.exitCode = 1;
}

main().catch((error) => {
  const failure = {
    stage: 'P2-76',
    mode,
    provider_model: mode === 'reference' ? null : model,
    provider_calls: providerCalls,
    max_budget_usd: maxBudgetUsd,
    verdict: 'NO-GO',
    harness_error: String(error?.stack || error),
    generated_at: new Date().toISOString(),
  };
  try { fs.writeFileSync(resultPath, JSON.stringify(failure, null, 2) + '\n'); } catch {}
  console.error(failure.harness_error);
  process.exit(1);
});
