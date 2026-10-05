const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const edge = fs.readFileSync('supabase/functions/exam-prep-ai/index.ts', 'utf8');
const ui = fs.readFileSync('exam-prep/exam-prep-ai-ui.js', 'utf8');

assert(edge.includes('get_exam_prep_ai_tutor_template_canary_service_v1'), 'Tutor Template canary service lookup missing');
assert(edge.includes('get_exam_prep_ai_tutor_card_service_v1'), 'Tutor Card service lookup missing from Edge');
assert(edge.includes('mode = "verified_template"') || edge.includes('const mode = "verified_template"'), 'verified_template Edge mode missing');
assert(edge.includes('verified_template: true'), 'verified_template response marker missing');
assert(edge.includes('generated: false'), 'provider-free generated=false contract missing');
assert(edge.includes('academic_state_changed: false'), 'academic state safety contract missing');
assert(edge.includes('["generated","verified_template"]') || edge.includes('["generated", "verified_template"]'), 'verified_template thread parent support missing');
assert(edge.includes('"main"') && edge.includes('"simple"') && edge.includes('"alternative"') && edge.includes('"focus"'), 'Tutor Template variants missing');

const interceptPos = edge.indexOf('// Provider-free Tutor Template canary.');
const reservePos = edge.indexOf('reservedCostUsd = conservativeProviderReservationCost');
assert(interceptPos > 0 && reservePos > interceptPos, 'Tutor Template intercept must run before provider reservation');

const variantStart = edge.indexOf('const variant:', interceptPos);
const variantEnd = edge.indexOf('if (variant)', variantStart);
const variantBlock = edge.slice(variantStart, variantEnd);
assert(variantBlock.includes('followupMode === "simplify"'), 'simplify preset mapping missing');
assert(variantBlock.includes('followupMode === "rephrase"'), 'rephrase preset mapping missing');
assert(variantBlock.includes('followupMode === "focus"'), 'focus preset mapping missing');
assert(!variantBlock.includes('followupMode === "question"'), 'learner free-text question must not use a static Tutor Template');

