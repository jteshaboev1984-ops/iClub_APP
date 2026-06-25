from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly 1 match, found {count}")
    return text.replace(old, new, 1)


def sub_once(text: str, pattern: str, replacement: str, label: str, flags: int = 0) -> str:
    updated, count = re.subn(pattern, replacement, text, count=1, flags=flags)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly 1 regex match, found {count}")
    return updated


app_path = ROOT / "app.js"
index_path = ROOT / "index.html"
style_path = ROOT / "style.css"

app = app_path.read_text(encoding="utf-8")
index = index_path.read_text(encoding="utf-8")
style = style_path.read_text(encoding="utf-8")

# ---------------------------------------------------------------------------
# 1. Load the fields needed by visual questions, timers and review.
# ---------------------------------------------------------------------------
app = replace_once(
    app,
    '.select("order_no, question:questions(id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,image_url,is_active,book_ref,question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en)")',
    '.select("order_no, question:questions(id,topic,subtopic,difficulty,qtype,time_limit_sec,question_text,options_text,correct_answer,explanation,image_url,is_active,book_ref,question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,explanation_ru,explanation_uz,explanation_en)")',
    "tour question select",
)

app = replace_once(
    app,
    '''  correct_answer: String(q.correct_answer ?? "").trim(),
  correctAnswer: String(q.correct_answer ?? "").trim(),
    imageUrl: q.image_url || null,
  book_ref: q.book_ref || null,
  bookReference: q.book_ref || null,
  timeLimitSec: TOUR_CONFIG.defaultQuestionTimeSec''',
    '''  correct_answer: String(q.correct_answer ?? "").trim(),
  correctAnswer: String(q.correct_answer ?? "").trim(),
  explanation: pickL(q, "explanation") || "",
  imageUrl: q.image_url || null,
  book_ref: q.book_ref || null,
  bookReference: q.book_ref || null,
  timeLimitSec:
    (q.time_limit_sec != null && Number(q.time_limit_sec) >= 10)
      ? Number(q.time_limit_sec)
      : TOUR_CONFIG.defaultQuestionTimeSec''',
    "tour UI mapping",
)

# ---------------------------------------------------------------------------
# 2. A question does not start timing until all required visual content is ready.
# ---------------------------------------------------------------------------
app = replace_once(
    app,
    '''    startedAt: Date.now(),
    qStartedAt: Date.now(),
    startedAtMono: monoNow(),
    qStartedAtMono: monoNow(),''',
    '''    startedAt: Date.now(),
    qStartedAt: null,
    startedAtMono: monoNow(),
    qStartedAtMono: null,
    questionReady: false,''',
    "tour session timing state",
)

preload_guard = '''
  showAsyncOverlay(tr3(
    "Загружаем изображения вопросов…",
    "Savol rasmlari yuklanmoqda…",
    "Loading question images…"
  ));

  let imagePreloadResult = { ok: true, failed: [] };
  try {
    imagePreloadResult = await preloadTourQuestionImages(questions);
  } finally {
    hideAsyncOverlay();
  }

  if (!imagePreloadResult?.ok) {
    try {
      trackEvent("tour_question_image_preload_failed", {
        tour_id: String(tour.id || ""),
        subject_key: String(subjectKey || ""),
        tour_no: Number(tourNo || 0),
        failed_urls: (imagePreloadResult.failed || []).map(x => String(x?.url || ""))
      });
    } catch {}

    await uiAlert({
      title: tr3("Изображение не загрузилось", "Rasm yuklanmadi", "Image failed to load"),
      message: tr3(
        "Тур не начат и попытка не использована. Проверьте интернет и попробуйте открыть тур снова.",
        "Tur boshlanmadi va urinish sarflanmadi. Internetni tekshirib, turni qayta ochib ko‘ring.",
        "The tour was not started and your attempt was not used. Check your connection and open the tour again."
      ),
      okText: tr3("Понятно", "Tushunarli", "OK")
    });
    return;
  }

'''
app = replace_once(
    app,
    '    try {\n    trackEvent("tour_rules_accepted", {',
    preload_guard + '    try {\n    trackEvent("tour_rules_accepted", {',
    "preload before attempt",
)

