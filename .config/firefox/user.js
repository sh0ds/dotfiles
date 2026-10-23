// Firefox prefs for the Diag look. `firefox-style` links this into your
// profile; Firefox reads it at every start, so changes in about:config to
// these prefs don't stick (edit this file instead).

// Load chrome/userChrome.css and userContent.css
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
// Built-in dark theme underneath, so anything the CSS misses is still dark
user_pref("extensions.activeThemeID", "firefox-compact-dark@mozilla.org");
user_pref("browser.theme.toolbar-theme", 0);
user_pref("browser.theme.content-theme", 0);
// Websites that have a dark mode use it
user_pref("layout.css.prefers-color-scheme.content-override", 0);
// Vertical tabs in the sidebar, like the rest of the setup
user_pref("sidebar.revamp", true);
user_pref("sidebar.verticalTabs", true);
// A plain black new tab: no sponsored tiles, stories or weather
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.newtabpage.activity-stream.showWeather", false);
// Native Wayland popups and menus look like the rest when they're square
user_pref("widget.gtk.rounded-bottom-corners.enabled", false);
