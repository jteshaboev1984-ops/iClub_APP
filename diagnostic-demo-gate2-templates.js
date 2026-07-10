(function(){'use strict';window.ICLUB_DEMO_GATE2_TEMPLATES={controls:`
      <section class="demo-controls-shell" id="demo-controls-shell" aria-label="Demo controls">
        <div class="demo-controls-row">
          <span class="demo-mode-copy" id="demo-mode-copy"></span>
          <div class="demo-plan-switch" role="group" aria-label="Plan switch">
            <button class="demo-plan-btn" type="button" data-demo-plan="free">Free</button>
            <button class="demo-plan-btn" type="button" data-demo-plan="plus">Plus</button>
            <button class="demo-plan-btn" type="button" data-demo-plan="pro">Pro</button>
          </div>
          <button class="demo-scenario-btn" id="demo-scenario-btn" type="button" aria-expanded="false"></button>
        </div>
        <div class="demo-scenario-menu hidden" id="demo-scenario-menu">
          <button class="demo-scenario-item" type="button" data-scenario-action="learning"><span id="scenario-learning-label"></span><small>01</small></button>
          <button class="demo-scenario-item" type="button" data-scenario-action="active-tour"><span id="scenario-tour-label"></span><small>02</small></button>
          <button class="demo-scenario-item" type="button" data-scenario-action="tools"><span id="scenario-tools-label"></span><small>03</small></button>
          <button class="demo-scenario-item" type="button" data-scenario-action="reset"><span id="scenario-reset-label"></span><small>↺</small></button>
          <button class="demo-scenario-item" type="button" data-scenario-action="technical"><span id="scenario-technical-label"></span><small>i</small></button>
        </div>
      </section>`,screens:`
      <section class="demo-screen subject-hub-screen hidden" id="subject-hub-screen">
        <div class="hub-title-row"><div><h1 id="hub-title"></h1><p id="hub-subtitle"></p></div><span class="hub-plan-badge" id="hub-plan-badge"></span></div>
        <section class="demo-profile-card">
          <div class="demo-avatar" aria-hidden="true">СК</div>
          <div><div class="demo-profile-name" id="demo-profile-name"></div><div class="demo-profile-status" id="demo-profile-status"></div></div>
          <div class="demo-profile-progress"><b>5</b><span id="demo-profile-progress-label"></span></div>
        </section>
        <section class="hub-card" id="hub-ai-card">
          <div class="hub-card-head"><div class="ai-mark-wrap" id="hub-ai-mark"><img src="iclub-ai-mark.svg" alt="iClub AI"><span class="ai-mark-lock" aria-hidden="true">⌕</span></div><div class="hub-card-copy"><div class="hub-card-title" id="hub-ai-title"></div><div class="hub-card-sub" id="hub-ai-sub"></div></div></div>
          <button class="hub-card-action primary" id="hub-ai-action" type="button"></button>
        </section>
        <section class="hub-card">
          <div class="hub-card-head"><div class="ai-mark-wrap is-available" aria-hidden="true"><span style="font-size:16px;font-weight:950">7</span></div><div class="hub-card-copy"><div class="hub-card-title" id="hub-diagnostic-title"></div><div class="hub-card-sub" id="hub-diagnostic-sub"></div></div></div>
          <button class="hub-card-action primary" id="hub-open-diagnostic" type="button"></button>
        </section>
        <div class="hub-metric-grid">
          <section class="hub-metric"><span id="hub-tour-label"></span><b>6/20</b><small id="hub-tour-meta"></small></section>
          <section class="hub-metric"><span id="hub-practice-label"></span><b>10/10</b><small id="hub-practice-meta"></small></section>
        </div>
        <section class="hub-card hub-attention"><div class="hub-card-title" id="hub-attention-title"></div><div class="hub-card-sub" id="hub-attention-copy"></div></section>
        <section class="hub-card"><div class="hub-card-title" id="hub-history-title"></div><div class="hub-card-sub" id="hub-history-sub"></div><div class="hub-history-tabs" id="hub-history-tabs"></div><div class="hub-mini-history"><div class="hub-history-row"><b id="hub-history-row-1"></b><span>10/10</span></div><div class="hub-history-row"><b id="hub-history-row-2"></b><span>6/20</span></div><div class="hub-history-row"><b id="hub-history-row-3"></b><span>10/10</span></div></div></section>
      </section>

      <section class="demo-screen gate2-screen hidden" id="plan-comparison-screen">
        <div class="section-head"><h1 id="compare-title"></h1><p id="compare-subtitle"></p></div>
        <div class="plan-compare-grid"><section class="plan-compare-card"><div class="plan-compare-name"><b>Plus</b></div><ul class="plan-compare-list" id="plus-feature-list"></ul><button class="hub-card-action" type="button" data-choose-plan="plus" id="choose-plus"></button></section><section class="plan-compare-card is-featured"><div class="plan-compare-name"><b>Pro</b><span id="pro-recommended"></span></div><ul class="plan-compare-list" id="pro-feature-list"></ul><button class="hub-card-action primary" type="button" data-choose-plan="pro" id="choose-pro"></button></section></div>
        <button class="btn" type="button" data-go-hub id="compare-back"></button>
      </section>

      <section class="demo-screen gate2-screen hidden" id="plus-chat-screen">
        <div class="section-head"><h1 id="chat-title"></h1><p id="chat-subtitle"></p></div>
        <section class="gate2-card chat-shell"><div class="chat-message system" id="chat-welcome"></div><div class="gate2-notice plan-pro-only" id="chat-pro-layer"></div><div class="chat-composer"><textarea id="demo-chat-draft"></textarea><button class="btn" type="button" id="demo-chat-send" disabled></button><div class="chat-note" id="chat-save-note"></div></div></section>
        <button class="btn" type="button" data-go-hub id="chat-back"></button>
      </section>

      <section class="demo-screen gate2-screen hidden" id="pro-trajectory-screen">
        <div class="section-head"><h1 id="trajectory-title"></h1><p id="trajectory-subtitle"></p></div>
        <section class="gate2-card"><div class="trajectory-bars"><div class="trajectory-row"><span id="trajectory-tour4"></span><div class="trajectory-track"><div class="trajectory-fill warning" style="width:30%"></div></div><b>30%</b></div><div class="trajectory-row"><span id="trajectory-practice4"></span><div class="trajectory-track"><div class="trajectory-fill" style="width:100%"></div></div><b>100%</b></div><div class="trajectory-row"><span id="trajectory-current"></span><div class="trajectory-track"><div class="trajectory-fill" id="trajectory-current-fill" style="width:0%"></div></div><b id="trajectory-current-value">—</b></div></div></section>
        <div class="gate2-notice" id="trajectory-notice"></div><button class="btn primary" type="button" id="trajectory-action"></button><button class="btn" type="button" data-go-hub id="trajectory-back"></button>
      </section>

      <section class="demo-screen gate2-screen hidden" id="active-tour-preview-screen">
        <div class="section-head"><h1 id="active-title"></h1><p id="active-subtitle"></p></div><section class="gate2-card"><div class="gate2-notice" id="active-warning"></div><button class="hub-card-action primary" type="button" id="active-theory-action"></button></section><button class="btn" type="button" id="active-back"></button>
      </section>

      <section class="demo-screen gate2-screen hidden" id="show-tools-screen">
        <div class="section-head"><h1 id="tools-title"></h1><p id="tools-subtitle"></p></div><section class="gate2-card"><div class="gate2-actions"><button class="btn primary" type="button" id="tools-rehearsed"></button><button class="btn" type="button" id="tools-free-check"></button></div><p class="chat-note" id="tools-note" style="margin-top:10px"></p></section><button class="btn" type="button" data-go-hub id="tools-back"></button>
      </section>

      <section class="demo-screen gate2-screen hidden" id="demo-technical-screen">
        <div class="section-head"><h1 id="tech-title"></h1><p id="tech-subtitle"></p></div><section class="gate2-card technical-grid" id="technical-grid"></section><button class="btn" type="button" data-go-hub id="tech-back"></button>
      </section>`};})();