app = replace_once(
    app,
    '''    // 2) per-question timeout: auto submit if exceeded and not answered for this question index
    const qElapsed = Math.floor((monoNow() - (ctx.qStartedAtMono ?? ctx.qStartedAt)) / 1000);''',
    '''    // The question timer is paused until its required image is fully available.
    const qStart = ctx.qStartedAtMono ?? ctx.qStartedAt;
    if (!ctx.questionReady || qStart === null || qStart === undefined) return;

    // 2) per-question timeout: auto submit if exceeded and not answered for this question index
    const qElapsed = Math.floor((monoNow() - qStart) / 1000);''',
    "timeout readiness guard",
)

# ---------------------------------------------------------------------------
# 3. Shared visual-question helpers.
# ---------------------------------------------------------------------------
helpers = r'''  // ---------- Question images ----------
  const __tourQuestionImageCache = new Map();
  let __questionImageModalBound = false;

  function normalizeQuestionImageUrl(value) {
    const raw = String(value || "").trim();
    if (!raw) return "";

    try {
      const parsed = new URL(raw, window.location.href);
      if (parsed.protocol !== "http:" && parsed.protocol !== "https:") return "";
      return parsed.href;
    } catch {
      return "";
    }
  }

  function questionImageAltText() {
    return tr3(
      "Изображение к вопросу",
      "Savolga oid rasm",
      "Question image"
    );
  }

  function preloadQuestionImage(rawUrl, { force = false, timeoutMs = 15000 } = {}) {
    const url = normalizeQuestionImageUrl(rawUrl);
    if (!url) {
      return Promise.resolve({ ok: false, url: rawUrl || "", reason: "invalid_url" });
    }

    const cached = __tourQuestionImageCache.get(url);
    if (!force && cached?.status === "loaded") {
      return Promise.resolve({ ok: true, url, image: cached.image, cached: true });
    }
    if (!force && cached?.status === "loading" && cached?.promise) {
      return cached.promise;
    }
    if (force || cached?.status === "error") {
      __tourQuestionImageCache.delete(url);
    }

    const record = {
      status: "loading",
      image: null,
      promise: null
    };

    record.promise = new Promise((resolve) => {
      const image = new Image();
      record.image = image;
      image.decoding = "async";

      let settled = false;
      const timer = setTimeout(() => finish(false, "timeout"), timeoutMs);

      const finish = (ok, reason = null) => {
        if (settled) return;
        settled = true;
        clearTimeout(timer);
        image.onload = null;
        image.onerror = null;
        record.status = ok ? "loaded" : "error";
        record.promise = null;
        __tourQuestionImageCache.set(url, record);
        resolve({ ok, url, image, reason });
      };

      image.onload = () => {
        try {
          const decoded = typeof image.decode === "function" ? image.decode() : null;
          if (decoded && typeof decoded.catch === "function") decoded.catch(() => null);
        } catch {}
        finish(true);
      };
      image.onerror = () => finish(false, "load_error");
      image.src = url;

      if (image.complete && image.naturalWidth > 0) {
        queueMicrotask(() => finish(true));
      }
    });

    __tourQuestionImageCache.set(url, record);
    return record.promise;
  }

  async function preloadTourQuestionImages(questions) {
    const urls = Array.from(new Set(
      (Array.isArray(questions) ? questions : [])
        .map(q => normalizeQuestionImageUrl(q?.imageUrl ?? q?.image_url))
        .filter(Boolean)
    ));

    if (!urls.length) return { ok: true, failed: [] };

    const results = await Promise.all(urls.map(url => preloadQuestionImage(url)));
    const failed = results.filter(x => !x?.ok);
    return { ok: failed.length === 0, failed };
  }

  function setTourAnswerControlsEnabled(enabled) {
    const wrap =
      $("#tour-options") ||
      $("#tour-options-wrap") ||
      $("#tour-options-list") ||
      document.querySelector(".tour-options");

    if (!wrap) return;
    wrap.classList.toggle("is-image-loading", !enabled);
    wrap.querySelectorAll(".option, #tour-input").forEach(el => {
      el.disabled = !enabled;
    });
  }

  function closeQuestionImageModal() {
    const modal = document.getElementById("question-image-modal");
    const image = document.getElementById("question-image-modal-img");
    if (!modal) return;
    modal.hidden = true;
    modal.setAttribute("aria-hidden", "true");
    if (image) image.removeAttribute("src");
    document.body.classList.remove("question-image-modal-open");
  }

  function openQuestionImageModal(rawUrl, altText = "") {
    const url = normalizeQuestionImageUrl(rawUrl);
    const modal = document.getElementById("question-image-modal");
    const image = document.getElementById("question-image-modal-img");
    if (!url || !modal || !image) return;

    image.alt = String(altText || questionImageAltText());
    image.src = url;
    modal.hidden = false;
    modal.setAttribute("aria-hidden", "false");
    document.body.classList.add("question-image-modal-open");
  }

  function bindQuestionImageModalOnce() {
    if (__questionImageModalBound) return;
    const modal = document.getElementById("question-image-modal");
    const closeBtn = document.getElementById("question-image-modal-close");
    if (!modal) return;

    __questionImageModalBound = true;
    if (closeBtn) closeBtn.addEventListener("click", closeQuestionImageModal);
    modal.addEventListener("click", (event) => {
      if (event.target === modal) closeQuestionImageModal();
    });
    document.addEventListener("keydown", (event) => {
      if (event.key === "Escape" && !modal.hidden) closeQuestionImageModal();
    });
  }

  function renderTourQuestionImage(q, { onReady } = {}) {
    const figure = document.getElementById("tour-question-figure");
    const status = document.getElementById("tour-question-image-status");
    const openBtn = document.getElementById("tour-question-image-open");
    const image = document.getElementById("tour-question-image");
    const retryBtn = document.getElementById("tour-question-image-retry");
    const url = normalizeQuestionImageUrl(q?.imageUrl ?? q?.image_url);

    const readyCallback = typeof onReady === "function" ? onReady : () => {};
    if (!figure || !status || !openBtn || !image || !retryBtn) {
      readyCallback();
      return;
    }

    bindQuestionImageModalOnce();
    image.onload = null;
    image.onerror = null;
    image.removeAttribute("src");
    image.hidden = true;
    openBtn.hidden = true;
    retryBtn.hidden = true;
    status.hidden = true;

    if (!url) {
      figure.hidden = true;
      readyCallback();
      return;
    }

    figure.hidden = false;
    status.hidden = false;
    status.textContent = tr3(
      "Загружаем изображение…",
      "Rasm yuklanmoqda…",
      "Loading image…"
    );

    const expectedIndex = Number(state?.tourContext?.index ?? -1);
    const expectedQuestionId = Number(q?.id || 0);
    let completed = false;

    const isStillCurrent = () => {
      const live = state?.tourContext;
      if (!live || Number(live.index) !== expectedIndex) return false;
      const currentId = Number(live.questions?.[live.index]?.id || 0);
      return !expectedQuestionId || !currentId || currentId === expectedQuestionId;
    };

    const markReady = () => {
      if (completed || !isStillCurrent()) return;
      completed = true;
      status.hidden = true;
      retryBtn.hidden = true;
      image.hidden = false;
      openBtn.hidden = false;
      readyCallback();
    };

    const markFailed = (reason = "load_error") => {
      if (!isStillCurrent()) return;
      completed = false;
      image.hidden = true;
      openBtn.hidden = true;
      status.hidden = false;
      retryBtn.hidden = false;
      status.textContent = tr3(
        "Изображение не загрузилось. Повторите загрузку.",
        "Rasm yuklanmadi. Qayta yuklang.",
        "The image failed to load. Try again."
      );

      try {
        trackEvent("tour_question_image_failed", {
          question_id: String(q?.id || ""),
          tour_id: String(state?.tourContext?.tourId || ""),
          tour_no: Number(state?.tourContext?.tourNo || 0),
          reason: String(reason || "load_error"),
          image_url: url
        });
      } catch {}
    };

    const loadIntoView = async (force = false) => {
      if (!isStillCurrent()) return;
      completed = false;
      setTourAnswerControlsEnabled(false);
      retryBtn.hidden = true;
      status.hidden = false;
      status.textContent = tr3(
        "Загружаем изображение…",
        "Rasm yuklanmoqda…",
        "Loading image…"
      );

      const result = await preloadQuestionImage(url, { force });
      if (!result?.ok) {
        markFailed(result?.reason || "load_error");
        return;
      }

      image.alt = questionImageAltText();
      image.onload = markReady;
      image.onerror = () => markFailed("dom_load_error");
      image.src = result.url;

      if (image.complete && image.naturalWidth > 0) {
        queueMicrotask(markReady);
      }
    };

    openBtn.onclick = () => openQuestionImageModal(url, image.alt);
    retryBtn.onclick = () => loadIntoView(true);
    loadIntoView(false).catch(() => markFailed("exception"));
  }

  function buildReviewQuestionImageHtml(detail) {
    const url = normalizeQuestionImageUrl(detail?.imageUrl ?? detail?.image_url);
    if (!url) return "";

    const alt = questionImageAltText();
    return `
      <div class="tour-review-image-wrap">
        <button
          type="button"
          class="tour-review-image-button"
          data-question-image-open="${escapeHTML(url)}"
          aria-label="${escapeHTML(tr3("Увеличить изображение", "Rasmni kattalashtirish", "Enlarge image"))}"
        >
          <img
            class="tour-review-question-image"
            src="${escapeHTML(url)}"
            alt="${escapeHTML(alt)}"
            loading="lazy"
            decoding="async"
          >
        </button>
        <div class="tour-review-image-error muted small" hidden>
          ${escapeHTML(tr3("Изображение недоступно.", "Rasm mavjud emas.", "Image unavailable."))}
        </div>
      </div>
    `;
  }

  function bindQuestionImageButtons(root) {
    if (!root) return;
    bindQuestionImageModalOnce();

    root.querySelectorAll("[data-question-image-open]").forEach(button => {
      const url = normalizeQuestionImageUrl(button.getAttribute("data-question-image-open"));
      const image = button.querySelector("img");
      const error = button.parentElement?.querySelector(".tour-review-image-error");

      if (!url) {
        button.hidden = true;
        if (error) error.hidden = false;
        return;
      }

      button.addEventListener("click", () => openQuestionImageModal(url, image?.alt || questionImageAltText()));
      if (image) {
        image.addEventListener("error", () => {
          button.hidden = true;
          if (error) error.hidden = false;
        }, { once: true });
      }
    });
  }

  // ---------- Render ----------
'''

