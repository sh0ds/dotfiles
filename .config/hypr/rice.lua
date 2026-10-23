-- ~/.config/hypr/rice.lua  (loaded from hyprland.lua with pcall(require, "rice"))
-- Everything that makes it look and move the way it does, plus the extra keys.
-- An error is logged by the base config, which stays usable. To turn it all off, comment
-- out the require line in hyprland.lua.
-- Every option below exists in Hyprland 0.56 (checked against the v0.56.1 source).

local mod = "SUPER"

-- Your scripts live in ~/.local/bin. A login through SDDM doesn't read
-- .bashrc, so Hyprland (and everything it starts: keybinds, swaync buttons,
-- hyprlock) wouldn't find them. Put the folder on Hyprland's own PATH.
local bin = os.getenv("HOME") .. "/.local/bin"
local path = os.getenv("PATH") or "/usr/local/bin:/usr/bin"
if not (":" .. path .. ":"):find(":" .. bin .. ":", 1, true) then
	hl.env("PATH", bin .. ":" .. path)
end

------------------------------------
---- LOOK: Diag, flat and exact ----
------------------------------------

-- Diag: the look of sh0ds.dev (Terminess, key: value lines, double rules,
-- inverted blocks) in Arch Linux colours: black, cool greys and one Arch
-- blue. Square corners, 2 px borders like the site's rules, small gaps, no
-- shadows, no blur, no dimming. Motion is small and physical: damped
-- springs, no bounce (see MOTION). The focused window is the only thing on
-- screen with colour in its frame.
-- Palette (the same everywhere: kitty, waybar, swaync, fuzzel, GTK, nvim):
--   bg #000000  row #161a1f  rule #3f4650  dim #5d6670  mid #8a929c
--   fg #c4c9ce  ink #e6e8ea  arch #1793d1  warn #ffb000  error #e5484d
hl.config({
	general = {
		-- 3 px between windows (two inner gaps meet, so 6 px of black), 6 px
		-- to the screen edge.
		gaps_in = 3,
		gaps_out = 6,
		border_size = 2,
		-- Lets games marked "immediate" below skip vsync: lowest input lag.
		allow_tearing = true,
		col = {
			active_border = "rgb(1793d1)",
			inactive_border = "rgb(3f4650)",
		},
	},
	decoration = {
		rounding = 0,
		active_opacity = 1.0,
		inactive_opacity = 1.0,
		shadow = { enabled = false },
		blur = { enabled = false },
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
			gradients = false,
			rounding = 0,
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
---- MOTION: measured, not decorated ----
------------------------------------

-- Two rules. Anything that moves is a critically damped spring; anything
-- that only appears or disappears is a short linear fade.
--
-- Why springs: Hyprland steps them with the exact solution of the spring
-- equation, so the motion is the same at any frame rate, and when a move is
-- interrupted (SUPER+arrow twice, fast) the window keeps its velocity and
-- bends towards the new target instead of restarting. Critically damped
-- (damping = 2 * sqrt(stiffness * mass)) is the fastest a spring can settle
-- without overshooting: no bounce, ever. speed is ignored for springs, the
-- physics sets the duration.
--
-- Amplitude stays tiny: windows scale 3 %, workspaces shift 8 %. The eye
-- reads the direction, nothing travels across the screen.
-- Exits are about twice as fast as entries, so closing never waits.
--
-- Three timings, nothing else (bezier speed is in 100 ms steps):
--   80 ms   popups and menus
--   120 ms  fades, focus frame, exits
--   ~110 ms to 90 % / ~190 ms to rest, every spring
hl.curve("settle", { type = "spring", mass = 1, stiffness = 1225, dampening = 70 })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })

-- Windows: open from 97 % with a fade, close to 98 % twice as fast. Tiles
-- glide to their new place when the layout changes.
hl.animation({ leaf = "windowsIn", enabled = true, speed = 1, spring = "settle", style = "popin 97%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.2, bezier = "linear", style = "popin 98%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 1, spring = "settle" })

-- Fades. Opacity never changes on focus here, so fadeSwitch is off with the
-- dim, shadow and glow fades (all of those are disabled in LOOK). Screen
-- off/on (DPMS) gets a slow 400 ms fade instead of a hard cut.
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.2, bezier = "linear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.2, bezier = "linear" })
hl.animation({ leaf = "fadeSwitch", enabled = false })
hl.animation({ leaf = "fadeDim", enabled = false })
hl.animation({ leaf = "fadeShadow", enabled = false })
hl.animation({ leaf = "fadeGlow", enabled = false })
hl.animation({ leaf = "fadePopupsIn", enabled = true, speed = 0.8, bezier = "linear" })
hl.animation({ leaf = "fadePopupsOut", enabled = true, speed = 0.8, bezier = "linear" })
hl.animation({ leaf = "fadeDpms", enabled = true, speed = 4, bezier = "linear" })

-- The focus frame changes colour in 120 ms, the same time the bar's
-- workspace block takes (waybar style.css), so both land together.
hl.animation({ leaf = "border", enabled = true, speed = 1.2, bezier = "linear" })
hl.animation({ leaf = "borderangle", enabled = false })

-- Workspaces: an 8 % sideways shift under a cross-fade, so you see which
-- way you went without the whole screen sliding past.
hl.animation({ leaf = "workspaces", enabled = true, speed = 1, spring = "settle", style = "slidefade 8%" })

-- Layers (launcher, notifications, OSD, power menu): fade in on the spring,
-- out linear. The rules below give each one its own entrance.
hl.animation({ leaf = "layersIn", enabled = true, speed = 1, spring = "settle", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.2, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.2, bezier = "linear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1, bezier = "linear" })
-- A new monitor just appears.
hl.animation({ leaf = "monitorAdded", enabled = false })

-- The bar is the fixed frame of the screen: it never animates. Neither do
-- screenshot selection (slurp) and the colour picker, which have to be
-- there the instant you press the key.
hl.layer_rule({ name = "still-bar", match = { namespace = "^waybar$" }, no_anim = true })
hl.layer_rule({ name = "still-tools", match = { namespace = "^(selection|hyprpicker)$" }, no_anim = true })
-- Launcher and calculator open from 96 %, like a window but a touch more.
hl.layer_rule({ name = "launcher-pop", match = { namespace = "^launcher$" }, animation = "popin 96%" })
-- Notifications and their panel come in from the right edge they live on.
hl.layer_rule({ name = "notify-slide", match = { namespace = "^swaync-(control-center|notification-window)$" }, animation = "slide right" })

------------------------------------------------
---- SMART GAPS: one window fills the screen ----
------------------------------------------------

-- A workspace with a single tiled window drops its gaps and border, so nvim
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

-- Quick apps (SoundCloud, calendar, WhatsApp, mail, music, btop)
-- are normal tiled windows. Each has one key that goes through
-- ~/.local/bin/app --toggle: start it next to what you're doing, press again
-- to hide it, press again to bring it back tiled where you are. If it's
-- visible on another workspace, the key jumps there.

-- SoundCloud app (PWAsForFirefox), SUPER+S. Matched by the app's ID, not the
-- page title, which changes with every track. Use your own ID from
-- `firefoxpwa profile list`.
local soundcloud = "01M4E9WM9PSN126GWCCEG49J4C"
hl.unbind(mod .. " + S")
hl.unbind(mod .. " + CTRL + S")
hl.bind(mod .. " + S", hl.dsp.exec_cmd("app --toggle '^FFPWA-" .. soundcloud .. "$' firefoxpwa site launch " .. soundcloud))
-- Proton Calendar app (PWAsForFirefox), SUPER+Y or a click on the clock.
-- Its ID lives in ~/.local/bin/calendar.
hl.bind(mod .. " + Y", hl.dsp.exec_cmd("calendar"))
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

-- Firefox picture-in-picture video: small, bottom right, on every workspace.
hl.window_rule({
	name = "pip",
	match = { title = "^Picture-in-Picture$" },
	float = true,
	pin = true,
	size = { 480, 270 },
	move = { "(monitor_w-500)", "(monitor_h-290)" },
	keep_aspect_ratio = true,
})

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
			.. "gsettings set org.gnome.desktop.interface font-name 'Terminess Nerd Font 12'; "
			.. "gsettings set org.gnome.desktop.interface monospace-font-name 'Terminess Nerd Font Mono 12'; "
			.. "gsettings set org.gnome.desktop.interface cursor-theme Adwaita"
	)
	hl.exec_cmd("udiskie")
	hl.exec_cmd("playerctld daemon")
	hl.exec_cmd("update-check --watch")
	hl.exec_cmd("/usr/lib/kdeconnectd")
	hl.exec_cmd("kdeconnect-indicator") -- optional tray icon
	-- Mail: Proton's Bridge in the tray, then aerc hidden (special:hidden,
	-- where `app --toggle` parks windows) so new mail shows up as
	-- notifications from the start; SUPER+SHIFT+I brings it in
	hl.exec_cmd("protonmail-bridge --no-window")
	hl.exec_cmd("kitty --class mail -e aerc", { workspace = "special:hidden silent" })
	-- aria2 in the background, Firefox hands its downloads to it
	hl.exec_cmd("aria2-rpc")
	-- Easy Effects without a window: the headphone EQ and limiter (docs/audio.md)
	hl.exec_cmd("easyeffects --service-mode --hide-window")
end)

-- WhatsApp (nchat) on SUPER+I, same idea
hl.bind(mod .. " + I", hl.dsp.exec_cmd("chat"))
-- Mail (aerc) on SUPER+SHIFT+I, next to it
hl.bind(mod .. " + SHIFT + I", hl.dsp.exec_cmd("inbox"))
-- Music player (rmpc) on SUPER+U, same idea
hl.bind(mod .. " + U", hl.dsp.exec_cmd("music"))
-- Files: yazi in a kitty (SUPER+E)
hl.bind(mod .. " + E", hl.dsp.exec_cmd("kitty -e yazi"))
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
-- Notification centre (swaync)
hl.bind(mod .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw"))
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
-- Record a region to ~/Videos (press again to stop); waybar shows REC in blue
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("rec-toggle"))
-- Window switcher: every open window in a fuzzel list, Enter jumps to it
hl.bind("ALT + Tab", hl.dsp.exec_cmd("winswitch"))
-- Hide or show the bar, for a clean screen while reading or sharing
hl.bind(mod .. " + SHIFT + B", hl.dsp.exec_cmd("pkill -SIGUSR1 waybar"))
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
