(function(){
  'use strict';

  try {
    window.ICLUB_DEMO_GATE2_BOOT_STATE = JSON.parse(localStorage.getItem('iclub_demo_v12.state') || '{}');
  } catch {
    window.ICLUB_DEMO_GATE2_BOOT_STATE = {};
  }

  const HUB_VERSION = 'main-hub-2';

  if (!document.querySelector('link[data-demo-main-hub]')) {
    const link = document.createElement('link');
    link.rel = 'stylesheet';
    link.dataset.demoMainHub = '1';
    link.href = `diagnostic-demo-main-hub.css?v=${HUB_VERSION}`;
    document.head.appendChild(link);
  }

  let loading = false;
  const loadHub = () => {
    if (loading || window.__iclubDemoMainHubLoaded || !document.getElementById('subject-hub-screen')) return;
    loading = true;
    const script = document.createElement('script');
    script.src = `diagnostic-demo-main-hub.js?v=${HUB_VERSION}`;
    script.dataset.demoMainHub = '1';
    script.onload = () => {
      window.__iclubDemoMainHubLoaded = true;
      loading = false;
    };
    script.onerror = () => {
      loading = false;
      console.error('Demo Subject Hub module could not be loaded.');
    };
    document.body.appendChild(script);
  };

  const observer = new MutationObserver(() => {
    loadHub();
    if (window.__iclubDemoMainHubLoaded) observer.disconnect();
  });

  const startObserver = () => {
    observer.observe(document.documentElement, { childList: true, subtree: true });
    loadHub();
  };

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', startObserver, { once: true });
  } else {
    startObserver();
  }
})();