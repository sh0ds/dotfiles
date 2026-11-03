-- ~/.config/hypr/rice.lua  (loaded from hyprland.lua with pcall(require, "rice"))
-- Everything that makes it look and move the way it does, plus the extra keys.
-- An error is logged by the base config, which stays usable. To turn it all off, comment
-- out the require line in hyprland.lua.
-- Every option below exists in Hyprland 0.56 (checked against the v0.56.1 source).

local mod = "SUPER"

-- Your scripts live in ~/.local/bin. A login through SDDM doesn't read
-- .bashrc, so Hyprland (and everything it starts: keybinds, notification centre buttons,
-- hyprlock) wouldn't find them. Put the folder on Hyprland's own PATH.
local bin = os.getenv("HOME") .. "/.local/bin"
local path = os.getenv("PATH") or "/usr/local/bin:/usr/bin"
if not (":" .. path .. ":"):find(":" .. bin .. ":", 1, true) then
	hl.env("PATH", bin .. ":" .. path)
end

------------------------------------
---- LOOK: Diag, softened ----------
------------------------------------

-- Diag: the colours and type of sh0ds.dev (Terminess, black, cool greys,
-- one Arch blue), with softer edges: 10 px squircle corners, a blue
-- gradient frame on the focused window, roomy gaps, a deep soft shadow and
-- frosted glass behind the bar, notifications, launcher and terminal.
-- Motion is physical: damped springs and eased fades, no bounce (see
-- MOTION). The focused window is the only thing on screen with colour in
-- its frame.
-- Palette (the same everywhere: kitty, quickshell, fuzzel, GTK, Helix):
--   bg #000000  row #161a1f  rule #3f4650  dim #5d6670  mid #8a929c
--   fg #c4c9ce  ink #e6e8ea  arch #1793d1  warn #ffb000  error #e5484d
hl.config({
	general = {
		-- 8 px between neighbouring tiles, 10 px at the edge (the bar
		-- floats 6 px down and 10 px in, so windows line up under its ends).
		gaps_in = 4,
		gaps_out = 10,
		border_size = 2,
		-- Lets games marked "immediate" below skip vsync: lowest input lag.
		allow_tearing = true,
		col = {
			-- Arch blue into a lighter sky blue. `frame` swaps the pair for
			-- amber while recording and grey under do-not-disturb.
			active_border = { colors = { "rgb(1793d1)", "rgb(6cc4f0)" }, angle = 45 },
			inactive_border = "rgba(3f465066)",
		},
	},
	decoration = {
		rounding = 10,
		-- Between a circle (2) and a square: the corners curve in smoothly
		-- instead of starting with a hard edge.
		rounding_power = 2.6,
		active_opacity = 1.0,
		inactive_opacity = 1.0,
		-- A wide, soft shadow that falls slightly down, like light from above.
		shadow = { enabled = true, range = 30, render_power = 2, offset = { 0, 6 }, color = "rgba(000000d0)", color_inactive = "rgba(00000080)" },
		-- Frosted glass for anything see-through: the bar, notifications,
		-- launcher and the terminal (kitty is 92 % opaque). Vibrancy keeps
		-- the blue behind it from turning to grey mush.
		blur = { enabled = true, size = 7, passes = 3, vibrancy = 0.25, noise = 0.012, contrast = 1.0, brightness = 0.85, popups = true },
		dim_inactive = false,
		glow = { enabled = false },
		motion_blur = { enabled = false },
	},
	animations = {
		enabled = true,
	},
	-- 180 Hz: VRR only for fullscreen games, so the desktop stays at a steady
	-- 180 and never flickers; games get adaptive sync and direct scanout
	-- (lower latency).
	render = {
		direct_scanout = 2,
	},
	misc = {
		vrr = 3,
		-- Open mpv or imv from kitty and the image/video takes the terminal's place.
		enable_swallow = true,
		swallow_regex = "^(kitty)$",
	},
	-- Tabbed groups (SUPER+G): a flat tab strip, blue for the active tab.
	group = {
		col = {
			border_active = "rgb(1793d1)",
			border_inactive = "rgb(3f4650)",
		},
		groupbar = {
			font_family = "Terminess Nerd Font",
			font_size = 16,
			height = 22,
			gradients = true,
			rounding = 6,
			gradient_rounding = 6,
			text_color = "rgb(000000)",
			text_color_inactive = "rgb(8a929c)",
			col = {
				active = "rgb(1793d1)",
				inactive = "rgb(0d1014)",
			},
		},
	},
})

