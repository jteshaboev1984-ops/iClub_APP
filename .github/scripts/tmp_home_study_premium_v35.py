from pathlib import Path
from textwrap import dedent

APP = Path('app.js')
I18N = Path('i18n.js')
INDEX = Path('index.html')
CSS = Path('visual/iclub-premium-v3.css')
WORKFLOW = Path('.github/workflows/visual-v3-premium.yml')

# app.js: visual-only replacement of the remaining pinned-subject emoji.
app = APP.read_text(encoding='utf-8')
old_icon = '<div class="home-pinned-ico">📘</div>'
new_icon = '''<div class="home-pinned-ico" aria-hidden="true"><svg class="v3-home-pinned-icon" viewBox="0 0 24 24"><path d="M4 5.5A2.5 2.5 0 0 1 6.5 3H11v16H6.5A2.5 2.5 0 0 0 4 21z"/><path d="M20 5.5A2.5 2.5 0 0 0 17.5 3H13v16h4.5A2.5 2.5 0 0 1 20 21z"/></svg></div>'''
if 'class="v3-home-pinned-icon"' not in app:
    if app.count(old_icon) != 1:
        raise SystemExit(f'Expected exactly one pinned emoji template, found {app.count(old_icon)}')
    app = app.replace(old_icon, new_icon, 1)
APP.write_text(app, encoding='utf-8')

# Align learner-facing Study title with the permanent bottom navigation label.
i18n = I18N.read_text(encoding='utf-8')
replacements = {
    'courses_title: "Курсы"': 'courses_title: "Учёба"',
    'courses_title: "Kurslar"': 'courses_title: "O‘qish"',
    'courses_title: "Courses"': 'courses_title: "Study"',
}
for old, new in replacements.items():
    if new not in i18n:
        if i18n.count(old) != 1:
            raise SystemExit(f'i18n title anchor mismatch for {old}: {i18n.count(old)}')
        i18n = i18n.replace(old, new, 1)
I18N.write_text(i18n, encoding='utf-8')

html = INDEX.read_text(encoding='utf-8')
old_title = '<div class="section-title" data-i18n="courses_title">Courses</div>'
new_title = '<div class="section-title" data-i18n="courses_title">Study</div>'
if new_title not in html:
    if html.count(old_title) != 1:
        raise SystemExit(f'Study fallback title anchor mismatch: {html.count(old_title)}')
    html = html.replace(old_title, new_title, 1)
INDEX.write_text(html, encoding='utf-8')

