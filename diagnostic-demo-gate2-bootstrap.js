(function(){
  'use strict';
  try {
    window.ICLUB_DEMO_GATE2_BOOT_STATE = JSON.parse(localStorage.getItem('iclub_demo_v12.state') || '{}');
  } catch {
    window.ICLUB_DEMO_GATE2_BOOT_STATE = {};
  }
})();