------------------------------------
---- MOTION: smooth, never slow ----
------------------------------------

-- Two rules. Anything that moves is a critically damped spring; anything
-- that only appears, disappears or changes colour is an eased fade.
--
-- Why springs: Hyprland steps them with the exact solution of the spring
-- equation, so the motion is the same at any frame rate, and when a move is
-- interrupted (SUPER+arrow twice, fast) the window keeps its velocity and
-- bends towards the new target instead of restarting. Critically damped
-- (dampening = 2 * sqrt(stiffness * mass)) is the fastest a spring can
-- settle without overshooting: no bounce, ever. speed is ignored for
-- springs, the physics sets the duration.
--
-- Why eased fades: a linear fade starts and stops abruptly, which reads as
-- a flicker at 180 Hz. "glide" (ease-out quint) does most of the change in
-- the first third and then lands softly; "exit" (ease-in) leaves quickly.
--
-- Amplitude stays small: windows grow from 90 %, workspaces shift 12 %. The
-- eye reads the direction, nothing travels across the screen. Exits are
-- faster than entries, so closing never waits.
--
-- Timings (bezier speed is in 100 ms steps):
--   120 ms  exits
--   200 ms  fades, layers and every colour change (bar, menus and
--           notifications use the same 200 ms ease-out in their CSS)
--   ~170 ms to 90 % / ~290 ms to 99 %   "settle", windows
--   ~200 ms to 90 % / ~340 ms to 99 %   "drift", workspaces
-- Softer springs than before: still no overshoot, but a longer, calmer
-- landing that reads as smooth rather than snappy.
hl.curve("settle", { type = "spring", mass = 1, stiffness = 520, dampening = 46 })
hl.curve("drift", { type = "spring", mass = 1, stiffness = 380, dampening = 39 })
hl.curve("glide", { type = "bezier", points = { { 0.22, 1 }, { 0.36, 1 } } })
hl.curve("exit", { type = "bezier", points = { { 0.4, 0 }, { 1, 1 } } })

-- Windows: grow in from 90 % with a fade, shrink to 95 % on the way out.
-- Tiles glide to their new place when the layout changes.
hl.animation({ leaf = "windowsIn", enabled = true, speed = 1, spring = "settle", style = "popin 90%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.2, bezier = "exit", style = "popin 95%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 1, spring = "settle" })

-- Fades. Opacity never changes on focus here, so fadeSwitch is off with the
-- dim and glow fades (both disabled in LOOK). The shadow fades with its
-- window. Screen off/on (DPMS) gets a slow 400 ms fade instead of a hard cut.
hl.animation({ leaf = "fadeIn", enabled = true, speed = 2, bezier = "glide" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.2, bezier = "exit" })
hl.animation({ leaf = "fadeSwitch", enabled = false })
hl.animation({ leaf = "fadeDim", enabled = false })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 2, bezier = "glide" })
hl.animation({ leaf = "fadeGlow", enabled = false })
hl.animation({ leaf = "fadePopupsIn", enabled = true, speed = 2, bezier = "glide" })
hl.animation({ leaf = "fadePopupsOut", enabled = true, speed = 1.2, bezier = "exit" })
hl.animation({ leaf = "fadeDpms", enabled = true, speed = 4, bezier = "glide" })

-- The focus frame changes colour in 200 ms, the same time the bar's
-- workspace marker takes (the bar, quickshell/Workspaces.qml), so both land together.
hl.animation({ leaf = "border", enabled = true, speed = 2, bezier = "glide" })
hl.animation({ leaf = "borderangle", enabled = false })

-- Workspaces: a 12 % sideways drift under a cross-fade, so you see which
-- way you went without the whole screen sliding past. A softer spring than
-- windows, because the whole screen changes.
hl.animation({ leaf = "workspaces", enabled = true, speed = 1, spring = "drift", style = "slidefade 12%" })

