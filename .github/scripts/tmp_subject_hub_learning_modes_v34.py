from pathlib import Path
from textwrap import dedent

INDEX = Path('index.html')
I18N = Path('i18n.js')
CSS = Path('visual/iclub-premium-v3.css')
ARCH_TEST = Path('.github/scripts/visual_v3_subject_hub_architecture_regression.js')
PREMIUM_TEST = Path('.github/scripts/visual_v3_premium_regression.js')

# -------------------------
# index.html
# -------------------------
html = INDEX.read_text(encoding='utf-8')
if 'subject-hub-primary-modes' not in html:
    start = html.index('<div id="subject-hub-exam-prep-entry"')
    tabs_start = html.index('  <div class="subject-hub-tabs" role="tablist" aria-label="Subject hub tabs">', start)
    tabs_end = html.index('</div>', tabs_start) + len('</div>')

    new_primary = dedent('''
    <div class="subject-hub-primary-modes" aria-label="Preparation">
      <div class="subject-hub-primary-label" data-i18n="hub_preparation_section">Подготовка</div>

      <div id="subject-hub-exam-prep-entry" class="subject-hub-list exam-prep-host-entry exam-prep-feature-card subject-mode-card subject-mode-card-exam" hidden aria-hidden="true">
        <button class="exam-prep-feature-button subject-mode-card-button" type="button" data-action="open-exam-prep" aria-describedby="subject-hub-exam-prep-sub">
          <span class="exam-prep-feature-topline subject-mode-topline">
            <span class="subject-mode-icon subject-mode-icon-exam" aria-hidden="true">
              <svg viewBox="0 0 24 24"><path d="M5 4h14v16H5z"/><path d="M8 8h8"/><path d="M8 12h5"/><path d="M15 15l1.2 1.2L19 13.5"/></svg>
            </span>
            <span id="subject-hub-exam-prep-badge" class="exam-prep-feature-badge subject-mode-status subject-mode-status-exam">Cambridge AS · Mathematics</span>
            <span class="exam-prep-feature-arrow subject-mode-arrow" aria-hidden="true"><svg viewBox="0 0 24 24" width="18" height="18"><path d="M9 6l6 6-6 6"/></svg></span>
          </span>
          <span id="subject-hub-exam-prep-title" class="exam-prep-feature-title subject-mode-title">Exam Prep</span>
          <span id="subject-hub-exam-prep-sub" class="exam-prep-feature-description subject-mode-description">Paper 1 and Paper 5 preparation</span>
          <span class="exam-prep-feature-components" aria-label="Exam components">
            <span class="exam-prep-feature-component"><strong>P1</strong><span id="subject-hub-exam-prep-p1">Pure Mathematics 1 · 45 skills</span></span>
            <span class="exam-prep-feature-component"><strong>P5</strong><span id="subject-hub-exam-prep-p5">Probability &amp; Statistics 1 · 36 skills</span></span>
          </span>
          <span class="exam-prep-feature-footer">
            <span id="subject-hub-exam-prep-note" class="exam-prep-feature-note">Practice and Tours history stays unchanged.</span>
            <span id="subject-hub-exam-prep-cta" class="exam-prep-feature-cta">Open Exam Prep</span>
          </span>
        </button>
      </div>

      <button class="subject-mode-card subject-mode-card-button subject-mode-card-practice" type="button" data-action="open-practice">
        <span class="subject-mode-topline">
          <span class="subject-mode-icon subject-mode-icon-practice" aria-hidden="true">
            <svg viewBox="0 0 24 24"><path d="M6 4h12v16H6z"/><path d="M9 8h6"/><path d="M9 12h6"/><path d="M9 16h3"/></svg>
          </span>
          <span class="subject-mode-status subject-mode-status-practice" data-i18n="hub_practice_status">Всегда доступна</span>
          <span class="subject-mode-arrow" aria-hidden="true"><svg viewBox="0 0 24 24"><path d="M9 6l6 6-6 6"/></svg></span>
        </span>
        <span class="subject-mode-title" data-i18n="practice">Практика</span>
        <span class="subject-mode-description" data-i18n="hub_practice_sub">Отрабатывайте темы в своём темпе и возвращайтесь к ошибкам.</span>
      </button>

      <button class="subject-mode-card subject-mode-card-button subject-mode-card-tours" type="button" data-action="open-tours">
        <span class="subject-mode-topline">
          <span class="subject-mode-icon subject-mode-icon-tours" aria-hidden="true">
            <svg viewBox="0 0 24 24"><path d="M8 4h8v4a4 4 0 0 1-8 0z"/><path d="M8 6H5v1a4 4 0 0 0 4 4"/><path d="M16 6h3v1a4 4 0 0 1-4 4"/><path d="M12 12v4"/><path d="M8 20h8"/><path d="M9 16h6v4H9z"/></svg>
          </span>
          <span class="subject-mode-status subject-mode-status-tours" data-i18n="hub_tours_status">По расписанию</span>
          <span class="subject-mode-arrow" aria-hidden="true"><svg viewBox="0 0 24 24"><path d="M9 6l6 6-6 6"/></svg></span>
        </span>
        <span class="subject-mode-title" data-i18n="tours_title">Туры</span>
        <span class="subject-mode-description" data-i18n="hub_tours_sub">Проверяйте знания в соревновательном формате, когда тур открыт.</span>
        <span class="subject-mode-state muted small" data-i18n="tours_active_and_completed">Активные и прошедшие</span>
      </button>
    </div>

    <div id="exam-prep-host-root" class="exam-prep-host-root" hidden aria-hidden="true"></div>
    ''').strip()

    html = html[:start] + new_primary + html[tabs_end:]

    actions_marker = '<div class="subject-hub-list subject-hub-actions">'
    actions_pos = html.index(actions_marker, html.index('id="courses-subject-hub"'))
    html = html[:actions_pos] + dedent('''
    <div class="section subject-hub-materials-section">
      <div class="h2" data-i18n="hub_materials_section">Материалы</div>
    </div>

    ''') + html[actions_pos:]

    rec_marker = '  <button class="settings-nav" type="button" data-action="open-my-recommendations">'
    rec_pos = html.index(rec_marker, actions_pos)
    resources_button = dedent('''
      <button class="settings-nav" type="button" data-action="open-books">
        <span class="settings-nav-ico"><svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M4 5.5A2.5 2.5 0 0 1 6.5 3H11v16H6.5A2.5 2.5 0 0 0 4 21z"/><path d="M20 5.5A2.5 2.5 0 0 0 17.5 3H13v16h4.5A2.5 2.5 0 0 1 20 21z"/></svg></span>
        <span class="settings-nav-text">
          <span class="settings-nav-title" data-i18n="resources_title">Ресурсы</span>
          <span class="settings-nav-sub muted small" data-i18n="hub_resources_sub">Книги и материалы по предмету</span>
        </span>
        <span class="settings-nav-arrow">›</span>
      </button>

    ''')
    html = html[:rec_pos] + resources_button + html[rec_pos:]

    html = html.replace(
        '<div class="section" style="margin-top:14px">\n    <div class="h2" data-i18n="hub_system_section">Системные</div>',
        '<div class="section subject-hub-system-section" style="margin-top:14px">\n    <div class="h2" data-i18n="hub_system_section">Системные</div>',
        1
    )