assert(ui.includes('topic: "Explain this topic"'), 'English curated topic action copy missing');
assert(ui.includes('topic: "Объяснить эту тему"'), 'Russian curated topic action copy missing');
assert(ui.includes('topic: "Bu mavzuni tushuntirish"'), 'Uzbek curated topic action copy missing');
assert(ui.includes('mode === "verified_template"'), 'UI does not recognize verified_template response');
assert(ui.includes('curatedSourceNote'), 'Curated source note contract missing');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  try {
    await page.setContent(`<!doctype html><html lang="en"><head></head><body>
      <div id="exam-prep-host-root" aria-hidden="false">
        <section data-ep-views-screen data-ep-ai-skill-detail="P1-QUA-01" data-ep-ai-skill-component="P1">
          <div class="ep-views-title">Completing the square</div>
          <div class="ep-views-summary"></div>
        </section>
      </div>
    </body></html>`);

    await page.evaluate(() => {
      window.__calls = [];
      window.i18n = { getLang: () => 'en' };
      window.iClubExamPrepHostInternal = {
        lastCapabilities: {
          rolloutState: 'controlled_beta',
          coreAccess: true,
          aiAssist: true,
          killSwitch: false
        },
        learnerCopy: {
          skillTitle: code => code === 'P1-QUA-01' ? 'Completing the square' : ''
        }
      };

      window.sb = {
        functions: {
          invoke: async (name, options) => {
            const body = options?.body || {};
            window.__calls.push({ name, body });

            if (body.interaction_type === 'theory_explanation') {
              return {
                data: {
                  request_id: '41000000-0000-4000-8000-000000000001',
                  mode: 'verified_template',
                  verified_template: true,
                  template_variant: 'main',
                  message: 'Curated main explanation',
                  generated: false,
                  academic_state_changed: false,
                  thread_eligible: true,
                  followup_turn: 0,
                  max_followups: 2
                },
                error: null
              };
            }

            if (body.interaction_type === 'context_followup' && body.followup_mode === 'simplify') {
              return {
                data: {
                  request_id: '41000000-0000-4000-8000-000000000002',
                  mode: 'verified_template',
                  verified_template: true,
                  template_variant: 'simple',
                  message: 'Curated simpler explanation',
                  generated: false,
                  academic_state_changed: false,
                  thread_eligible: true,
                  followup_turn: 1,
                  max_followups: 2
                },
                error: null
              };
            }

            if (body.interaction_type === 'context_followup' && body.followup_mode === 'question') {
              return {
                data: {
                  request_id: '41000000-0000-4000-8000-000000000003',
                  mode: 'generated',
                  message: 'Generated answer to the learner question',
                  generated: true,
                  academic_state_changed: false,
                  thread_eligible: false,
                  followup_turn: 2,
                  max_followups: 2
                },
                error: null
              };
            }

            return { data: null, error: { message: 'unexpected mock call' } };
          }
        }
      };
    });

    await page.addScriptTag({ path: path.resolve('exam-prep/exam-prep-ai-ui.js') });
    await page.waitForSelector('[data-ep-ai-topic-action-wrap] [data-ep-ai-action="theory_explanation"]');

    const rootLabel = await page.locator('[data-ep-ai-topic-action-wrap] [data-ep-ai-context-label]').textContent();
    assert(rootLabel === 'Explain this topic', 'Topic action still advertises provider AI instead of the learner action');

    await page.click('[data-ep-ai-topic-action-wrap] [data-ep-ai-action="theory_explanation"]');
    await page.waitForFunction(() =>
      document.querySelector('[data-ep-ai-topic-action-wrap] [data-ep-ai-output-text]')?.textContent === 'Curated main explanation'
    );
    await page.waitForSelector('[data-ep-ai-topic-action-wrap] [data-ep-ai-followup]:not([hidden])');

    let state = await page.evaluate(() => ({
      note: document.querySelector('[data-ep-ai-topic-action-wrap] [data-ep-ai-output-note]')?.textContent || '',
      calls: window.__calls
    }));
    assert(state.note === 'Based on reviewed iClub learning material.', 'Curated root explanation did not use curated source note');
    assert(state.calls.length === 1, 'Curated root must make exactly one Edge request');
    assert(state.calls[0].body.interaction_type === 'theory_explanation', 'Curated root interaction drifted');
    assert(state.calls[0].body.skill_code === 'P1-QUA-01', 'Curated root lost exact skill binding');

    await page.click('[data-ep-ai-topic-action-wrap] [data-ep-ai-followup-open]');
    await page.click('[data-ep-ai-topic-action-wrap] [data-ep-ai-followup-mode="simplify"]');
    await page.waitForFunction(() => document.body.textContent.includes('Curated simpler explanation'));

    state = await page.evaluate(() => ({
      note: document.querySelector('[data-ep-ai-topic-action-wrap] [data-ep-ai-output-note]')?.textContent || '',
      calls: window.__calls
    }));
    assert(state.note === 'Based on reviewed iClub learning material.', 'Curated preset follow-up lost curated source note');
    assert(state.calls.length === 2, 'Preset clarification should add exactly one Edge request');
    const preset = state.calls[1].body;
    assert(preset.interaction_type === 'context_followup' && preset.followup_mode === 'simplify', 'Preset clarification contract drifted');
    assert(preset.parent_request_id === '41000000-0000-4000-8000-000000000001', 'Preset clarification lost verified-template parent');
    assert(preset.prior_assistant_text === 'Curated main explanation', 'Preset clarification lost curated parent output binding');
    assert(preset.followup_turn === 1, 'Preset clarification turn drifted');
    assert(preset.skill_code === 'P1-QUA-01', 'Preset clarification crossed skill boundary');
    assert(preset.user_text === '', 'Preset clarification must not send free text');

    await page.fill('[data-ep-ai-topic-action-wrap] [data-ep-ai-followup-input]', 'Why does completing the square help?');
    await page.click('[data-ep-ai-topic-action-wrap] [data-ep-ai-followup-send]');
    await page.waitForFunction(() => document.body.textContent.includes('Generated answer to the learner question'));

    state = await page.evaluate(() => ({
      note: document.querySelector('[data-ep-ai-topic-action-wrap] [data-ep-ai-output-note]')?.textContent || '',
      calls: window.__calls,
      doneVisible: document.querySelector('[data-ep-ai-topic-action-wrap] [data-ep-ai-followup-done]')?.hidden === false
    }));
    assert(state.note === 'Based on iClub learning material and your work in the app.', 'Generated learner question should restore personalized source note');
    assert(state.calls.length === 3, 'Learner question should add exactly one provider-backed Edge request');
    const question = state.calls[2].body;
    assert(question.interaction_type === 'context_followup' && question.followup_mode === 'question', 'Learner question interaction drifted');
    assert(question.parent_request_id === '41000000-0000-4000-8000-000000000002', 'Learner question did not chain from curated preset clarification');
    assert(question.prior_assistant_text === 'Curated simpler explanation', 'Learner question lost previous curated output binding');
    assert(question.followup_turn === 2, 'Learner question turn drifted');
    assert(question.skill_code === 'P1-QUA-01', 'Learner question crossed skill boundary');
    assert(question.user_text === 'Why does completing the square help?', 'Learner question text changed');
    assert(state.doneVisible, 'Two-turn thread did not close after the provider-backed learner question');

    console.log('P3-17 Tutor Template canary contract: GREEN');
  } finally {
    await browser.close();
  }
})().catch(error => {
  console.error(error);
  process.exit(1);
});
