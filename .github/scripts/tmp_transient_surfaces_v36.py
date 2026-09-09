from pathlib import Path
from textwrap import dedent

CSS = Path('visual/iclub-premium-v3.css')
css = CSS.read_text(encoding='utf-8')
marker = '/* ===== PREMIUM TRANSIENT SURFACES v3.6 ===== */'
if marker in css:
    raise SystemExit('Transient surfaces v3.6 already present')

block = dedent('''
/* ===== PREMIUM TRANSIENT SURFACES v3.6 ===== */
/* Feedback, loading and confirmation surfaces share the same quiet premium language. */
.iclub-visual-v3 #modal-root .modal-backdrop {
  padding: 18px 14px calc(18px + var(--safe-bottom));
  background: rgba(15, 23, 42, 0.34);
  backdrop-filter: blur(5px);
  -webkit-backdrop-filter: blur(5px);
}

.iclub-visual-v3 #modal-root .modal {
  width: min(100%, 360px);
  max-height: min(78vh, 620px);
  overflow: auto;
  padding: 16px;
  border: 1px solid rgba(226, 232, 240, 0.96);
  border-radius: var(--v3-radius-lg);
  background: #FFFFFF;
  color: var(--v3-text);
  box-shadow: 0 22px 60px rgba(15, 23, 42, 0.18);
}

.iclub-visual-v3 #modal-root .modal-title {
  margin: 0 0 7px;
  color: var(--v3-text);
  font-size: 17px;
  line-height: 1.22;
  font-weight: 810;
  letter-spacing: -0.018em;
  overflow-wrap: anywhere;
}

.iclub-visual-v3 #modal-root .modal-text {
  color: var(--v3-muted);
  font-size: 12.5px;
  line-height: 1.5;
  overflow-wrap: anywhere;
}

.iclub-visual-v3 #modal-root .modal-actions {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 8px;
  margin-top: 15px;
}

.iclub-visual-v3 #modal-root .modal-actions.modal-actions-single {
  grid-template-columns: 1fr;
}

.iclub-visual-v3 #modal-root .modal-actions .btn {
  width: 100%;
  min-width: 0;
  min-height: 42px;
  border-radius: var(--v3-radius-md);
  box-shadow: none;
  font-size: 12px;
  font-weight: 770;
  white-space: normal;
}

.iclub-visual-v3 #modal-root .modal-actions .btn.primary {
  border-color: var(--v3-primary);
  background: var(--v3-primary);
  color: #FFFFFF;
  box-shadow: 0 5px 14px rgba(36, 87, 214, 0.15);
}

.iclub-visual-v3 #modal-root .modal-actions .btn.danger {
  border-color: #F0D2CF;
  background: #FFF5F3;
  color: var(--v3-danger);
}

.iclub-visual-v3 #toast {
  left: 50%;
  right: auto;
  bottom: calc(78px + var(--safe-bottom));
  width: max-content;
  max-width: min(calc(100vw - 28px), 350px);
  min-height: 40px;
  padding: 10px 13px;
  border: 1px solid rgba(203, 213, 225, 0.92);
  border-radius: var(--v3-radius-md);
  background: rgba(255, 255, 255, 0.97);
  color: var(--v3-text);
  font-size: 12px;
  line-height: 1.4;
  font-weight: 700;
  text-align: center;
  box-shadow: 0 14px 34px rgba(15, 23, 42, 0.14);
  backdrop-filter: blur(10px);
  -webkit-backdrop-filter: blur(10px);
  transform: translate(-50%, 10px);
}

.iclub-visual-v3 #toast.is-show {
  transform: translate(-50%, 0);
}

.iclub-visual-v3 #view-transition-overlay,
.iclub-visual-v3 #ratings-loading,
.iclub-visual-v3 #tours-loading {
  background: rgba(247, 249, 254, 0.78);
  backdrop-filter: blur(5px);
  -webkit-backdrop-filter: blur(5px);
}

.iclub-visual-v3 #view-transition-overlay .view-transition-card,
.iclub-visual-v3 #ratings-loading .lb-loading-card,
.iclub-visual-v3 #tours-loading .tours-loading-card {
  min-width: 132px;
  max-width: min(calc(100vw - 32px), 280px);
  padding: 15px 17px;
  border: 1px solid var(--v3-border);
  border-radius: var(--v3-radius-lg);
  background: rgba(255, 255, 255, 0.96);
  color: var(--v3-text);
  box-shadow: 0 18px 46px rgba(15, 23, 42, 0.12);
}

.iclub-visual-v3 #view-transition-overlay .view-transition-text,
.iclub-visual-v3 #ratings-loading .lb-loading-text,
.iclub-visual-v3 #tours-loading .tours-loading-text {
  margin-top: 8px;
  color: var(--v3-muted);
  font-size: 11px;
  line-height: 1.35;
  font-weight: 720;
  text-align: center;
  overflow-wrap: anywhere;
}

.iclub-visual-v3 #view-transition-overlay .view-transition-spinner {
  width: 28px;
  height: 28px;
  border-width: 2px;
  border-color: #DDE5F4;
  border-top-color: var(--v3-primary);
}

.iclub-visual-v3 #ratings-loading .lb-loading-logo,
.iclub-visual-v3 #tours-loading .tours-loading-logo {
  width: 38px;
  height: 38px;
  border: 1px solid #DEE6F6;
  border-radius: var(--v3-radius-sm);
  background: #FFFFFF;
  box-shadow: none;
}

.iclub-visual-v3 #view-notifications .notification-card {
  padding: 13px 46px 13px 13px;
  border: 1px solid var(--v3-border);
  border-radius: var(--v3-radius-lg);
  background: #FFFFFF;
  box-shadow: var(--v3-premium-shadow);
}

.iclub-visual-v3 #view-notifications .notification-card.is-unread {
  border-color: #D3DEFA;
  background: linear-gradient(135deg, #FFFFFF 0%, #F5F8FF 100%);
  box-shadow: var(--v3-premium-shadow);
}

.iclub-visual-v3 #view-notifications .notification-title {
  color: var(--v3-text);
  font-size: 13px;
  line-height: 1.3;
  font-weight: 780;
  letter-spacing: -0.008em;
  overflow-wrap: anywhere;
}

.iclub-visual-v3 #view-notifications .notification-date {
  color: var(--v3-muted);
  font-size: 10px;
  line-height: 1.3;
  font-weight: 650;
}

.iclub-visual-v3 #view-notifications .notification-body {
  margin-top: 6px;
  color: #536178;
  font-size: 11.5px;
  line-height: 1.48;
  overflow-wrap: anywhere;
}

.iclub-visual-v3 #view-notifications .notification-delete-btn {
  top: 10px;
  right: 10px;
  width: 32px;
  height: 32px;
  padding: 0;
  border: 1px solid #E2E8F0;
  border-radius: var(--v3-radius-sm);
  background: #F8FAFD;
  color: #7B8798;
  font-size: 17px;
  line-height: 1;
  box-shadow: none;
}

.iclub-visual-v3 #question-image-modal {
  padding: 18px 14px calc(18px + var(--safe-bottom));
  background: rgba(15, 23, 42, 0.58);
  backdrop-filter: blur(6px);
  -webkit-backdrop-filter: blur(6px);
}

.iclub-visual-v3 #question-image-modal .question-image-modal-content {
  max-width: min(92vw, 900px);
  max-height: 82vh;
  padding: 8px;
  overflow: hidden;
  border: 1px solid rgba(255, 255, 255, 0.28);
  border-radius: var(--v3-radius-lg);
  background: rgba(255, 255, 255, 0.96);
  box-shadow: 0 24px 64px rgba(15, 23, 42, 0.28);
}

.iclub-visual-v3 #question-image-modal .question-image-modal-img {
  border-radius: var(--v3-radius-md);
}

.iclub-visual-v3 #question-image-modal .question-image-modal-close {
  width: 38px;
  height: 38px;
  display: grid;
  place-items: center;
  padding: 0;
  border: 1px solid rgba(255, 255, 255, 0.34);
  border-radius: var(--v3-radius-md);
  background: rgba(255, 255, 255, 0.94);
  color: var(--v3-text);
  font-size: 22px;
  line-height: 1;
  box-shadow: 0 8px 20px rgba(15, 23, 42, 0.16);
}

@media (max-width: 350px) {
  .iclub-visual-v3 #modal-root .modal-actions {
    grid-template-columns: 1fr;
  }

  .iclub-visual-v3 #view-notifications .notification-head {
    display: grid;
    grid-template-columns: 1fr;
    gap: 4px;
  }

  .iclub-visual-v3 #view-notifications .notification-date {
    max-width: none;
    text-align: left;
  }
}

@media (prefers-reduced-motion: reduce) {
  .iclub-visual-v3 #toast,
  .iclub-visual-v3 #view-transition-overlay .view-transition-spinner {
    transition: none !important;
    animation: none !important;
  }
}
''').strip()

CSS.write_text(css.rstrip() + '\n\n' + block + '\n', encoding='utf-8')