app = replace_once(
    app,
    '  // ---------- Render ----------\n  function renderTourHUD() {',
    helpers + '  function renderTourHUD() {',
    "visual helpers insertion",
)

# ---------------------------------------------------------------------------
# 4. HUD and timeout are safe while an image is loading.
# ---------------------------------------------------------------------------
app = replace_once(
    app,
    '''       const overall = formatMsToMMSS(monoNow() - (ctx.startedAtMono ?? ctx.startedAt));
    const overallEl = $("#tour-overall-time");
    if (overallEl) overallEl.textContent = overall;

    const qElapsed = formatMsToMMSS(monoNow() - (ctx.qStartedAtMono ?? ctx.qStartedAt));
    const qEl = $("#tour-question-time");
    if (qEl) qEl.textContent = qElapsed;
     // ✅ last-10-seconds warning on question timer
try {
  const qRow = ctx.questions?.[ctx.index] || null;

  const limitSecRaw =
    qRow?.time_limit_seconds ??
    qRow?.timeLimitSec ??
    TOUR_CONFIG.defaultQuestionTimeSec ??
    45;

  const limitSec = Math.max(1, Number(limitSecRaw) || 45);
  const elapsedSec = Math.max(0, Math.floor((monoNow() - (ctx.qStartedAtMono ?? ctx.qStartedAt)) / 1000));
  const remainSec = limitSec - elapsedSec;

  const qCard = (qEl && qEl.closest) ? qEl.closest(".tour-timer-card") : null;
  if (qCard) {
    if (remainSec <= 10) qCard.classList.add("danger");
    else qCard.classList.remove("danger");

    if (remainSec <= 5) qCard.classList.add("pulse");
    else qCard.classList.remove("pulse");
  }
} catch {}''',
    '''       const overall = formatMsToMMSS(monoNow() - (ctx.startedAtMono ?? ctx.startedAt));
    const overallEl = $("#tour-overall-time");
    if (overallEl) overallEl.textContent = overall;

    const qEl = $("#tour-question-time");
    const qCard = (qEl && qEl.closest) ? qEl.closest(".tour-timer-card") : null;
    const qStart = ctx.qStartedAtMono ?? ctx.qStartedAt;
    const timingReady = !!ctx.questionReady && qStart !== null && qStart !== undefined;

    if (!timingReady) {
      if (qEl) qEl.textContent = "—";
      if (qCard) {
        qCard.classList.remove("danger");
        qCard.classList.remove("pulse");
      }
    } else {
      const qElapsed = formatMsToMMSS(monoNow() - qStart);
      if (qEl) qEl.textContent = qElapsed;

      try {
        const qRow = ctx.questions?.[ctx.index] || null;
        const limitSecRaw =
          qRow?.time_limit_seconds ??
          qRow?.timeLimitSec ??
          TOUR_CONFIG.defaultQuestionTimeSec ??
          45;
        const limitSec = Math.max(1, Number(limitSecRaw) || 45);
        const elapsedSec = Math.max(0, Math.floor((monoNow() - qStart) / 1000));
        const remainSec = limitSec - elapsedSec;

        if (qCard) {
          if (remainSec <= 10) qCard.classList.add("danger");
          else qCard.classList.remove("danger");

          if (remainSec <= 5) qCard.classList.add("pulse");
          else qCard.classList.remove("pulse");
        }
      } catch {}
    }''',
    "tour HUD timing",
)

