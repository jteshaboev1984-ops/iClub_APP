// Lab-only display fix for AI diagnosis focus labels.
// It only localizes visible text in the lab UI. No DB writes.

(() => {
  'use strict';

  const FOCUS_MAP = {
    'examples of injections': {
      ru: 'Примеры инъекций',
      uz: 'Inyeksiyalar misollari',
      en: 'Examples of injections'
    },
    'injections': {
      ru: 'Инъекции',
      uz: 'Inyeksiyalar',
      en: 'Injections'
    },
    'examples of leakages': {
      ru: 'Примеры утечек',
      uz: 'Chiqib ketishlar misollari',
      en: 'Examples of leakages'
    },
    'leakages': {
      ru: 'Утечки',
      uz: 'Chiqib ketishlar',
      en: 'Leakages'
    },
    'circular flow': {
      ru: 'Кругооборот доходов',
      uz: 'Daromadlar aylanishi',
      en: 'Circular flow'
    },
    'market equilibrium': {
      ru: 'Рыночное равновесие',
      uz: 'Bozor muvozanati',
      en: 'Market equilibrium'
    },
    'demand': {
      ru: 'Спрос',
      uz: 'Talab',
      en: 'Demand'
    },
    'supply': {
      ru: 'Предложение',
      uz: 'Taklif',
      en: 'Supply'
    }
  };

  function lang() {
    try {
      if (window.i18n && typeof window.i18n.getLang === 'function') {
        return String(window.i18n.getLang() || 'ru').toLowerCase();
      }
    } catch {}
    return String(document.documentElement.lang || 'ru').toLowerCase();
  }

  function localizeText(value) {
    let text = String(value || '');
    const currentLang = lang();

    for (const [rawKey, labels] of Object.entries(FOCUS_MAP)) {
      const label = labels[currentLang] || labels.ru || labels.en || rawKey;
      const escaped = rawKey.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      text = text.replace(new RegExp(escaped, 'gi'), label);
    }

    if (currentLang === 'ru') {
      text = text
        .replace(/Примеры инъекций выбран как главный фокус/g, 'Тема «Примеры инъекций» выбрана как главный фокус')
        .replace(/Инъекции выбран как главный фокус/g, 'Тема «Инъекции» выбрана как главный фокус')
        .replace(/Примеры утечек выбран как главный фокус/g, 'Тема «Примеры утечек» выбрана как главный фокус')
        .replace(/Утечки выбран как главный фокус/g, 'Тема «Утечки» выбрана как главный фокус')
        .replace(/Кругооборот доходов выбран как главный фокус/g, 'Тема «Кругооборот доходов» выбрана как главный фокус')
        .replace(/Рыночное равновесие выбран как главный фокус/g, 'Тема «Рыночное равновесие» выбрана как главный фокус')
        .replace(/Спрос выбран как главный фокус/g, 'Тема «Спрос» выбрана как главный фокус')
        .replace(/Предложение выбран как главный фокус/g, 'Тема «Предложение» выбрана как главный фокус');
    }

    return text;
  }

  function patchTextNodes(root = document.body) {
    if (!root) return;
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    const nodes = [];
    while (walker.nextNode()) nodes.push(walker.currentNode);
    nodes.forEach((node) => {
      const next = localizeText(node.nodeValue);
      if (next !== node.nodeValue) node.nodeValue = next;
    });
  }

  let timer = null;
  function schedulePatch() {
    clearTimeout(timer);
    timer = setTimeout(() => patchTextNodes(), 40);
  }

  document.addEventListener('DOMContentLoaded', schedulePatch);
  new MutationObserver(schedulePatch).observe(document.documentElement, {
    childList: true,
    subtree: true,
    characterData: true
  });

  schedulePatch();
})();