# Premium Home + Study architecture. Presentation only.
css = CSS.read_text(encoding='utf-8')
marker = '/* ===== PREMIUM HOME STUDY ARCHITECTURE v3.5 ===== */'
if marker not in css:
    css += '\n\n' + dedent('''
    /* ===== PREMIUM HOME STUDY ARCHITECTURE v3.5 ===== */
    /* Home prioritizes active work; Study is the subject/mode control surface. */
    .iclub-visual-v3 #view-home .home-competitive-card {
      position: relative;
      overflow: hidden;
      padding: 0;
      border: 1px solid #DCE4F4;
      border-radius: var(--v3-radius-lg);
      background: #FFFFFF;
      box-shadow: var(--v3-premium-shadow);
    }

    .iclub-visual-v3 #view-home .home-competitive-badge {
      position: absolute;
      z-index: 2;
      top: 9px;
      left: 10px;
      max-width: calc(100% - 20px);
      padding: 4px 7px;
      border: 1px solid rgba(255, 255, 255, 0.72);
      border-radius: 999px;
      background: rgba(255, 255, 255, 0.92);
      color: var(--v3-text);
      font-size: 9px;
      line-height: 1.2;
      font-weight: 800;
      letter-spacing: .045em;
      box-shadow: 0 4px 12px rgba(15, 23, 42, 0.07);
    }

    .iclub-visual-v3 #view-home .home-competitive-hero {
      height: 76px;
      border-radius: 0;
      background: #EEF3FB;
    }

    .iclub-visual-v3 #view-home .home-competitive-hero::after {
      content: "";
      position: absolute;
      inset: 0;
      background: linear-gradient(180deg, rgba(15, 23, 42, 0.04), rgba(15, 23, 42, 0.14));
      pointer-events: none;
    }

    .iclub-visual-v3 #view-home .home-competitive-hero-img {
      filter: saturate(.86) contrast(.97);
    }

    .iclub-visual-v3 #view-home .home-competitive-body {
      gap: 6px;
      padding: 12px 14px 10px;
    }

    .iclub-visual-v3 #view-home .home-competitive-title {
      color: var(--v3-text);
      font-size: 16px;
      line-height: 1.2;
      font-weight: 790;
      letter-spacing: -0.014em;
    }

    .iclub-visual-v3 #view-home .home-competitive-note,
    .iclub-visual-v3 #view-home .home-competitive-meta,
    .iclub-visual-v3 #view-home .home-competitive-percent {
      color: var(--v3-muted);
      font-size: 11px;
      line-height: 1.4;
    }

    .iclub-visual-v3 #view-home .home-competitive-meta {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 10px;
    }

    .iclub-visual-v3 #view-home .home-progress {
      height: 5px;
      margin-top: 2px;
      overflow: hidden;
      border-radius: 999px;
      background: #E9EEF7;
    }

    .iclub-visual-v3 #view-home .home-progress-fill {
      border-radius: inherit;
      background: var(--v3-primary);
    }

    .iclub-visual-v3 #view-home .home-competitive-btn {
      width: calc(100% - 28px);
      min-height: 42px;
      margin: 0 14px 14px;
      border-radius: var(--v3-radius-md);
      font-size: 12px;
      font-weight: 780;
      box-shadow: 0 5px 14px rgba(36, 87, 214, 0.16);
    }

    .iclub-visual-v3 #view-home #home-study-list {
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 9px;
      margin-top: 10px;
    }

    .iclub-visual-v3 #view-home .home-pinned-tile {
      display: grid;
      grid-template-columns: 36px minmax(0, 1fr);
      grid-template-areas:
        "icon title"
        "icon meta";
      align-items: center;
      column-gap: 9px;
      row-gap: 2px;
      min-width: 0;
      min-height: 78px;
      padding: 11px 12px;
      overflow: hidden;
      border: 1px solid var(--v3-border);
      border-radius: var(--v3-radius-lg);
      background: #FFFFFF;
      color: var(--v3-text);
      box-shadow: var(--v3-premium-shadow);
    }

    .iclub-visual-v3 #view-home .home-pinned-ico {
      grid-area: icon;
      width: 36px;
      height: 36px;
      display: grid;
      place-items: center;
      border: 1px solid #D8E3FB;
      border-radius: var(--v3-radius-sm);
      background: var(--v3-primary-soft);
      color: var(--v3-primary);
      font-size: 0;
    }

    .iclub-visual-v3 #view-home .v3-home-pinned-icon {
      width: 18px;
      height: 18px;
      display: block;
      fill: none;
      stroke: currentColor;
      stroke-width: 1.7;
      stroke-linecap: round;
      stroke-linejoin: round;
    }

    .iclub-visual-v3 #view-home .home-pinned-title {
      grid-area: title;
      min-width: 0;
      color: var(--v3-text);
      font-size: 12px;
      line-height: 1.25;
      font-weight: 760;
      letter-spacing: -0.006em;
      overflow-wrap: anywhere;
    }

    .iclub-visual-v3 #view-home .home-pinned-meta {
      grid-area: meta;
      min-width: 0;
      color: var(--v3-muted);
      font-size: 10px;
      line-height: 1.3;
      overflow-wrap: anywhere;
    }

    .iclub-visual-v3 #courses-all-subjects > .section {
      margin-top: 4px;
      margin-bottom: 14px;
    }

    .iclub-visual-v3 #courses-all-subjects #courses-filter-row {
      display: block;
      width: 100%;
      margin-top: 12px;
      padding: 4px;
      overflow: visible;
      border: 1px solid var(--v3-border);
      border-radius: var(--v3-radius-lg);
      background: #F1F4F9;
    }

    .iclub-visual-v3 #courses-all-subjects .grid-section-filters {
      width: 100%;
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 4px;
    }

    .iclub-visual-v3 #courses-all-subjects #courses-filter-row .grid-section-filters .chip {
      width: 100%;
      min-width: 0;
      min-height: 38px;
      padding: 8px 10px;
      border: 0;
      border-radius: var(--v3-radius-sm);
      background: transparent;
      color: var(--v3-muted);
      font-size: 11px;
      line-height: 1.2;
      font-weight: 760;
      box-shadow: none;
    }

    .iclub-visual-v3 #courses-all-subjects #courses-filter-row .grid-section-filters .chip.is-active {
      background: #FFFFFF;
      color: var(--v3-primary);
      box-shadow: 0 2px 8px rgba(15, 23, 42, 0.07);
    }

    .iclub-visual-v3 #courses-all-subjects #subjects-grid {
      gap: 9px;
    }

    .iclub-visual-v3 #courses-all-subjects .grid-section-title {
      margin-top: 7px;
      padding: 9px 2px 4px;
      color: var(--v3-muted);
      font-size: 10px;
      line-height: 1.25;
      font-weight: 800;
      letter-spacing: .065em;
      text-transform: uppercase;
    }

    .iclub-visual-v3 #courses-all-subjects .catalog-card {
      min-width: 0;
      overflow: hidden;
      border: 1px solid var(--v3-border);
      border-radius: var(--v3-radius-lg);
      background: #FFFFFF;
      box-shadow: var(--v3-premium-shadow);
    }

    .iclub-visual-v3 #courses-all-subjects .catalog-head {
      position: relative;
      min-height: 54px;
      padding: 12px 40px 11px 13px;
      background: #FFFFFF;
    }

    .iclub-visual-v3 #courses-all-subjects .catalog-head::after {
      content: "";
      position: absolute;
      top: 50%;
      right: 15px;
      width: 7px;
      height: 7px;
      border-right: 1.6px solid #94A3B8;
      border-bottom: 1.6px solid #94A3B8;
      transform: translateY(-50%) rotate(-45deg);
      pointer-events: none;
    }

    .iclub-visual-v3 #courses-all-subjects .catalog-head .card-title {
      margin: 0;
      color: var(--v3-text);
      font-size: 14px;
      line-height: 1.3;
      font-weight: 760;
      letter-spacing: -0.008em;
      overflow-wrap: anywhere;
    }

    .iclub-visual-v3 #courses-all-subjects .catalog-toggle-row {
      min-height: 48px;
      padding: 9px 12px;
      border-top: 1px solid #EDF1F7;
      background: #FBFCFE;
    }

    .iclub-visual-v3 #courses-all-subjects .catalog-toggle-row::after {
      display: none;
    }

    .iclub-visual-v3 #courses-all-subjects .catalog-toggle-row.is-on {
      background: #F4F7FF;
    }

    .iclub-visual-v3 #courses-all-subjects .catalog-toggle-state {
      color: var(--v3-muted);
      font-size: 11px;
      line-height: 1.25;
      font-weight: 700;
    }

    .iclub-visual-v3 #courses-all-subjects .catalog-toggle-row.is-on .catalog-toggle-state {
      color: var(--v3-primary);
    }

    .iclub-visual-v3 #courses-all-subjects .catalog-card:focus-within {
      border-color: #CFDBF8;
      box-shadow: 0 0 0 3px rgba(36, 87, 214, 0.08), var(--v3-premium-shadow);
    }

    @media (max-width: 359px) {
      .iclub-visual-v3 #view-home #home-study-list {
        grid-template-columns: 1fr;
      }
    }

    @media (hover: hover) and (pointer: fine) {
      .iclub-visual-v3 #view-home .home-competitive-card:hover,
      .iclub-visual-v3 #view-home .home-pinned-tile:hover,
      .iclub-visual-v3 #courses-all-subjects .catalog-card:hover {
        box-shadow: var(--v3-premium-shadow-hover);
      }
    }
    ''').strip() + '\n'
