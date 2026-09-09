from pathlib import Path


def replace_once(source: str, old: str, new: str, label: str) -> str:
    count = source.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected exactly 1 match, found {count}")
    return source.replace(old, new, 1)


index = Path("index.html")
text = index.read_text(encoding="utf-8")
text = replace_once(
    text,
    '<link rel="stylesheet" href="style.css?v=support1" />',
    '<link rel="stylesheet" href="style.css?v=support1" />\n  <link rel="stylesheet" href="visual/iclub-visual-v3.css?v=v3foundation1" />',
    "Visual v3 stylesheet anchor",
)
text = replace_once(text, "<body>", '<body class="iclub-visual-v3">', "Visual v3 body class")
text = replace_once(
    text,
    '<span class="icon">←</span>',
    '<svg class="v3-shell-icon" viewBox="0 0 24 24" aria-hidden="true"><path d="M15 18l-6-6 6-6"/></svg>',
    "Topbar back icon",
)
text = replace_once(
    text,
    '<span class="icon">🔔</span>',
    '<svg class="v3-shell-icon" viewBox="0 0 24 24" aria-hidden="true"><path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9"/><path d="M10 21h4"/></svg>',
    "Topbar notifications icon",
)
text = replace_once(
    text,
    '<span class="icon">⋯</span>',
    '<svg class="v3-shell-icon" viewBox="0 0 24 24" aria-hidden="true"><circle cx="5" cy="12" r="1"/><circle cx="12" cy="12" r="1"/><circle cx="19" cy="12" r="1"/></svg>',
    "Topbar action icon",
)
text = replace_once(
    text,
    '<span class="tab-ico">⌂</span>',
    '<span class="tab-ico" aria-hidden="true"><svg class="v3-shell-nav-icon" viewBox="0 0 24 24"><path d="M3 10.5 12 3l9 7.5"/><path d="M5.5 9.5V21h13V9.5"/><path d="M9.5 21v-6h5v6"/></svg></span>',
    "Home navigation icon",
)
text = replace_once(
    text,
    '<span class="tab-ico">▦</span>',
    '<span class="tab-ico" aria-hidden="true"><svg class="v3-shell-nav-icon" viewBox="0 0 24 24"><path d="M4 5.5A2.5 2.5 0 0 1 6.5 3H20v16H6.5A2.5 2.5 0 0 0 4 21.5z"/><path d="M4 5.5v16"/></svg></span>',
    "Study navigation icon",
)
text = replace_once(
    text,
    '<span class="tab-ico">▤</span>',
    '<span class="tab-ico" aria-hidden="true"><svg class="v3-shell-nav-icon" viewBox="0 0 24 24"><path d="M5 20v-8"/><path d="M12 20V4"/><path d="M19 20v-12"/><path d="M3 20h18"/></svg></span>',
    "Ratings navigation icon",
)
old_profile = '''<span class="tab-ico" aria-hidden="true">
    <svg viewBox="0 0 24 24" width="18" height="18" fill="none">
      <path d="M12 12.2c2.55 0 4.62-2.07 4.62-4.62S14.55 2.96 12 2.96 7.38 5.03 7.38 7.58 9.45 12.2 12 12.2Z" fill="currentColor"/>
      <path d="M4.6 20.7c.9-3.7 4.3-6.1 7.4-6.1s6.5 2.4 7.4 6.1c.1.4-.2.8-.6.8H5.2c-.4 0-.7-.4-.6-.8Z" fill="currentColor"/>
    </svg>
  </span>'''
new_profile = '<span class="tab-ico" aria-hidden="true"><svg class="v3-shell-nav-icon" viewBox="0 0 24 24"><circle cx="12" cy="8" r="4"/><path d="M4.5 21a7.5 7.5 0 0 1 15 0"/></svg></span>'
text = replace_once(text, old_profile, new_profile, "Profile navigation icon")
text = replace_once(
    text,
    '<span class="tab-txt" data-i18n="tab_courses">Courses</span>',
    '<span class="tab-txt" data-i18n="tab_study">Study</span>',
    "Study navigation label",
)
index.write_text(text, encoding="utf-8")

i18n = Path("i18n.js")
t = i18n.read_text(encoding="utf-8")
for old, new, label in [
    ('    tab_home: "Главная",\n', '    tab_home: "Главная",\n    tab_study: "Учёба",\n', "RU Study"),
    ('    tab_home: "Bosh sahifa",\n', '    tab_home: "Bosh sahifa",\n    tab_study: "O‘qish",\n', "UZ Study"),
    ('    tab_home: "Home",\n', '    tab_home: "Home",\n    tab_study: "Study",\n', "EN Study"),
]:
    t = replace_once(t, old, new, label)