INDEX.write_text(html, encoding='utf-8')

# -------------------------
# i18n.js
# -------------------------
i18n = I18N.read_text(encoding='utf-8')
insertions = [
    (
        '      hub_video_lessons_title: "Видео-уроки",',
        dedent('''
              hub_preparation_section: "Подготовка",
              hub_practice_status: "Всегда доступна",
              hub_practice_sub: "Отрабатывайте темы в своём темпе и возвращайтесь к ошибкам.",
              hub_tours_status: "По расписанию",
              hub_tours_sub: "Проверяйте знания в соревновательном формате, когда тур открыт.",
              hub_materials_section: "Материалы",
              hub_resources_sub: "Книги и материалы по предмету",
        ''').rstrip()
    ),
    (
        '      hub_video_lessons_title: "Video darslar",',
        dedent('''
              hub_preparation_section: "Tayyorgarlik",
              hub_practice_status: "Har doim ochiq",
              hub_practice_sub: "Mavzularni o‘z tempingizda mashq qiling va xatolarga qayting.",
              hub_tours_status: "Jadval bo‘yicha",
              hub_tours_sub: "Tur ochilganda bilimni musobaqa formatida tekshiring.",
              hub_materials_section: "Materiallar",
              hub_resources_sub: "Fan bo‘yicha kitoblar va materiallar",
        ''').rstrip()
    ),
    (
        '      hub_video_lessons_title: "Video lessons",',
        dedent('''
              hub_preparation_section: "Preparation",
              hub_practice_status: "Always available",
              hub_practice_sub: "Practice topics at your own pace and return to mistakes.",
              hub_tours_status: "Scheduled",
              hub_tours_sub: "Test your knowledge in competitive mode when a Tour is open.",
              hub_materials_section: "Materials",
              hub_resources_sub: "Books and subject resources",
        ''').rstrip()
    ),
]
if 'hub_preparation_section' not in i18n:
    for anchor, block in insertions:
        if anchor not in i18n:
            raise SystemExit(f'i18n anchor missing: {anchor}')
        i18n = i18n.replace(anchor, block + '\n\n' + anchor, 1)