# ---------------------------------------------------------------------------
# 5. Replace the question renderer as one coherent unit.
# ---------------------------------------------------------------------------
new_render_question = r'''  function renderTourQuestion() {
    const ctx = state.tourContext;
    if (!ctx) return;

    const q = ctx.questions?.[ctx.index];
    if (!q) {
      finishTour({ reason: "done" }).catch(() => null);
      return;
    }

    const renderedIndex = Number(ctx.index);
    const renderedQuestionId = Number(q?.id || 0);

    ctx.questionReady = false;
    ctx.qStartedAt = null;
    ctx.qStartedAtMono = null;
    ctx._pickedIndex = null;
    saveState();

    const qEl =
      $("#tour-question") ||
      $("#quiz-question") ||
      $("#tour-question-text");

    if (qEl) {
      const qText =
        (q.question ?? q.question_text ?? q.questionText ?? q.text ?? q.prompt ?? q.title ?? "");
      qEl.textContent = String(qText || "");
    }

    const qTypeRaw = String(q.qtype ?? q.type ?? q.question_type ?? "mcq").toLowerCase();
    const isMcq = (qTypeRaw === "mcq" || qTypeRaw === "choice" || qTypeRaw === "multiple_choice");

    const wrap =
      $("#tour-options") ||
      $("#tour-options-wrap") ||
      $("#tour-options-list") ||
      document.querySelector(".tour-options");

    const nextBtn =
      $("#tour-next-btn") ||
      $("#quiz-next-btn") ||
      document.querySelector('[data-action="tour-next"]');

    let inputEl = null;
    let syncTourInputState = null;

    if (wrap) {
      wrap.innerHTML = "";

      if (!isMcq) {
        const inputWrap = document.createElement("div");
        inputWrap.className = "input-wrap";
        inputWrap.innerHTML = `
          <label class="input-label">${escapeHTML(t("answer") || "Answer")}</label>
          <input id="tour-input" class="text-input" type="text" placeholder="${escapeHTML(t("type_answer") || "Type your answer")}" disabled>
          <div id="tour-input-error" class="muted small" style="margin-top:6px; display:none;"></div>
        `;
        wrap.appendChild(inputWrap);

        inputEl = inputWrap.querySelector("#tour-input");
        const errEl = inputWrap.querySelector("#tour-input-error");

        syncTourInputState = () => {
          if (!inputEl || !nextBtn) return;
          const liveCtx = state.tourContext;
          if (!liveCtx?.questionReady) {
            nextBtn.disabled = true;
            return;
          }

          const raw = String(inputEl.value || "");
          const hasValue = raw.trim().length > 0;
          const isValid = hasValue && isValidInputAnswer(q, raw);
          nextBtn.disabled = !isValid;

          if (errEl) {
            if (hasValue && !isValid) {
              errEl.textContent = t("invalid_answer_format");
              errEl.style.display = "block";
            } else {
              errEl.textContent = "";
              errEl.style.display = "none";
            }
          }
        };

        if (inputEl) inputEl.addEventListener("input", syncTourInputState);
      } else {
        const opts = Array.isArray(q.options) && q.options.length
          ? q.options
          : ["Option A", "Option B", "Option C", "Option D"];

        opts.forEach((opt, i) => {
          const btn = document.createElement("button");
          btn.type = "button";
          btn.className = "option";
          btn.dataset.action = "tour-pick";
          btn.dataset.index = String(i);
          btn.disabled = true;
          btn.innerHTML = `
            <span class="dot" aria-hidden="true"></span>
            <span class="opt-text">${escapeHTML(opt)}</span>
          `;

          btn.onclick = (event) => {
            try { event.preventDefault(); event.stopPropagation(); } catch {}
            const liveCtx = state.tourContext;
            if (!liveCtx?.questionReady) return;

            wrap.querySelectorAll(".option").forEach(option => option.classList.remove("is-selected"));
            btn.classList.add("is-selected");
            if (nextBtn) nextBtn.disabled = false;
            liveCtx._pickedIndex = i;
            saveState();
          };

          wrap.appendChild(btn);
        });
      }
    }

    if (nextBtn) {
      nextBtn.classList.remove("is-loading");
      nextBtn.disabled = true;
      const isLast = (ctx.index >= TOUR_CONFIG.total - 1);
      nextBtn.textContent = isLast
        ? (t("tour_finish_button") || "Finish Tour →")
        : (t("tour_next_question") || "Next Question →");
    }

    setTourAnswerControlsEnabled(false);

    const markQuestionReady = () => {
      const liveCtx = state.tourContext;
      if (!liveCtx || Number(liveCtx.index) !== renderedIndex) return;
      const currentQuestionId = Number(liveCtx.questions?.[liveCtx.index]?.id || 0);
      if (renderedQuestionId && currentQuestionId && renderedQuestionId !== currentQuestionId) return;

      const limitRaw =
        q?.time_limit_seconds ??
        q?.timeLimitSec ??
        TOUR_CONFIG.defaultQuestionTimeSec ??
        45;

      liveCtx.questionTimeLimit = Math.max(1, Number(limitRaw) || 45);
      liveCtx.qStartedAt = Date.now();
      liveCtx.qStartedAtMono = monoNow();
      liveCtx.questionReady = true;
      setTourAnswerControlsEnabled(true);
      if (typeof syncTourInputState === "function") syncTourInputState();
      saveState();
      renderTourHUD();
    };

    renderTourQuestionImage(q, { onReady: markQuestionReady });
    renderTourHUD();
  }

       async function submitTourAnswer'''