i18n.write_text(t, encoding="utf-8")

css_path = Path("visual/iclub-visual-v3.css")
css = css_path.read_text(encoding="utf-8")
if "LIVE FOUNDATION v3" in css:
    raise SystemExit("Visual v3 live layer already exists")

css += r'''

/* ===== LIVE FOUNDATION v3 =====
   Additive shell/theme layer. No route, state, persistence or data selectors. */
body.iclub-visual-v3 {
  --primary: var(--v3-primary);
  --primary-2: var(--v3-brand);
  --bg: var(--v3-bg);
  --card: var(--v3-card);
  --text: var(--v3-text);
  --muted: var(--v3-muted);
  --border: var(--v3-border);
  --shadow: var(--v3-shadow);
  --shadow-sm: var(--v3-shadow-soft);
  --radius: var(--v3-radius-lg);
  --radius-sm: var(--v3-radius-sm);
  color: var(--v3-text);
  background: var(--v3-bg);
}

.iclub-visual-v3 .app,
.iclub-visual-v3 .main { background: var(--v3-bg); }

.iclub-visual-v3 .topbar {
  min-height: 56px;
  padding: calc(7px + var(--safe-top)) 8px 7px;
  background: rgba(247, 249, 254, 0.96);
  border-bottom: 1px solid var(--v3-border);
  box-shadow: none;
  backdrop-filter: blur(12px);
}

.iclub-visual-v3 .topbar-logo {
  width: 32px;
  height: 32px;
  border-radius: var(--v3-radius-md);
  box-shadow: none;
}

.iclub-visual-v3 .icon-btn {
  width: 36px;
  height: 36px;
  border: 1px solid var(--v3-border);
  border-radius: var(--v3-radius-md);
  background: var(--v3-card);
  color: var(--v3-text);
  box-shadow: none;
}

.iclub-visual-v3 .v3-shell-icon,
.iclub-visual-v3 .v3-shell-nav-icon {
  width: 20px;
  height: 20px;
  display: block;
  fill: none;
  stroke: currentColor;
  stroke-width: 1.8;
  stroke-linecap: round;
  stroke-linejoin: round;
}

.iclub-visual-v3 .topbar-title .title {
  font-size: 15px;
  font-weight: 760;
  letter-spacing: -0.012em;
}
.iclub-visual-v3 .topbar-title .subtitle { font-size: 11px; color: var(--v3-muted); }
.iclub-visual-v3 .h1 { font-size: 22px; font-weight: 790; letter-spacing: -0.022em; }
.iclub-visual-v3 .section-title,
.iclub-visual-v3 .card-title { color: var(--v3-text); font-weight: 760; letter-spacing: -0.008em; }
.iclub-visual-v3 .muted { color: var(--v3-muted); }

.iclub-visual-v3 .card,
.iclub-visual-v3 .card-btn {
  border: 1px solid var(--v3-border);
  border-radius: var(--v3-radius-lg);
  background: var(--v3-card);
  box-shadow: var(--v3-shadow-soft);
}

.iclub-visual-v3 .list-item,
.iclub-visual-v3 .settings-nav,
.iclub-visual-v3 .profile-row,
.iclub-visual-v3 .panel-card,
.iclub-visual-v3 .overview-card {
  border-color: var(--v3-border);
  border-radius: var(--v3-radius-md);
  box-shadow: none;
}

.iclub-visual-v3 .input,
.iclub-visual-v3 textarea.input,
.iclub-visual-v3 select.input {
  border: 1px solid var(--v3-border);
  border-radius: var(--v3-radius-md);
  background: var(--v3-card);
  color: var(--v3-text);
  box-shadow: none;
}
.iclub-visual-v3 .input:focus,
.iclub-visual-v3 textarea.input:focus,
.iclub-visual-v3 select.input:focus {
  border-color: var(--v3-primary);
  box-shadow: 0 0 0 3px rgba(36, 87, 214, 0.10);
}

.iclub-visual-v3 .btn { min-height: 40px; border-radius: var(--v3-radius-md); box-shadow: none; }
.iclub-visual-v3 .btn.primary {
  border-color: var(--v3-primary);
  background: var(--v3-primary);
  color: #FFFFFF;
  box-shadow: none;
}

.iclub-visual-v3 .tabbar {
  grid-template-columns: repeat(4, minmax(0, 1fr));
  min-height: 64px;
  padding: 7px 8px calc(8px + var(--safe-bottom));
  background: rgba(255, 255, 255, 0.97);
  border-top: 1px solid var(--v3-border);
  box-shadow: 0 -4px 18px rgba(15, 23, 42, 0.035);
  backdrop-filter: blur(14px);
}
.iclub-visual-v3 .tab {
  min-width: 0;
  gap: 3px;
  border-radius: var(--v3-radius-sm);
  color: var(--v3-muted);
  background: transparent;
}
.iclub-visual-v3 .tab.is-active { color: var(--v3-primary); background: var(--v3-primary-soft); }
.iclub-visual-v3 .tab-ico {
  width: 20px;
  height: 20px;
  display: grid;
  place-items: center;
  color: currentColor;
  font-size: 0;
}
.iclub-visual-v3 .tab-txt { font-size: 10px; font-weight: 680; line-height: 1.15; }
.iclub-visual-v3 .chip-btn,
.iclub-visual-v3 .hub-tab,
.iclub-visual-v3 .lang-btn { border-radius: var(--v3-radius-sm); box-shadow: none; }

.iclub-visual-v3 #exam-prep-host-root .ep-host-shell { gap: 12px; padding: 16px 0 28px; }
.iclub-visual-v3 #exam-prep-host-root .ep-host-title,
.iclub-visual-v3 #exam-prep-host-root .ep-placement-title { color: var(--v3-text); letter-spacing: -0.02em; }
.iclub-visual-v3 #exam-prep-host-root .ep-host-kicker { color: var(--v3-primary); opacity: 1; }

.iclub-visual-v3 #exam-prep-host-root .ep-host-component-card,
.iclub-visual-v3 #exam-prep-host-root .ep-host-invite-facts > div,
.iclub-visual-v3 #exam-prep-host-root .ep-host-consent-state,
.iclub-visual-v3 #exam-prep-host-root .ep-live-card,
.iclub-visual-v3 #exam-prep-host-root .ep-placement-card,
.iclub-visual-v3 #exam-prep-host-root .ep-views-card,
.iclub-visual-v3 #exam-prep-host-root .ep-materials-card,
.iclub-visual-v3 #exam-prep-host-root .ep-paper-card,
.iclub-visual-v3 #exam-prep-host-root .ep-map-card {
  border: 1px solid var(--v3-border);
  border-radius: var(--v3-radius-lg);
  background: var(--v3-card);
  box-shadow: var(--v3-shadow-soft);
}

.iclub-visual-v3 #exam-prep-host-root .ep-overview-stat,
.iclub-visual-v3 #exam-prep-host-root .ep-placement-stat,
.iclub-visual-v3 #exam-prep-host-root .ep-placement-note,
.iclub-visual-v3 #exam-prep-host-root .ep-materials-item,
.iclub-visual-v3 #exam-prep-host-root .ep-live-stat {
  border-color: var(--v3-border);
  border-radius: var(--v3-radius-md);
}

.iclub-visual-v3 #exam-prep-host-root .ep-host-btn,
.iclub-visual-v3 #exam-prep-host-root .ep-live-btn,
.iclub-visual-v3 #exam-prep-host-root .ep-placement-btn,
.iclub-visual-v3 #exam-prep-host-root .ep-views-btn,
.iclub-visual-v3 #exam-prep-host-root .ep-materials-btn,
.iclub-visual-v3 #exam-prep-host-root .ep-paper-btn,
.iclub-visual-v3 #exam-prep-host-root .ep-map-btn {
  min-height: 40px;
  border-radius: var(--v3-radius-md);
  border-color: var(--v3-border);
  box-shadow: none;
}
.iclub-visual-v3 #exam-prep-host-root .ep-host-btn-primary,
.iclub-visual-v3 #exam-prep-host-root .ep-live-btn.primary,
.iclub-visual-v3 #exam-prep-host-root .ep-placement-btn.primary {
  border-color: var(--v3-primary);
  background: var(--v3-primary);
  color: #FFFFFF;
  box-shadow: none;
}

@media (max-width: 430px) {
  .iclub-visual-v3 .main { padding-left: 12px; padding-right: 12px; }
}
'''
css_path.write_text(css, encoding="utf-8")

print("Visual Foundation v3 shell patch prepared")