-- Layers fade in 200 ms. The launcher keeps its pixel font at native size
-- (scaling blurs Terminess); notifications slide in from the edge they
-- live on.
hl.animation({ leaf = "layersIn", enabled = true, speed = 2, bezier = "glide", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.2, bezier = "exit", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 2, bezier = "glide" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.2, bezier = "exit" })
-- A new monitor just appears.
hl.animation({ leaf = "monitorAdded", enabled = false })

-- The bar is the fixed frame of the screen: it never animates. Neither do
-- screenshot selection (slurp) and the colour picker, which have to be
-- there the instant you press the key.
hl.layer_rule({ name = "still-bar", match = { namespace = "^diag-bar$" }, no_anim = true })
-- The volume popup grows in a little, like a window.
hl.layer_rule({ name = "osd-pop", match = { namespace = "^diag-osd$" }, animation = "popin 92%" })
-- Frosted glass behind the see-through panels. ignore_alpha skips the
-- fully clear parts (the gap around the floating bar, shadows), so only
-- the panels themselves are blurred.
hl.layer_rule({
	name = "glass",
	match = { namespace = "^(diag-bar|diag-osd|launcher|logout_dialog|diag-notes|diag-center)$" },
	blur = true,
	blur_popups = true,
	ignore_alpha = 0.3,
})
hl.layer_rule({ name = "still-tools", match = { namespace = "^(selection|hyprpicker)$" }, no_anim = true })
-- Launcher and calculator fade without enlarging the text.
hl.layer_rule({ name = "launcher-fade", match = { namespace = "^launcher$" }, animation = "fade" })
-- Notifications and their panel slide in from the right edge.
hl.layer_rule({ name = "notify-slide", match = { namespace = "^diag-(notes|center)$" }, animation = "slide right" })

------------------------------------------------
---- SMART GAPS: one window fills the screen ----
------------------------------------------------

-- A workspace with a single tiled window drops its gaps and border, so the editor
-- alone gets every pixel. Open a second window and they come back.
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.window_rule({
	name = "smart-borders",
	match = { float = false, workspace = "w[tv1]" },
	border_size = 0,
})

----------------------
---- WINDOW RULES ----
----------------------

-- Quick apps (SoundCloud, WhatsApp, music, btop)
-- are normal tiled windows. Each has one key that goes through
-- ~/.local/bin/app --toggle: start it next to what you're doing, press again
-- to hide it, press again to bring it back tiled where you are. If it's
-- visible on another workspace, the key jumps there.

-- Rename, extraction, confirmations and preferences must not split the grid.
-- Keep the application's natural dialog size; cap it to the logical output.
hl.window_rule({
	name = "file-manager-modal-dialogs",
	match = { class = "(?i)^(thunar|org\\.xfce\\.thunar|xarchiver)$", modal = true },
	float = true,
	center = true,
	max_size = { "(monitor_w*0.8)", "(monitor_h*0.8)" },
})
-- Some GTK/Wayland versions omit the modal hint on the F2 dialog.
-- Anchored titles avoid matching ordinary folder windows ending in - Thunar.
hl.window_rule({
	name = "thunar-rename-dialog",
	match = { class = "(?i)^(thunar|org\\.xfce\\.thunar)$", title = '^(Rename ".*"|".*" umbenennen)$' },
	float = true,
	center = true,
	max_size = { "(monitor_w*0.8)", "(monitor_h*0.8)" },
})
-- Properties is deliberately non-modal in Thunar; it still belongs above
-- the browser rather than taking half of the working grid.
hl.window_rule({
	name = "thunar-properties-dialog",
	match = { class = "(?i)^(thunar|org\\.xfce\\.thunar)$", title = "^(Properties|.* - Properties|Eigenschaften|.* - Eigenschaften)$" },
	float = true,
	center = true,
	max_size = { "(monitor_w*0.8)", "(monitor_h*0.8)" },
})

-- Xarchiver's extraction window is a dialog but is not always marked modal.
hl.window_rule({
	name = "archive-action-dialogs",
	match = {
		class = "(?i)^xarchiver$",
		title = "(?i)^(Extract files|Multi-Extract|Add files|Preferences|Password|Password required|Archive properties|Dateien entpacken|Entpacken|Mehrfach.entpacken|Dateien hinzuf.gen|Einstellungen|Passwort.*|Archiveigenschaften)$",
	},
	float = true,
	center = true,
	max_size = { "(monitor_w*0.8)", "(monitor_h*0.8)" },
})

