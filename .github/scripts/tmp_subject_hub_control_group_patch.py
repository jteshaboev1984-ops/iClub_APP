from pathlib import Path
from textwrap import dedent

css_path = Path('visual/iclub-premium-v3.css')
css = css_path.read_text(encoding='utf-8')
marker = '/* ===== PREMIUM SUBJECT HUB CONTROL GROUP v3.3 ===== */'
if marker not in css:
    addition = dedent('''
    /* ===== PREMIUM SUBJECT HUB CONTROL GROUP v3.3 ===== */
    /* One grouped launcher surface: no pre-selected visual state, less card noise. */
    .iclub-visual-v3 #courses-subject-hub > .subject-hub-panels {
      order: 15;
      display: grid;
      margin: 0 0 12px;
    }

    .iclub-visual-v3 #courses-subject-hub > .subject-hub-panels .subject-hub-panel {
      padding: 11px 12px;
      border: 1px solid var(--v3-border);
      border-radius: var(--v3-radius-lg);
      background: #FFFFFF;
      box-shadow: var(--v3-premium-shadow);
    }

    .iclub-visual-v3 #courses-subject-hub > .subject-hub-tabs {
      order: 30;
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 0;
      margin: 0 0 12px;
      padding: 0;
      overflow: hidden;
      border: 1px solid var(--v3-border);
      border-radius: var(--v3-radius-lg);
      background: #FFFFFF;
      box-shadow: var(--v3-premium-shadow);
    }

    .iclub-visual-v3 #courses-subject-hub > .subject-hub-tabs .hub-tab,
    .iclub-visual-v3 #courses-subject-hub > .subject-hub-tabs .hub-tab.is-active {
      position: relative;
      display: flex;
      align-items: center;
      justify-content: flex-start;
      min-height: 58px;
      padding: 12px 34px 12px 14px;
      border: 0;
      border-radius: 0;
      background: transparent;
      color: var(--v3-text);
      text-align: left;
      font-size: 12px;
      font-weight: 760;
      box-shadow: none;
    }

    .iclub-visual-v3 #courses-subject-hub > .subject-hub-tabs .hub-tab:nth-child(odd) {
      border-right: 1px solid var(--v3-border);
    }

    .iclub-visual-v3 #courses-subject-hub > .subject-hub-tabs .hub-tab:nth-child(n+3) {
      border-top: 1px solid var(--v3-border);
    }

    .iclub-visual-v3 #courses-subject-hub > .subject-hub-tabs .hub-tab::after,
    .iclub-visual-v3 #courses-subject-hub > .subject-hub-tabs .hub-tab.is-active::after {
      content: "›";
      position: absolute;
      left: auto;
      right: 12px;
      top: 50%;
      bottom: auto;
      width: auto;
      height: auto;
      transform: translateY(-52%);
      border-radius: 0;
      background: transparent;
      color: #94A3B8;
      font-size: 20px;
      line-height: 1;
      font-weight: 500;
    }

    @media (hover:hover) {
      .iclub-visual-v3 #courses-subject-hub > .subject-hub-tabs .hub-tab:hover {
        background: #F8FAFD;
        color: var(--v3-text);
        box-shadow: none;
      }
    }

    .iclub-visual-v3 #courses-subject-hub > .subject-hub-tabs .hub-tab:active {
      transform: none;
      background: #F2F6FF;
      color: var(--v3-primary);
      box-shadow: inset 0 0 0 1px rgba(36, 87, 214, 0.08);
    }

    .iclub-visual-v3 #courses-subject-hub > .subject-hub-list.subject-hub-actions {
      order: 40;
      display: block;
      margin-top: 0;
      overflow: hidden;
      border: 1px solid var(--v3-border);
      border-radius: var(--v3-radius-lg);
      background: #FFFFFF;
      box-shadow: var(--v3-premium-shadow);
    }

    .iclub-visual-v3 #courses-subject-hub > .subject-hub-list.subject-hub-actions .settings-nav {
      min-height: 60px;
      border: 0;
      border-radius: 0;
      background: transparent;
      box-shadow: none;
    }

    .iclub-visual-v3 #courses-subject-hub > .subject-hub-list.subject-hub-actions .settings-nav + .settings-nav {
      border-top: 1px solid var(--v3-border);
    }

    .iclub-visual-v3 #subject-hub-exam-prep-entry.exam-prep-feature-card {
      margin: 0 0 14px;
      box-shadow: 0 12px 30px rgba(36, 87, 214, 0.085);
    }

    .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-button {
      gap: 8px;
      padding: 15px;
    }

    .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-title {
      font-size: 22px;
    }

    .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-description {
      max-width: 560px;
      font-size: 12px;
      line-height: 1.45;
    }

    .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-components {
      display: block;
      margin-top: 2px;
      overflow: hidden;
      border: 1px solid #D8E3FA;
      border-radius: var(--v3-radius-md);
      background: rgba(255,255,255,.66);
    }

    .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-component {
      display: flex;
      align-items: center;
      gap: 8px;
      min-height: 48px;
      padding: 9px 10px;
      border: 0;
      border-radius: 0;
      background: transparent;
    }

    .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-component + .exam-prep-feature-component {
      border-top: 1px solid #DDE6F8;
    }

    .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-component strong {
      flex: 0 0 auto;
      min-width: 30px;
      text-align: center;
    }

    .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-component span {
      min-width: 0;
      line-height: 1.35;
    }

    .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-footer {
      justify-content: flex-end;
      margin-top: 1px;
      padding-top: 6px;
      border-top: 0;
    }

    .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-note {
      display: none;
    }

    .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-cta {
      min-height: 28px;
      padding: 4px 0;
      border-radius: 0;
      background: transparent;
      color: var(--v3-primary);
      font-size: 11px;
      font-weight: 800;
    }

    .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-cta::after {
      content: "  →";
    }

    @media (min-width: 620px) {
      .iclub-visual-v3 #courses-subject-hub > .subject-hub-tabs {
        grid-template-columns: repeat(4, minmax(0, 1fr));
      }

      .iclub-visual-v3 #courses-subject-hub > .subject-hub-tabs .hub-tab:nth-child(odd),
      .iclub-visual-v3 #courses-subject-hub > .subject-hub-tabs .hub-tab:nth-child(n+3) {
        border-top: 0;
        border-right: 0;
      }

      .iclub-visual-v3 #courses-subject-hub > .subject-hub-tabs .hub-tab:not(:last-child) {
        border-right: 1px solid var(--v3-border);
      }
    }
    ''')
    css_path.write_text(css.rstrip() + '\n\n' + addition.strip() + '\n', encoding='utf-8')


