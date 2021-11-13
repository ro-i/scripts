/**
 * This is a minimal user.js for Mozilla Firefox based on https://github.com/arkenfox/user.js
 *
 * It tries to enable a basic privacy level while not breaking site functionality.
 * Additionally, it includes some personal preferences.
 *
 * See https://github.com/arkenfox/user.js/blob/master/LICENSE.txt for copyright
 * and license details.
 */


/*** [SECTION 0100]: STARTUP ***/
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.startup.page", 0);
user_pref("browser.startup.homepage", "about:blank");
user_pref("browser.newtabpage.enabled", false);
user_pref("browser.newtab.preload", false);
user_pref("browser.newtabpage.activity-stream.feeds.telemetry", false);
user_pref("browser.newtabpage.activity-stream.telemetry", false);
user_pref("browser.newtabpage.activity-stream.feeds.snippets", false); // [DEFAULT: false FF89+]
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.newtabpage.activity-stream.section.highlights.includePocket", false);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.feeds.discoverystreamfeed", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false); // [FF83+]
user_pref("browser.newtabpage.activity-stream.default.sites", "");


/*** [SECTION 0300]: QUIET FOX ***/
user_pref("app.update.auto", false);
user_pref("extensions.getAddons.showPane", false); // [HIDDEN PREF]
user_pref("extensions.htmlaboutaddons.recommendations.enabled", false);
user_pref("toolkit.telemetry.unified", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("toolkit.telemetry.server", "data:,");
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("toolkit.telemetry.newProfilePing.enabled", false);
user_pref("toolkit.telemetry.shutdownPingSender.enabled", false);
user_pref("toolkit.telemetry.updatePing.enabled", false);
user_pref("toolkit.telemetry.bhrPing.enabled", false);
user_pref("toolkit.telemetry.firstShutdownPing.enabled", false);
user_pref("toolkit.telemetry.coverage.opt-out", true); // [HIDDEN PREF]
user_pref("toolkit.coverage.opt-out", true);
user_pref("toolkit.coverage.endpoint.base", "");
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("app.shield.optoutstudies.enabled", false);
user_pref("browser.discovery.enabled", false);
user_pref("breakpad.reportURL", "");
user_pref("browser.tabs.crashReporting.sendReport", false);
user_pref("browser.crashReports.unsubmittedCheck.autoSubmit2", false);
user_pref("captivedetect.canonicalURL", "");
user_pref("network.captive-portal-service.enabled", false);
user_pref("network.connectivity-service.enabled", false);


/*** [SECTION 0500]: SYSTEM ADD-ONS / EXPERIMENTS ***/
user_pref("app.normandy.enabled", false);
user_pref("app.normandy.api_url", "");
user_pref("browser.ping-centre.telemetry", false);
user_pref("extensions.formautofill.addresses.enabled", false);
user_pref("extensions.formautofill.available", "off");
user_pref("extensions.formautofill.creditCards.available", false);
user_pref("extensions.formautofill.creditCards.enabled", false);
user_pref("extensions.formautofill.heuristics.enabled", false);
user_pref("extensions.webcompat-reporter.enabled", false);


/*** [SECTION 0800]: LOCATION BAR / SEARCH BAR / SUGGESTIONS / HISTORY / FORMS ***/
user_pref("keyword.enabled", false);
user_pref("browser.fixup.alternate.enabled", false);
user_pref("browser.urlbar.trimURLs", false);
user_pref("browser.search.suggest.enabled", false);
user_pref("browser.urlbar.suggest.searches", false);
user_pref("browser.urlbar.speculativeConnect.enabled", false);
user_pref("browser.urlbar.dnsResolveSingleWordsAfterSearch", 0);
user_pref("browser.urlbar.suggest.history", false);
user_pref("browser.urlbar.suggest.bookmark", false);
user_pref("browser.urlbar.suggest.openpage", false);
user_pref("browser.urlbar.maxRichResults", 0);
user_pref("browser.urlbar.autoFill", false);
user_pref("browser.formfill.enable", false);
user_pref("places.history.enabled", false);
user_pref("browser.taskbar.lists.enabled", false);
user_pref("browser.taskbar.lists.frequent.enabled", false);
user_pref("browser.taskbar.lists.recent.enabled", false);
user_pref("browser.taskbar.lists.tasks.enabled", false);


/*** [SECTION 0900]: PASSWORDS ***/
user_pref("signon.rememberSignons", false);


/*** [SECTION 1000]: CACHE / SESSION (RE)STORE / FAVICONS ***/
user_pref("browser.cache.disk.enable", false);
user_pref("browser.sessionstore.max_tabs_undo", 2);
user_pref("browser.sessionstore.privacy_level", 2);
user_pref("toolkit.winRegisterApplicationRestart", false);


/*** [SECTION 1700]: CONTAINERS ***/
user_pref("privacy.userContext.ui.enabled", true);
user_pref("privacy.userContext.enabled", true);


/*** [SECTION 2000]: MEDIA / CAMERA / MIC ***/
user_pref("media.autoplay.default", 5);


/*** [SECTION 2700]: PERSISTENT STORAGE ***/
user_pref("network.cookie.lifetimePolicy", 2);
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);


/*** [SECTION 2800]: SHUTDOWN ***/
user_pref("privacy.sanitize.sanitizeOnShutdown", true);
user_pref("privacy.clearOnShutdown.cache", true);
user_pref("privacy.clearOnShutdown.cookies", true);
user_pref("privacy.clearOnShutdown.downloads", true);
user_pref("privacy.clearOnShutdown.formdata", true);
user_pref("privacy.clearOnShutdown.history", true);
user_pref("privacy.clearOnShutdown.offlineApps", true);
user_pref("privacy.clearOnShutdown.sessions", true);
user_pref("privacy.clearOnShutdown.siteSettings", false);
user_pref("privacy.cpd.cache", true);
user_pref("privacy.cpd.cookies", true);
user_pref("privacy.cpd.formdata", true);
user_pref("privacy.cpd.history", true);
user_pref("privacy.cpd.offlineApps", true);
user_pref("privacy.cpd.passwords", false);
user_pref("privacy.cpd.sessions", true);
user_pref("privacy.cpd.siteSettings", false);
user_pref("privacy.sanitize.timeSpan", 0);


/*** [SECTION 4000]: FPI (FIRST PARTY ISOLATION) ***/
user_pref("privacy.firstparty.isolate", true);


/*** MISC ***/
/* APPEARANCE ***/
user_pref("browser.download.autohideButton", false);
/* UX BEHAVIOR ***/
user_pref("browser.backspace_action", 0);
user_pref("browser.tabs.closeWindowWithLastTab", false);
user_pref("browser.tabs.loadBookmarksInTabs", true);
user_pref("general.autoScroll", true);
user_pref("extensions.pocket.enabled", false);
user_pref("identity.fxaccounts.enabled", false);
/* OTHER ***/
user_pref("browser.bookmarks.max_backups", 2);


/*
 * settings not in user.js template
 */
user_pref("browser.ctrlTab.recentlyUsedOrder", false);
user_pref("browser.tabs.warnOnClose", true);
//user_pref("gfx.webrender.all", true); // Experimental!


user_pref("_user.js.parrot", "SUCCESS");