-- SoundCloud app (PWAsForFirefox), SUPER+S. Matched by the app's ID, not the
-- page title, which changes with every track. Use your own ID from
-- `firefoxpwa profile list`.
local soundcloud = "01M4E9WM9PSN126GWCCEG49J4C"
hl.unbind(mod .. " + S")
hl.unbind(mod .. " + CTRL + S")
hl.bind(mod .. " + S", hl.dsp.exec_cmd("app --toggle '^FFPWA-" .. soundcloud .. "$' firefoxpwa site launch " .. soundcloud))
-- Network settings (right-click the network icon): nmtui floating in the middle
hl.window_rule({
	name = "nmtui",
	match = { class = "^nmtui$" },
	float = true,
	size = { "(monitor_w*0.4)", "(monitor_h*0.55)" },
	center = true,
})
-- "Update" in the update notification: the system update floating in the middle
hl.window_rule({
	name = "update",
	match = { class = "^update$" },
	float = true,
	size = { "(monitor_w*0.5)", "(monitor_h*0.5)" },
	center = true,
})

-- Steam lives on workspace 5, together with the games it starts, so gaming
-- never reshuffles the workspaces you code on.
hl.window_rule({
	name = "steam-main",
	match = { class = "^steam$", title = "^Steam$" },
	workspace = "5 silent",
})
-- Friends list: a slim floating column at the top right edge.
hl.window_rule({
	name = "steam-friends",
	match = { class = "^steam$", title = "^Friends List$" },
	float = true,
	size = { 380, "(monitor_h*0.7)" },
	move = { "(monitor_w-386)", 6 },
})
-- Every other Steam window (settings, game properties, chats, update and
-- install dialogs) floats in the middle instead of squeezing the tiles.
-- Steam's own corner pop-ups (notificationtoasts_*) are left where Steam puts them.
hl.window_rule({
	name = "steam-dialogs",
	match = { class = "^steam$", title = "negative:^(Steam|Friends List|notificationtoasts_.*)$" },
	float = true,
	center = true,
})
-- Games (Steam and Proton both name them steam_app_<id>): workspace 5, marked
-- as game content so misc.vrr = 3 turns adaptive sync on, allowed to tear for
-- the lowest input lag, and the screen never dims or locks mid-match.
hl.window_rule({
	name = "steam-games",
	match = { class = "^steam_app_\\d+$" },
	workspace = "5",
	content = "game",
	immediate = true,
	idle_inhibit = "fullscreen",
})

-- PICO-8 and Picotron (pico8, picotron, from the launcher) tile where you
-- start them instead of going to workspace 5: they're as much an editor as a
-- game. Marked as game content for adaptive sync, the screen stays on while
-- one is fullscreen, and a single tile gets the whole screen (smart gaps), so
-- the pixel-perfect picture sits centred on Diag black.
hl.window_rule({
	name = "fantasy-consoles",
	match = { class = "(?i)^(pico-?8.*|picotron)$" },
	content = "game",
	idle_inhibit = "fullscreen",
})

-- Game dev (docs/gamedev.md). A game started from the Godot editor (F5)
-- floats centred at its own size over the editor instead of squeezing it
-- into half a tile; Godot titles that window "<project> (DEBUG)".
hl.window_rule({
	name = "godot-run",
	match = { title = "\\(DEBUG\\)$" },
	float = true,
	center = true,
})
-- Bitwig keeps the screen awake while it has focus: listening back to a
-- mix for ten minutes without touching anything is normal.
hl.window_rule({
	name = "bitwig",
	match = { class = "(?i)bitwig" },
	idle_inhibit = "focus",
})

-- GameMode for every game, no Steam launch options needed: when a game's
-- window opens, gamemoded switches it on for that process, and it switches
-- off by itself when the game quits. Each process is only asked once, since
-- asking twice would toggle it back off (launchers open several windows).
local gamemode_pids = {}
hl.on("window.open", function(w)
	if not (w and w.class and w.class:match("^steam_app_%d+$")) then
		return
	end
	local pid = w.pid
	if not pid or pid <= 0 or gamemode_pids[pid] then
		return
	end
	gamemode_pids[pid] = true
	hl.exec_cmd("gamemoded -r" .. pid)
end)