I18N.write_text(i18n, encoding='utf-8')

# -------------------------
# Premium CSS v3.4
# -------------------------
css = CSS.read_text(encoding='utf-8')
marker = '/* ===== PREMIUM SUBJECT HUB LEARNING MODES v3.4 ===== */'
if marker not in css:
    css += '\n\n' + dedent('''
    /* ===== PREMIUM SUBJECT HUB LEARNING MODES v3.4 ===== */
    /* Practice, Tours and Exam Prep are peer preparation products with different access properties. */
    .iclub-visual-v3 #courses-subject-hub > .subject-hub-primary-modes {
      order: 20;
      display: grid;
      grid-template-columns: 1fr;
      gap: 10px;
      margin: 0 0 14px;
    }

    .iclub-visual-v3 #courses-subject-hub .subject-hub-primary-label {
      margin: 2px 2px -1px;
      color: var(--v3-muted);
      font-size: 10px;
      line-height: 1.2;
      font-weight: 800;
      letter-spacing: .07em;
      text-transform: uppercase;
    }

    .iclub-visual-v3 #courses-subject-hub .subject-mode-card {
      width: 100%;
      min-width: 0;
      overflow: hidden;
      border: 1px solid var(--v3-border);
      border-radius: var(--v3-radius-lg);
      background: #FFFFFF;
      color: var(--v3-text);
      box-shadow: var(--v3-premium-shadow);
    }

    .iclub-visual-v3 #courses-subject-hub .subject-mode-card-button {
      width: 100%;
      display: grid;
      gap: 7px;
      min-height: 112px;
      padding: 13px 14px;
      border: 0;
      background: transparent;
      color: inherit;
      text-align: left;
      font: inherit;
      cursor: pointer;
    }

    .iclub-visual-v3 #courses-subject-hub button.subject-mode-card-button {
      border: 1px solid var(--v3-border);
    }

    .iclub-visual-v3 #courses-subject-hub .subject-mode-card-practice {
      border-color: #D8E2F7;
      background: linear-gradient(135deg, #FFFFFF 0%, #F8FAFF 100%);
    }

    .iclub-visual-v3 #courses-subject-hub .subject-mode-card-tours {
      border-color: #E8DEC8;
      background: linear-gradient(135deg, #FFFFFF 0%, #FFFCF6 100%);
    }

    .iclub-visual-v3 #courses-subject-hub .subject-mode-card-exam {
      margin: 0;
      border-color: #C9D8FC;
      background: linear-gradient(135deg, #FFFFFF 0%, #F2F6FF 100%);
      box-shadow: var(--v3-premium-shadow);
    }

    .iclub-visual-v3 #courses-subject-hub .subject-mode-topline,
    .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-topline {
      display: grid;
      grid-template-columns: auto minmax(0, 1fr) auto;
      gap: 8px;
      align-items: center;
      justify-content: initial;
    }

    .iclub-visual-v3 #courses-subject-hub .subject-mode-icon {
      width: 34px;
      height: 34px;
      display: grid;
      place-items: center;
      border: 1px solid #D9E3F8;
      border-radius: var(--v3-radius-sm);
      background: #F0F5FF;
      color: var(--v3-primary);
    }

    .iclub-visual-v3 #courses-subject-hub .subject-mode-icon-tours {
      border-color: #EBDDBF;
      background: #FFF7E8;
      color: #91601B;
    }

    .iclub-visual-v3 #courses-subject-hub .subject-mode-icon svg {
      width: 18px;
      height: 18px;
      display: block;
      fill: none;
      stroke: currentColor;
      stroke-width: 1.7;
      stroke-linecap: round;
      stroke-linejoin: round;
    }

    .iclub-visual-v3 #courses-subject-hub .subject-mode-status {
      justify-self: start;
      min-width: 0;
      max-width: 100%;
      padding: 4px 7px;
      border: 1px solid transparent;
      border-radius: 999px;
      font-size: 9.5px;
      line-height: 1.2;
      font-weight: 800;
      white-space: normal;
    }

    .iclub-visual-v3 #courses-subject-hub .subject-mode-status-practice {
      border-color: #CFE9DC;
      background: #EEF9F3;
      color: #287451;
    }

    .iclub-visual-v3 #courses-subject-hub .subject-mode-status-tours {
      border-color: #EADAB7;
      background: #FFF7E7;
      color: #8A5B17;
    }

    .iclub-visual-v3 #courses-subject-hub .subject-mode-status-exam {
      border-color: #D4DFFD;
      background: #EEF4FF;
      color: var(--v3-primary);
      text-transform: none;
      letter-spacing: 0;
    }

    .iclub-visual-v3 #courses-subject-hub .subject-mode-arrow,
    .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-arrow {
      width: 28px;
      height: 28px;
      display: grid;
      place-items: center;
      justify-self: end;
      border: 1px solid #E0E6EF;
      border-radius: 999px;
      background: rgba(255,255,255,.86);
      color: #7C899C;
    }

    .iclub-visual-v3 #courses-subject-hub .subject-mode-arrow svg,
    .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-arrow svg {
      width: 16px;
      height: 16px;
      fill: none;
      stroke: currentColor;
      stroke-width: 1.8;
      stroke-linecap: round;
      stroke-linejoin: round;
    }

    .iclub-visual-v3 #courses-subject-hub .subject-mode-title,
    .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-title {
      color: var(--v3-text);
      font-size: 17px;
      line-height: 1.18;
      font-weight: 810;
      letter-spacing: -0.018em;
    }

    .iclub-visual-v3 #courses-subject-hub .subject-mode-description,
    .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-description {
      max-width: none;
      color: #667085;
      font-size: 11.5px;
      line-height: 1.45;
      font-weight: 500;
    }

    .iclub-visual-v3 #courses-subject-hub .subject-mode-state {
      margin-top: 1px;
      color: #7B8798;
      font-size: 10px;
      line-height: 1.35;
      font-weight: 650;
    }

    .iclub-visual-v3 #courses-subject-hub .subject-mode-card-tours.is-disabled {
      opacity: .82;
      box-shadow: none;
    }

    .iclub-visual-v3 #courses-subject-hub .subject-mode-card-tours.is-disabled .subject-mode-status-tours {
      border-color: #E2E8F0;
      background: #F7F9FC;
      color: #667085;
    }

    .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-button {
      gap: 7px;
      min-height: 126px;
      padding: 13px 14px;
    }

    .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-components {
      display: flex;
      flex-wrap: wrap;
      gap: 6px;
      margin-top: 1px;
      overflow: visible;
      border: 0;
      border-radius: 0;
      background: transparent;
    }

    .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-component,
    .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-component + .exam-prep-feature-component {
      display: inline-flex;
      align-items: center;
      flex: 0 1 auto;
      gap: 5px;
      min-height: 29px;
      padding: 5px 7px;
      border: 1px solid #DCE5FA;
      border-radius: 999px;
      background: rgba(255,255,255,.78);
    }

    .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-component strong {
      flex: 0 0 auto;
      min-width: auto;
      padding: 0;
      border-radius: 0;
      background: transparent;
      color: var(--v3-primary);
      font-size: 9.5px;
    }

    .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-component span {
      min-width: 0;
      color: #536178;
      font-size: 9.5px;
      line-height: 1.25;
      font-weight: 650;
    }

    .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-footer {
      justify-content: flex-end;
      margin-top: 0;
      padding-top: 1px;
      border-top: 0;
    }

    .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-note {
      display: none;
    }

    .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-cta {
      min-height: auto;
      padding: 0;
      border-radius: 0;
      background: transparent;
      color: var(--v3-primary);
      font-size: 10px;
      font-weight: 800;
    }

    .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-cta::after {
      content: none;
    }

    .iclub-visual-v3 #courses-subject-hub > .subject-hub-materials-section {
      order: 30;
      margin: 2px 0 8px !important;
    }

    .iclub-visual-v3 #courses-subject-hub > .subject-hub-materials-section .h2,
    .iclub-visual-v3 #courses-subject-hub > .subject-hub-system-section .h2 {
      color: var(--v3-muted);
      font-size: 10px;
      font-weight: 800;
      letter-spacing: .07em;
      text-transform: uppercase;
    }

    .iclub-visual-v3 #courses-subject-hub > .subject-hub-list.subject-hub-actions {
      order: 40;
    }

    .iclub-visual-v3 #courses-subject-hub > .subject-hub-system-section {
      order: 60;
      margin-top: 18px !important;
    }

    @media (hover:hover) {
      .iclub-visual-v3 #courses-subject-hub .subject-mode-card-button:hover {
        border-color: #C9D7F8;
        box-shadow: var(--v3-premium-shadow-hover);
      }

      .iclub-visual-v3 #subject-hub-exam-prep-entry .exam-prep-feature-button:hover {
        background: rgba(255,255,255,.22);
      }
    }

    .iclub-visual-v3 #courses-subject-hub .subject-mode-card-button:active {
      transform: none;
      box-shadow: inset 0 0 0 1px rgba(36,87,214,.06);
    }

    @media (min-width: 620px) {
      .iclub-visual-v3 #courses-subject-hub > .subject-hub-primary-modes {
        grid-template-columns: repeat(2, minmax(0, 1fr));
      }

      .iclub-visual-v3 #courses-subject-hub > .subject-hub-primary-modes > .subject-hub-primary-label,
      .iclub-visual-v3 #courses-subject-hub > .subject-hub-primary-modes > #subject-hub-exam-prep-entry {
        grid-column: 1 / -1;
      }
    }
    ''').strip() + '\n'
