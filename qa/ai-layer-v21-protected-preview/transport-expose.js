// Move only QA synthetic transport into its own namespace before other
// browser-compatible modules load. This prevents CommonJS export collisions.
"use strict";
window.iClubQaV21ScreenClient=window.module?.exports?.QaV21ScreenClient;
delete window.module;
if(typeof window.iClubQaV21ScreenClient!=="function")
 throw Error("Synthetic V2 transport could not be initialized");