-- Everything DJ (Lexicon, rekordbox, Traktor, Audacity) lives in a Windows VM
-- (djvm, SUPER+SHIFT+M) on workspace 7. The screen stays on while it has focus,
-- and the SUPER keys keep working in it instead of going to Windows.
hl.window_rule({
	name = "dj-vm",
	match = { class = "(?i).*virt-viewer.*" },
	workspace = "7",
	idle_inhibit = "focus",
	no_shortcuts_inhibit = true,
})

-- Proton Pass (SUPER+SHIFT+P) floats in the middle instead of tiling.
-- The class is matched loosely since the app doesn't set one of its own.
hl.window_rule({
	name = "proton-pass",
	match = { class = "(?i)^proton.?pass$" },
	float = true,
	size = { "(monitor_w*0.5)", "(monitor_h*0.65)" },
	center = true,
})

-- Firefox picture-in-picture joins the normal tile grid on its workspace.
-- Firefox fits the video inside the tile; the layout controls the window size.
hl.window_rule({
	name = "firefox-pip-tiled",
	match = {
		class = "(?i)^(firefox.*|org\\.mozilla\\.firefox)$",
		title = "^(Picture-in-Picture|Bild-im-Bild)$",
	},
	tile = true,
	pin = false,
})

require("firefox-pip")

------------------------
---- TOOLS AND KEYS ----
------------------------

-- USB sticks mount themselves when plugged in (udiskie, ~/.config/udiskie).
-- playerctld tracks which player was used last, so the media keys, the bar
-- and the lock screen follow rmpc or SoundCloud, whichever is playing,
-- instead of always grabbing the first one.
-- update-check sends a notification when Arch updates pile up.
-- gsettings: GTK apps and file pickers go dark (adw-gtk3 + Diag gtk.css).
hl.on("hyprland.start", function()
	hl.exec_cmd(
		"gsettings set org.gnome.desktop.interface color-scheme prefer-dark; "
			.. "gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark; "
			.. "gsettings set org.gnome.desktop.interface accent-color blue; "
			.. "gsettings set org.gnome.desktop.interface font-name 'Terminess Nerd Font Mono 13.5'; "
			.. "gsettings set org.gnome.desktop.interface monospace-font-name 'Terminess Nerd Font Mono 13.5'; "
			.. "gsettings set org.gnome.desktop.interface cursor-theme Posy_Cursor_Black; "
			.. "gsettings set org.gnome.desktop.interface cursor-size 32"
	)
	-- Hyprland draws its own cursor and can start with the default one even
	-- with XCURSOR_THEME set, so name the theme once it's running.
	hl.exec_cmd("hyprctl setcursor Posy_Cursor_Black 32")
	-- The focus frame turns amber while recording or sharing, grey on
	-- do-not-disturb (~/.local/bin/frame).
	hl.exec_cmd("frame")
	-- The wallpaper's dot grid shows your LOG.md days (wall-streak), and
	-- five diagnostic lines sit bottom left on the main screen (readout,
	-- in a kitty panel on the background layer: windows cover it, and it
	-- reserves no space).
	hl.exec_cmd("sleep 2 && wall-streak --watch")
	hl.exec_cmd(
		"kitty +kitten panel --edge=bottom --layer=background --lines=5 "
			.. "--margin-left=40 --margin-bottom=32 --exclusive-zone=0 --override-exclusive-zone "
			.. "--output-name=DP-4 -o background_opacity=0 readout"
	)
	hl.exec_cmd("udiskie")
	hl.exec_cmd("playerctld daemon")
	hl.exec_cmd("update-check --watch")
	hl.exec_cmd("/usr/lib/kdeconnectd")
	hl.exec_cmd("kdeconnect-indicator") -- optional tray icon
	-- aria2 in the background, Firefox hands its downloads to it
	hl.exec_cmd("aria2-rpc")
	-- Easy Effects without a window: the headphone EQ and limiter (docs/audio.md)
	hl.exec_cmd("easyeffects --service-mode --hide-window")
end)