app = sub_once(
    app,
    r'  function renderTourQuestion\(\) \{.*?\n\}\n\n       async function submitTourAnswer',
    new_render_question,
    "replace tour question renderer",
    flags=re.DOTALL,
)

app = replace_once(
    app,
    '''    let q = ctx.questions?.[ctx.index];
    if (!q) return;

    const spentSec =''',
    '''    let q = ctx.questions?.[ctx.index];
    if (!q || !ctx.questionReady) return;

    const spentSec =''',
    "submit readiness guard",
)

# ---------------------------------------------------------------------------
# 6. Preserve and display the same image in tour review.
# ---------------------------------------------------------------------------
app = sub_once(
        app,
        r'(\s+question: q\?\.question \|\| "",\n)(\s+options: Array\.isArray\(q\?\.options\) \? q\.options\.slice\(\) : \[\],)',
        r'\1               imageUrl: q?.imageUrl || q?.image_url || null,\n\2',
        "local review image",
    )

app = sub_once(
        app,
        r'(\s+explanation,\n)(\s+question_text_ru,)',
        r'\1          image_url,\n\2',
        "DB review image select",
    )

app = sub_once(
        app,
        r'(\s+question: pickContentText\(q, "question_text"\) \|\| "",\n)(\s+options,)',
        r'\1         imageUrl: q?.image_url || null,\n\2',
        "DB review image mapping",
    )

