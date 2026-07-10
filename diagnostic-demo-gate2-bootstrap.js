(function(){
  'use strict';
  try {
    window.ICLUB_DEMO_GATE2_BOOT_STATE = JSON.parse(localStorage.getItem('iclub_demo_v12.state') || '{}');
  } catch {
    window.ICLUB_DEMO_GATE2_BOOT_STATE = {};
  }
  if (!document.querySelector('link[href="diagnostic-demo-main-hub.css"]')) {
    const link = document.createElement('link');
    link.rel = 'stylesheet';
    link.href = 'diagnostic-demo-main-hub.css';
    document.head.appendChild(link);
  }
  if (!document.querySelector('script[src="diagnostic-demo-main-hub.js"]')) {
    const script = document.createElement('script');
    script.src = 'diagnostic-demo-main-hub.js';
    document.head.appendChild(script);
  }
})();