-- WhatsApp (nchat) on SUPER+I, same idea
hl.bind(mod .. " + I", hl.dsp.exec_cmd("chat"))
-- Music player (rmpc) on SUPER+U, same idea
hl.bind(mod .. " + U", hl.dsp.exec_cmd("music"))
-- Files: Thunar uses the same GTK Diag palette and tiles normally (SUPER+E).
hl.bind(mod .. " + E", hl.dsp.exec_cmd("thunar"))
-- Task manager: btop, same key as on Windows
hl.bind("CTRL + SHIFT + Escape", hl.dsp.exec_cmd("sysmon"))
-- Emoji picker in fuzzel, types the one you pick
hl.bind(mod .. " + period", hl.dsp.exec_cmd("emoji"))
-- Proton Pass. Pressing it again while it's open brings the window back.
hl.bind(mod .. " + SHIFT + P", hl.dsp.exec_cmd("proton-pass"))
-- Unmount every USB stick so it is safe to pull out
hl.bind(mod .. " + SHIFT + U", hl.dsp.exec_cmd('udiskie-umount -ad && notify-send -a USB "Safe to unplug"'))
-- Tabbed groups: SUPER+G groups/ungroups, SUPER+Tab cycles the tabs
hl.bind(mod .. " + G", hl.dsp.group.toggle())
hl.bind(mod .. " + Tab", hl.dsp.group.next())
-- Notification centre (Quickshell, Center.qml)
hl.bind(mod .. " + N", hl.dsp.exec_cmd("qs ipc call notes toggle"))
-- Floating windows: SUPER+V now floats the window AND puts it in the middle of
-- the screen (the base config's SUPER+V only floated it where it was).
-- SUPER+X re-centres the focused floating window after you've dragged it.
hl.unbind(mod .. " + V")
hl.bind(mod .. " + V", function()
	hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
	hl.dispatch(hl.dsp.window.center()) -- no-op when it just went back to tiling
end)
hl.bind(mod .. " + X", hl.dsp.window.center())

-- Power menu (wlogout)
hl.bind(mod .. " + SHIFT + Escape", hl.dsp.exec_cmd("power-menu"))
-- Colour picker: click anywhere, hex code lands in the clipboard
hl.bind(mod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))
-- Screenshot a region in a Diag frame with a caption, for devlogs (shot)
hl.bind("ALT + Print", hl.dsp.exec_cmd("shot"))
-- Screenshot a region and draw on it before saving (satty)
hl.bind(
	"CTRL + Print",
	hl.dsp.exec_cmd(
		'grim -g "$(slurp)" - | satty --filename - --output-filename ~/Pictures/shot-%Y%m%d-%H%M%S.png --copy-command wl-copy'
	)
)
-- Calculator in fuzzel (qalc): "15% of 89", "300 EUR to USD"
hl.bind(mod .. " + C", hl.dsp.exec_cmd("calc"))
-- Night light on/off
hl.bind(mod .. " + SHIFT + N", hl.dsp.exec_cmd("nightlight"))
-- Record a region to ~/Videos (press again to stop); the bar shows REC in amber
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("rec-toggle"))
-- Window switcher: every open window in a fuzzel list, Enter jumps to it
hl.bind("ALT + Tab", hl.dsp.exec_cmd("winswitch"))
-- Hide or show the bar, for a clean screen while reading or sharing
hl.bind(mod .. " + SHIFT + B", hl.dsp.exec_cmd("qs ipc call bar toggle"))
-- Copy the text inside a screen region (OCR): error messages in videos, PDFs, screenshots
hl.bind(mod .. " + SHIFT + T", hl.dsp.exec_cmd("ocr"))
-- Notes: Obsidian as a normal window, started or focused
hl.bind(mod .. " + O", hl.dsp.exec_cmd("notes"))
-- Every keybind in a searchable list (read from the README table)
hl.bind(mod .. " + F1", hl.dsp.exec_cmd("keys"))
-- Docs search: "h foldr", "w hyprland", "m printf" (see the docs script)
hl.bind(mod .. " + D", hl.dsp.exec_cmd("docs"))
-- The Windows DJ VM: start it, or jump to it if it's open
hl.bind(mod .. " + SHIFT + M", hl.dsp.exec_cmd("djvm"))
