from pathlib import Path
import re

APP_PATH = Path("app.js")
INDEX_PATH = Path("index.html")
app = APP_PATH.read_text()
index = INDEX_PATH.read_text()

if "P0-14 HOST BRIDGE" in app or "subject-hub-exam-prep-entry" in index:
    raise SystemExit("P0-14 patch already present; refusing duplicate patch")


def sub_once(text, pattern, repl, label, flags=0):
    matches = list(re.finditer(pattern, text, flags))
    if len(matches) != 1:
        raise SystemExit(f"{label}: expected exactly 1 anchor, got {len(matches)}")
    return re.sub(pattern, repl, text, count=1, flags=flags)


app = sub_once(
    app,
    r"(async function renderSubjectHub\(\) \{\s*\n\s*const profile = loadProfile\(\);\s*\n\s*const subj = subjectByKey\(state\.courses\.subjectKey\);)",
    r'''\1

  // P0-14 HOST BRIDGE: isolated Exam Prep visibility/lifecycle sync; no domain logic here.
  try {
    Promise.resolve(window.iClubExamPrep?.syncSubjectHub?.({
      subjectKey: state.courses.subjectKey,
      language: currentLang()
    })).catch(() => null);
  } catch {}''',
    "renderSubjectHub",
)

app = sub_once(
    app,
    r'(\n\s*if \(action === "open-practice"\) \{)',
    r'''
      if (action === "open-exam-prep") {
        try {
          await window.iClubExamPrep?.open?.({
            subjectKey: state.courses.subjectKey,
            language: currentLang()
          });
        } catch {}
        return;
      }
\1''',
    "open-exam-prep action",
)

app = sub_once(
    app,
    r"(function canCoursesBack\(\) \{\s*\n)",
    r'''\1  // P0-14 HOST BRIDGE: Exam Prep owns its internal/transient back first.
  try { if (window.iClubExamPrep?.isOpen?.()) return true; } catch {}

''',
    "canCoursesBack",
)

app = sub_once(
    app,
    r"(function popCourses\(\) \{\s*\n\s*if \(state\.quizLock\) return;\s*\n)",
    r'''\1
  // P0-14 HOST BRIDGE: never write Exam Prep routes into the legacy Courses stack.
  try {
    if (window.iClubExamPrep?.isOpen?.() && window.iClubExamPrep?.back?.()) return;
  } catch {}

''',
    "popCourses",
)

app = sub_once(
    app,
    r'(function setTab\(tabName\) \{\s*\n\s*if \(!\["home", "courses", "ratings", "profile"\]\.includes\(tabName\)\) tabName = "home";\s*\n)',
    r'''\1  // P0-14 HOST BRIDGE: tab switch cannot leave a hidden active Exam Prep surface.
  if (tabName !== "courses") {
    try { window.iClubExamPrep?.close?.(); } catch {}
  }

''',
    "setTab",
)

css_anchor = '  <link rel="stylesheet" href="style.css?v=support1" />'
if index.count(css_anchor) != 1:
    raise SystemExit(f"index css anchor expected 1, got {index.count(css_anchor)}")
index = index.replace(
    css_anchor,
    css_anchor + '\n  <link rel="stylesheet" href="exam-prep/exam-prep-host.css?v=p014h1" />',
    1,
)

hub_anchor = '</div>\n\n  <div class="subject-hub-tabs" role="tablist" aria-label="Subject hub tabs">'
if index.count(hub_anchor) != 1:
    raise SystemExit(f"subject hub insertion anchor expected 1, got {index.count(hub_anchor)}")
host_markup = '''</div>

<div id="subject-hub-exam-prep-entry" class="subject-hub-list exam-prep-host-entry" hidden aria-hidden="true">
  <button class="settings-nav" type="button" data-action="open-exam-prep">
    <span class="settings-nav-ico">🎯</span>
    <span class="settings-nav-text">
      <span id="subject-hub-exam-prep-title" class="settings-nav-title">Cambridge AS Mathematics · Exam Prep</span>
      <span id="subject-hub-exam-prep-sub" class="settings-nav-sub muted small">Paper 1 + Paper 5</span>
    </span>
    <span class="settings-nav-arrow">›</span>
  </button>
</div>

<div id="exam-prep-host-root" class="exam-prep-host-root" hidden aria-hidden="true"></div>

  <div class="subject-hub-tabs" role="tablist" aria-label="Subject hub tabs">'''
index = index.replace(hub_anchor, host_markup, 1)

script_anchor = '  <script src="i18n.js"></script>\n  <script src="security/legacy-assessment-safe-api.js?v=p002v4reset1"></script>'
if index.count(script_anchor) != 1:
    raise SystemExit(f"script insertion anchor expected 1, got {index.count(script_anchor)}")
index = index.replace(
    script_anchor,
    '''  <script src="i18n.js"></script>
  <script src="exam-prep/exam-prep-api.js?v=p014h1"></script>
  <script src="exam-prep/exam-prep-host.js?v=p014h1"></script>
  <script src="security/legacy-assessment-safe-api.js?v=p002v4reset1"></script>''',
    1,
)

app_cache = "app.js?v=support4-p0legacysaveoff1"
if index.count(app_cache) != 1:
    raise SystemExit(f"app cache anchor expected 1, got {index.count(app_cache)}")
index = index.replace(app_cache, "app.js?v=support4-p0legacysaveoff1-p014host1", 1)

for marker in (
    "P0-14 HOST BRIDGE",
    "open-exam-prep",
    "window.iClubExamPrep?.syncSubjectHub",
    "window.iClubExamPrep?.isOpen",
    "window.iClubExamPrep?.back",
    "window.iClubExamPrep?.close",
):
    if marker not in app:
        raise SystemExit(f"missing app marker: {marker}")

for marker in (
    "subject-hub-exam-prep-entry",
    "exam-prep-host-root",
    "exam-prep/exam-prep-api.js?v=p014h1",
    "exam-prep/exam-prep-host.js?v=p014h1",
    "exam-prep/exam-prep-host.css?v=p014h1",
):
    if marker not in index:
        raise SystemExit(f"missing index marker: {marker}")

if "exam-prep/exam-prep-controller.js" in index or "exam-prep-static-data.js" in index:
    raise SystemExit("preview/synthetic modules must not be loaded by production index")

APP_PATH.write_text(app)
INDEX_PATH.write_text(index)
print("P0-14 guarded patch: prepared")