CSS.write_text(css, encoding='utf-8')

# Permanently include the new regression in the premium gate after the staged change is proven.
wf = WORKFLOW.read_text(encoding='utf-8')
if 'visual_v3_home_study_regression.js' not in wf:
    wf = wf.replace(
        "      - '.github/scripts/visual_v3_subject_hub_architecture_regression.js'\n",
        "      - '.github/scripts/visual_v3_subject_hub_architecture_regression.js'\n      - '.github/scripts/visual_v3_home_study_regression.js'\n"
    )
    wf = wf.replace(
        "          test -f .github/scripts/visual_v3_subject_hub_architecture_regression.js\n",
        "          test -f .github/scripts/visual_v3_subject_hub_architecture_regression.js\n          test -f .github/scripts/visual_v3_home_study_regression.js\n",
        1
    )
    wf = wf.replace(
        "          node --check .github/scripts/visual_v3_subject_hub_architecture_regression.js\n",
        "          node --check .github/scripts/visual_v3_subject_hub_architecture_regression.js\n          node --check .github/scripts/visual_v3_home_study_regression.js\n",
        1
    )
    wf = wf.replace(
        "          grep -q 'PREMIUM SUBJECT HUB LEARNING MODES v3.4' visual/iclub-premium-v3.css\n",
        "          grep -q 'PREMIUM SUBJECT HUB LEARNING MODES v3.4' visual/iclub-premium-v3.css\n          grep -q 'PREMIUM HOME STUDY ARCHITECTURE v3.5' visual/iclub-premium-v3.css\n",
        1
    )
    wf = wf.replace(
        "          node .github/scripts/visual_v3_subject_hub_architecture_regression.js\n",
        "          node .github/scripts/visual_v3_subject_hub_architecture_regression.js\n          node .github/scripts/visual_v3_home_study_regression.js\n",
        1
    )
WORKFLOW.write_text(wf, encoding='utf-8')

# Normalize only touched product/gate files so git diff --check is deterministic.
for path in [APP, I18N, INDEX, CSS, WORKFLOW]:
    text = path.read_text(encoding='utf-8')
    path.write_text('\n'.join(line.rstrip() for line in text.splitlines()) + '\n', encoding='utf-8')