app = replace_once(
    app,
    '''              <div style="margin-top:10px">${escapeHTML(d.question || "")}</div>
              <div class="muted small" style="margin-top:10px">''',
    '''              <div style="margin-top:10px">${escapeHTML(d.question || "")}</div>
              ${buildReviewQuestionImageHtml(d)}
              <div class="muted small" style="margin-top:10px">''',
    "review image HTML",
)

app = replace_once(
    app,
    '''    `;
  };

  // 1) instant local payload right after finish''',
    '''    `;
    bindQuestionImageButtons(wrap);
  };

  // 1) instant local payload right after finish''',
    "review image binding",
)

# ---------------------------------------------------------------------------
# 7. HTML containers for active image, retry and full-screen view.
# ---------------------------------------------------------------------------
index = replace_once(
    index,
    '''    <div id="tour-question" class="question-text">Вопрос тура…</div>
    <div id="tour-options" class="options"></div>''',
    '''    <div id="tour-question" class="question-text">Вопрос тура…</div>

    <figure id="tour-question-figure" class="tour-question-figure" hidden>
      <div id="tour-question-image-status" class="tour-question-image-status muted small" role="status" aria-live="polite"></div>
      <button id="tour-question-image-open" class="tour-question-image-open" type="button" hidden aria-label="Open question image">
        <img id="tour-question-image" class="tour-question-image" alt="" hidden decoding="async">
      </button>
      <button id="tour-question-image-retry" class="btn tour-question-image-retry" type="button" hidden>
        Повторить загрузку
      </button>
    </figure>

    <div id="tour-options" class="options"></div>''',
    "active tour image container",
)