test_path = Path('.github/scripts/visual_v3_subject_hub_architecture_regression.js')
test = test_path.read_text(encoding='utf-8')
if "'PREMIUM SUBJECT HUB CONTROL GROUP v3.3'" not in test:
    test = test.replace("  'PREMIUM SUBJECT HUB ACTION AFFORDANCE v3.2',", "  'PREMIUM SUBJECT HUB ACTION AFFORDANCE v3.2',\n  'PREMIUM SUBJECT HUB CONTROL GROUP v3.3',")

old_state = "      mentorBeforeFeature: panels.getBoundingClientRect().top < entry.getBoundingClientRect().top,\n      width: document.documentElement.scrollWidth,"
new_state = "      mentorBeforeFeature: panels.getBoundingClientRect().top < entry.getBoundingClientRect().top,\n      tabsGap: getComputedStyle(tabs).gap,\n      tabsBorder: getComputedStyle(tabs).borderTopStyle,\n      firstTabShadow: getComputedStyle(firstTab).boxShadow,\n      firstTabAfterBackground: getComputedStyle(firstTab, '::after').backgroundColor,\n      firstTabAfterBottom: getComputedStyle(firstTab, '::after').bottom,\n      secondaryGroupBorder: getComputedStyle(actions).borderTopStyle,\n      width: document.documentElement.scrollWidth,"
if old_state in test:
    test = test.replace(old_state, new_state)
elif new_state not in test:
    raise SystemExit('Expected Subject Hub state block not found')

old_assert = "  assert(state.mentorBeforeFeature === true, 'Mentor card must stay in its original place directly after the subject header');\n  assert(state.width <= state.innerWidth, `Subject Hub mobile overflow: ${JSON.stringify(state)}`);"
new_assert = "  assert(state.mentorBeforeFeature === true, 'Mentor card must stay in its original place directly after the subject header');\n  assert(state.tabsGap === '0px', `Primary actions must read as one control group, gap=${state.tabsGap}`);\n  assert(state.tabsBorder === 'solid', `Primary action group needs a clear outer boundary, border=${state.tabsBorder}`);\n  assert(state.firstTabShadow === 'none', `Primary action cell must not look like a selected floating card: ${state.firstTabShadow}`);\n  assert(state.firstTabAfterBackground === 'rgba(0, 0, 0, 0)', `Legacy active underline leaked into launcher: ${state.firstTabAfterBackground}`);\n  assert(state.firstTabAfterBottom === 'auto', `Legacy active underline positioning leaked into launcher: bottom=${state.firstTabAfterBottom}`);\n  assert(state.secondaryGroupBorder === 'solid', `Secondary actions must be grouped, border=${state.secondaryGroupBorder}`);\n  assert(state.width <= state.innerWidth, `Subject Hub mobile overflow: ${JSON.stringify(state)}`);"
if old_assert in test:
    test = test.replace(old_assert, new_assert)
elif new_assert not in test:
    raise SystemExit('Expected Subject Hub assertion block not found')

test_path.write_text(test, encoding='utf-8')
