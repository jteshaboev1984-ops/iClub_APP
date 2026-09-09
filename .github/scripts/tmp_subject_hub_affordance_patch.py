from pathlib import Path
from textwrap import dedent

css_path = Path('visual/iclub-premium-v3.css')
css = css_path.read_text(encoding='utf-8')
marker = '/* ===== PREMIUM SUBJECT HUB ACTION AFFORDANCE v3.2 ===== */'
if marker not in css:
    addition = dedent('''
    /* ===== PREMIUM SUBJECT HUB ACTION AFFORDANCE v3.2 ===== */
    /* Primary learning controls are launchers, not selected tabs. */
    .iclub-visual-v3 #courses-subject-hub > .subject-hub-panels {
      order: 15;
      margin: 0 0 12px;
    }

    .iclub-visual-v3 #courses-subject-hub > .subject-hub-tabs {
      order: 30;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 8px;
      margin: 0 0 12px;
      padding: 0;
      border: 0;
      background: transparent;
    }

    .iclub-visual-v3 #courses-subject-hub > .subject-hub-tabs .hub-tab {
      position: relative;
      display: flex;
      align-items: center;
      justify-content: flex-start;
      min-height: 56px;
      padding: 12px 38px 12px 14px;
      border: 1px solid var(--v3-border);
      border-radius: var(--v3-radius-lg);
      background: #FFFFFF;
      color: var(--v3-text);
      text-align: left;
      font-size: 12px;
      font-weight: 760;
      box-shadow: var(--v3-premium-shadow);
      transition: border-color .16s ease, background-color .16s ease, box-shadow .16s ease, transform .08s ease;
    }

    .iclub-visual-v3 #courses-subject-hub > .subject-hub-tabs .hub-tab::after {
      content: "›";
      position: absolute;
      right: 13px;
      top: 50%;
      transform: translateY(-52%);
      color: #94A3B8;
      font-size: 21px;
      line-height: 1;
      font-weight: 500;
    }

    .iclub-visual-v3 #courses-subject-hub > .subject-hub-tabs .hub-tab.is-active {
      border-color: var(--v3-border);
      background: #FFFFFF;
      color: var(--v3-text);
      box-shadow: var(--v3-premium-shadow);
    }

    .iclub-visual-v3 #courses-subject-hub > .subject-hub-tabs .hub-tab.is-active::after {
      color: #94A3B8;
    }

    body.iclub-visual-v3 #courses-subject-hub.is-study > .subject-hub-tabs .hub-tab:nth-child(3),
    body.iclub-visual-v3 #courses-subject-hub.is-study > .subject-hub-tabs .hub-tab.is-active:nth-child(3) {
      color: var(--v3-text);
    }

    @media (hover:hover) {
      .iclub-visual-v3 #courses-subject-hub > .subject-hub-tabs .hub-tab:hover {
        border-color: #C9D7F8;
        background: #FBFCFF;
        box-shadow: var(--v3-premium-shadow-hover);
      }
    }

    .iclub-visual-v3 #courses-subject-hub > .subject-hub-tabs .hub-tab:focus-visible {
      outline: 3px solid rgba(36, 87, 214, 0.16);
      outline-offset: 2px;
    }

    .iclub-visual-v3 #courses-subject-hub > .subject-hub-tabs .hub-tab:active {
      transform: translateY(1px);
      border-color: #C9D7F8;
      background: #F7F9FE;
      box-shadow: none;
    }

    @media (min-width: 620px) {
      .iclub-visual-v3 #courses-subject-hub > .subject-hub-tabs {
        grid-template-columns: repeat(4, minmax(0, 1fr));
      }
    }

    @media (max-width: 350px) {
      .iclub-visual-v3 #courses-subject-hub > .subject-hub-tabs {
        grid-template-columns: 1fr;
      }
    }
    ''')
    css_path.write_text(css.rstrip() + '\n\n' + addition.strip() + '\n', encoding='utf-8')


test_path = Path('.github/scripts/visual_v3_subject_hub_architecture_regression.js')
test = test_path.read_text(encoding='utf-8')
old = "assert(JSON.stringify(state.orders) === JSON.stringify({ head: 10, entry: 20, tabs: 30, actions: 40, panels: 50, system: 60, bottom: 80 }), `Subject Hub hierarchy drift: ${JSON.stringify(state.orders)}`);"
new = "assert(JSON.stringify(state.orders) === JSON.stringify({ head: 10, entry: 20, tabs: 30, actions: 40, panels: 15, system: 60, bottom: 80 }), `Subject Hub hierarchy drift: ${JSON.stringify(state.orders)}`);"
if old in test:
    test = test.replace(old, new)
elif new not in test:
    raise SystemExit('Expected hierarchy assertion not found')

old_state = "      tabHeight: firstTab.getBoundingClientRect().height,\n      width: document.documentElement.scrollWidth,"
new_state = "      tabHeight: firstTab.getBoundingClientRect().height,\n      activeTabBackground: getComputedStyle(firstTab).backgroundColor,\n      activeTabColor: getComputedStyle(firstTab).color,\n      mentorBeforeFeature: panels.getBoundingClientRect().top < entry.getBoundingClientRect().top,\n      width: document.documentElement.scrollWidth,"
if old_state in test:
    test = test.replace(old_state, new_state)
elif new_state not in test:
    raise SystemExit('Expected state block not found')

old_assert = "  assert(state.tabHeight >= 46, `Subject Hub primary action target too small: ${state.tabHeight}`);\n  assert(state.width <= state.innerWidth, `Subject Hub mobile overflow: ${JSON.stringify(state)}`);"
new_assert = "  assert(state.tabHeight >= 54, `Subject Hub primary action target too small: ${state.tabHeight}`);\n  assert(state.activeTabBackground === 'rgb(255, 255, 255)', `Primary action must not look pre-selected: ${state.activeTabBackground}`);\n  assert(state.activeTabColor === 'rgb(15, 23, 42)', `Primary action selected-color leak: ${state.activeTabColor}`);\n  assert(state.mentorBeforeFeature === true, 'Mentor card must stay in its original place directly after the subject header');\n  assert(state.width <= state.innerWidth, `Subject Hub mobile overflow: ${JSON.stringify(state)}`);"
if old_assert in test:
    test = test.replace(old_assert, new_assert)
elif new_assert not in test:
    raise SystemExit('Expected assertion block not found')

if "'PREMIUM SUBJECT HUB ACTION AFFORDANCE v3.2'" not in test:
    test = test.replace("  'PREMIUM SUBJECT HUB ARCHITECTURE v3.1',", "  'PREMIUM SUBJECT HUB ARCHITECTURE v3.1',\n  'PREMIUM SUBJECT HUB ACTION AFFORDANCE v3.2',")

test_path.write_text(test, encoding='utf-8')