modal_html = '''
  <div id="question-image-modal" class="question-image-modal" role="dialog" aria-modal="true" aria-hidden="true" aria-label="Question image" hidden>
    <button id="question-image-modal-close" class="question-image-modal-close" type="button" aria-label="Close">×</button>
    <div class="question-image-modal-content">
      <img id="question-image-modal-img" class="question-image-modal-img" alt="">
    </div>
  </div>
'''
index = replace_once(index, "</body>", modal_html + "\n</body>", "question image modal")

# ---------------------------------------------------------------------------
# 8. Responsive styles. Appended to avoid disturbing existing layout rules.
# ---------------------------------------------------------------------------
visual_css = r'''

/* =========================================================
   Question images — active tours and review
   ========================================================= */
.tour-question-figure {
  margin: 12px 0 16px;
  padding: 10px;
  border: 1px solid var(--border);
  border-radius: 16px;
  background: rgba(246, 248, 252, 0.7);
  text-align: center;
}

.tour-question-image-status {
  padding: 16px 10px;
  font-weight: 700;
}

.tour-question-image-open,
.tour-review-image-button {
  display: block;
  width: 100%;
  padding: 0;
  border: 0;
  border-radius: 12px;
  background: transparent;
  cursor: zoom-in;
}

.tour-question-image,
.tour-review-question-image {
  display: block;
  width: 100%;
  max-width: 100%;
  max-height: 380px;
  object-fit: contain;
  border-radius: 12px;
  background: #fff;
}

.tour-question-image-retry {
  margin: 10px auto 2px;
}

.options.is-image-loading {
  opacity: 0.58;
  pointer-events: none;
}

.option:disabled,
#tour-input:disabled {
  cursor: not-allowed;
  opacity: 0.62;
}

.tour-review-image-wrap {
  margin-top: 12px;
  padding: 8px;
  border: 1px solid var(--border);
  border-radius: 14px;
  background: rgba(246, 248, 252, 0.7);
}

.tour-review-image-error {
  padding: 10px;
  text-align: center;
}

body.question-image-modal-open {
  overflow: hidden;
}

.question-image-modal[hidden] {
  display: none !important;
}

.question-image-modal {
  position: fixed;
  inset: 0;
  z-index: 10000;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: max(18px, env(safe-area-inset-top)) max(14px, env(safe-area-inset-right)) max(18px, env(safe-area-inset-bottom)) max(14px, env(safe-area-inset-left));
  background: rgba(15, 23, 42, 0.92);
}

.question-image-modal-content {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
  overflow: auto;
}

.question-image-modal-img {
  display: block;
  max-width: 100%;
  max-height: 100%;
  object-fit: contain;
  background: #fff;
  border-radius: 12px;
}

.question-image-modal-close {
  position: fixed;
  top: max(12px, env(safe-area-inset-top));
  right: max(12px, env(safe-area-inset-right));
  z-index: 10001;
  width: 44px;
  height: 44px;
  border: 1px solid rgba(255, 255, 255, 0.35);
  border-radius: 999px;
  background: rgba(15, 23, 42, 0.78);
  color: #fff;
  font-size: 30px;
  line-height: 1;
  cursor: pointer;
}

@media (max-width: 420px) {
  .tour-question-figure {
    margin: 10px 0 14px;
    padding: 7px;
  }

  .tour-question-image,
  .tour-review-question-image {
    max-height: 300px;
  }
}
'''

if "Question images — active tours and review" in style:
    raise RuntimeError("visual question CSS already exists")
style = style.rstrip() + visual_css + "\n"

app_path.write_text(app, encoding="utf-8")
index_path.write_text(index, encoding="utf-8")
style_path.write_text(style, encoding="utf-8")

print("Visual question rendering patch applied successfully.")