CSS.write_text(css, encoding='utf-8')

# -------------------------
# Premium regression: stop querying removed hub tabs.
# -------------------------
premium = PREMIUM_TEST.read_text(encoding='utf-8')
premium = premium.replace(
    "    tabsColumns: getComputedStyle(document.querySelector('#courses-subject-hub .subject-hub-tabs')).gridTemplateColumns,",
    "    primaryColumns: getComputedStyle(document.querySelector('#courses-subject-hub .subject-hub-primary-modes')).gridTemplateColumns,"
)
PREMIUM_TEST.write_text(premium, encoding='utf-8')

# -------------------------
# Subject Hub architecture regression v3.4
# -------------------------
ARCH_TEST.write_text(dedent(r'''
const fs = require('fs');
const { chromium } = require('playwright');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const html = fs.readFileSync('index.html', 'utf8');
const css = fs.readFileSync('visual/iclub-premium-v3.css', 'utf8');
const i18n = fs.readFileSync('i18n.js', 'utf8');

for (const token of [
  'PREMIUM SUBJECT HUB LEARNING MODES v3.4',
  '#courses-subject-hub > .subject-hub-primary-modes',
  '.subject-mode-card-practice',
  '.subject-mode-card-tours',
  '.subject-mode-status-practice',
  '.subject-mode-status-tours',
  '#courses-subject-hub > .subject-hub-panels'
]) {
  assert(css.includes(token), `Subject Hub learning-mode CSS missing ${token}`);
}

for (const forbidden of [/localStorage/i, /sessionStorage/i, /supabase/i, /\.rpc\s*\(/, /\.from\s*\(/, /operational_stage\s*=/, /innerHTML\s*=/]) {
  assert(!forbidden.test(css), `Subject Hub architecture layer is not presentation-only: ${forbidden}`);
}

const hubMatch = html.match(/<section id="courses-subject-hub"[\s\S]*?<\/section>/);
assert(hubMatch, 'Subject Hub markup missing');
const hubHtml = hubMatch[0];
assert(!hubHtml.includes('class="subject-hub-tabs"'), 'Legacy Content/Practice/Tours/Resources tab strip must be removed from Subject Hub');
assert((hubHtml.match(/data-action="open-lessons"/g) || []).length === 1, 'Video lessons must have exactly one Subject Hub entry');
for (const action of ['open-lessons', 'open-practice', 'open-tours', 'open-books', 'open-subject-mentor', 'open-exam-prep']) {
  assert(hubHtml.includes(`data-action="${action}"`), `Subject Hub action contract missing: ${action}`);
}
for (const key of ['hub_preparation_section', 'hub_practice_status', 'hub_practice_sub', 'hub_tours_status', 'hub_tours_sub', 'hub_materials_section', 'hub_resources_sub']) {
  assert((i18n.match(new RegExp(`${key}:`, 'g')) || []).length === 3, `i18n key ${key} must exist in RU/UZ/EN`);
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 }, javaScriptEnabled: false });
  const url = process.env.VISUAL_V3_PREMIUM_URL || 'http://127.0.0.1:4173/index.html';
  await page.goto(url, { waitUntil: 'domcontentloaded' });

  await page.evaluate(() => {
    document.querySelectorAll('.view').forEach(node => node.classList.remove('is-active'));
    const courses = document.getElementById('view-courses');
    courses.classList.add('is-active');
    document.querySelectorAll('#courses-stack .stack-screen').forEach(node => {
      node.classList.remove('is-active');
      node.hidden = true;
      node.setAttribute('aria-hidden', 'true');
    });
    const hub = document.getElementById('courses-subject-hub');
    hub.hidden = false;
    hub.removeAttribute('aria-hidden');
    hub.classList.add('is-active', 'exam-prep-available');
    const entry = document.getElementById('subject-hub-exam-prep-entry');
    entry.hidden = false;
    entry.setAttribute('aria-hidden', 'false');
  });

  let state = await page.evaluate(() => {
    const hub = document.getElementById('courses-subject-hub');
    const head = hub.querySelector('.subject-hub-head');
    const panels = hub.querySelector('.subject-hub-panels');
    const primary = hub.querySelector('.subject-hub-primary-modes');
    const entry = document.getElementById('subject-hub-exam-prep-entry');
    const practice = hub.querySelector('.subject-mode-card-practice');
    const tours = hub.querySelector('.subject-mode-card-tours');
    const practiceStatus = practice.querySelector('.subject-mode-status-practice');
    const toursStatus = tours.querySelector('.subject-mode-status-tours');
    const materials = hub.querySelector('.subject-hub-materials-section');
    const actions = hub.querySelector('.subject-hub-actions');
    const system = hub.querySelector('.subject-hub-system-section');
    const bottom = hub.querySelector('.subject-hub-bottom');
    return {
      display: getComputedStyle(hub).display,
      orders: {
        head: Number(getComputedStyle(head).order),
        panels: Number(getComputedStyle(panels).order),
        primary: Number(getComputedStyle(primary).order),
        materials: Number(getComputedStyle(materials).order),
        actions: Number(getComputedStyle(actions).order),
        system: Number(getComputedStyle(system).order),
        bottom: Number(getComputedStyle(bottom).order)
      },
      primaryColumns: getComputedStyle(primary).gridTemplateColumns.split(' ').length,
      practiceHeight: practice.getBoundingClientRect().height,
      toursHeight: tours.getBoundingClientRect().height,
      practiceRadius: getComputedStyle(practice).borderRadius,
      toursRadius: getComputedStyle(tours).borderRadius,
      examRadius: getComputedStyle(entry).borderRadius,
      practiceStatusBackground: getComputedStyle(practiceStatus).backgroundColor,
      toursStatusBackground: getComputedStyle(toursStatus).backgroundColor,
      mentorBeforePrimary: panels.getBoundingClientRect().top < primary.getBoundingClientRect().top,
      materialsAfterPrimary: materials.getBoundingClientRect().top > primary.getBoundingClientRect().top,
      secondaryGroupBorder: getComputedStyle(actions).borderTopStyle,
      width: document.documentElement.scrollWidth,
      innerWidth: innerWidth
    };
  });

  assert(state.display === 'flex', `Subject Hub active layout must be flex, got ${state.display}`);
  assert(JSON.stringify(state.orders) === JSON.stringify({ head: 10, panels: 15, primary: 20, materials: 30, actions: 40, system: 60, bottom: 80 }), `Subject Hub hierarchy drift: ${JSON.stringify(state.orders)}`);
  assert(state.primaryColumns === 1, `Primary preparation products must be full-width on mobile, got ${state.primaryColumns} columns`);
  assert(state.practiceHeight >= 108 && state.toursHeight >= 108, `Practice/Tours lost primary visual weight: ${JSON.stringify(state)}`);
  assert(state.practiceRadius === state.toursRadius && state.practiceRadius === state.examRadius, `Preparation product family radius mismatch: ${JSON.stringify(state)}`);
  assert(state.practiceStatusBackground !== state.toursStatusBackground, 'Practice and Tours access properties must remain visually distinct');
  assert(state.mentorBeforePrimary === true, 'Mentor card must stay directly after the subject header');
  assert(state.materialsAfterPrimary === true, 'Materials must remain secondary to Exam Prep / Practice / Tours');
  assert(state.secondaryGroupBorder === 'solid', `Materials actions must read as one grouped list, border=${state.secondaryGroupBorder}`);
  assert(state.width <= state.innerWidth, `Subject Hub mobile overflow: ${JSON.stringify(state)}`);

  await page.evaluate(() => {
    const hub = document.getElementById('courses-subject-hub');
    const root = document.getElementById('exam-prep-host-root');
    root.hidden = false;
    root.setAttribute('aria-hidden', 'false');
    hub.classList.add('exam-prep-host-open');
  });

  state = await page.evaluate(() => ({
    primary: getComputedStyle(document.querySelector('#courses-subject-hub .subject-hub-primary-modes')).display,
    head: getComputedStyle(document.querySelector('#courses-subject-hub .subject-hub-head')).display,
    root: getComputedStyle(document.getElementById('exam-prep-host-root')).display,
    width: document.documentElement.scrollWidth,
    innerWidth: innerWidth
  }));
  assert(state.primary === 'none' && state.head === 'none', `Exam Prep open state must hide Subject Hub siblings: ${JSON.stringify(state)}`);
  assert(state.root !== 'none', 'Exam Prep host root must remain visible when open');
  assert(state.width <= state.innerWidth, `Exam Prep open overflow after Subject Hub learning-mode pass: ${JSON.stringify(state)}`);

  await page.evaluate(() => {
    const hub = document.getElementById('courses-subject-hub');
    hub.classList.remove('exam-prep-host-open', 'is-active');
    hub.hidden = true;
  });
  state = await page.evaluate(() => getComputedStyle(document.getElementById('courses-subject-hub')).display);
  assert(state === 'none', `Inactive/hidden Subject Hub leaked into layout: ${state}`);

  await browser.close();
  console.log('Visual v3 Subject Hub learning modes regression: GREEN');
})().catch(error => {
  console.error(error);
  process.exit(1);
});
''').lstrip(), encoding='utf-8')
