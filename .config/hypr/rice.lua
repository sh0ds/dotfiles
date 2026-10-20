-- ~/.config/hypr/rice.lua  (loaded from hyprland.lua with pcall(require, "rice"))
-- Everything that makes it look and move the way it does, plus the extra keys.
-- An error in here shows the red bar but leaves the rest of your config running. To turn it all off, comment
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

---------------------------------
---- WINDOWS: depth and glow ----
---------------------------------

hl.config({
	-- One grid for the whole desktop: 10 px around the screen edge (the bar
	-- uses the same margin, so its pills line up with the window edges),
	-- 5 px between windows, 12 px corners on everything.
	general = {
		gaps_in = 5,
		gaps_out = 10,
		-- Lets games marked "immediate" below skip vsync: lowest input lag.
		allow_tearing = true,
		-- Only the focused window carries the blue-to-mauve border; the rest
		-- fade to a near-invisible outline, so the screen reads calmer.
		col = {
			active_border = { colors = { "rgba(89b4faee)", "rgba(cba6f7ee)" }, angle = 45 },
			inactive_border = "rgba(31324466)",
		},
	},
	decoration = {
		rounding = 12,
		-- Softer "squircle" corners (2 is a plain circle arc).
		rounding_power = 3,
		-- Depth instead of decoration: a wide, soft shadow under the focused
		-- window and a fainter one under the rest.
		shadow = {
			enabled = true,
			range = 20,
			render_power = 3,
			color = 0x6611111b,
			color_inactive = 0x3311111b,
		},
		-- Unfocused windows 12% darker, so the focused one stands out.
		dim_inactive = true,
		dim_strength = 0.12,
		-- Soft mauve light inside the focused window's edge.
		glow = {
			enabled = true,
			range = 12,
			render_power = 3,
			color = 0x55cba6f7,
			color_inactive = 0x00000000,
		},
		-- Slight smear while dragging or resizing a window.
		motion_blur = {
			enabled = true,
			samples = 7,
		},
	},
	-- 180 Hz: VRR only for fullscreen games, so the desktop stays at a steady
	-- 180 and never flickers; games get adaptive sync and direct scanout
	-- (lower latency). Keyboard resizes animate instead of jumping.
	render = {
		direct_scanout = 2,
	},
	misc = {
		vrr = 3,
		animate_manual_resizes = true,
		-- Open mpv or imv from kitty and the image/video takes the terminal's place.
		enable_swallow = true,
		swallow_regex = "^(kitty)$",
	},
	-- Tabbed groups (SUPER+G): Catppuccin tab bar above grouped windows.
	group = {
		col = {
			border_active = "rgba(cba6f7ee)",
			border_inactive = "rgba(45475aaa)",
		},
		groupbar = {
			font_size = 11,
			height = 18,
			gradients = true,
			rounding = 6,
			text_color = "rgba(1e1e2eff)",
			text_color_inactive = "rgba(cdd6f4ff)",
			col = {
				active = "rgba(cba6f7ee)",
				inactive = "rgba(313244ee)",
			},
		},
	},
})

-------------------------------------
---- MOTION: smoother animations ----
-------------------------------------

-- "glide" is a spring: windows ease into place and settle, with no bounce.
-- (dampening 25 is just under critical for stiffness 200, so it never wobbles.)
-- "md3" is Material 3's decelerate curve: fast start, long soft landing.
-- Durations are in time, not frames, so on a 180 Hz screen every animation
-- simply gets three times the frames of a 60 Hz one. The long tails of these
-- curves are where 180 Hz shows: the last few pixels of motion stay visible.
hl.curve("glide", { type = "spring", mass = 1, stiffness = 200, dampening = 25 })
hl.curve("md3", { type = "bezier", points = { { 0.05, 0.7 }, { 0.1, 1 } } })
hl.curve("md3in", { type = "bezier", points = { { 0.3, 0 }, { 0.8, 0.15 } } })

-- Windows: open with a gentle pop, move and resize on the spring, close fast.
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.5, spring = "glide", style = "popin 87%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4.5, spring = "glide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.5, bezier = "md3in", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 3, bezier = "md3" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 2, bezier = "md3in" })
-- Focus changes: border colour, glow and dimming cross-fade instead of jumping.
hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "md3" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 5, bezier = "md3" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 5, bezier = "md3" })
hl.animation({ leaf = "fadeGlow", enabled = true, speed = 5, bezier = "md3" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 5, bezier = "md3" })
-- Bar, launcher, notifications, power menu: pop in, fade out.
hl.animation({ leaf = "layersIn", enabled = true, speed = 3, bezier = "md3", style = "popin" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2, bezier = "md3in", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 2.5, bezier = "md3" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.5, bezier = "md3in" })
-- Right-click menus and tooltips fade too.
hl.animation({ leaf = "fadePopupsIn", enabled = true, speed = 2, bezier = "md3" })
-- Workspaces slide 15% and cross-fade. Kept short (0.35 s): you switch
-- workspaces hundreds of times a day.
hl.animation({ leaf = "workspaces", enabled = true, speed = 3.5, bezier = "md3", style = "slidefade 15%" })
-- Every scratchpad (SoundCloud, chat, music, btop, drop-down terminal, quick note) slides all the way
-- down from the top edge, the same way.
-- Plain "slidevert" picks the direction itself (SoundCloud came up from the
-- bottom), so pin it: in from the top edge, out back up through the top.
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 4, bezier = "md3", style = "slidevert top" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 3, bezier = "md3in", style = "slidevert bottom" })

--------------------------------------
---- LAYERS: blur behind the bars ----
--------------------------------------

-- Frosted glass behind waybar, notifications, launcher, power menu and OSD.
-- Check the names with `hyprctl layers` if one isn't blurred.
hl.layer_rule({
	name = "frosted-layers",
	match = { namespace = "^(waybar|swaync-control-center|swaync-notification-window|launcher|logout_dialog|swayosd)$" },
	blur = true,
	ignore_alpha = 0.3,
})

-- The notification centre and notification popups slide in from the right
-- edge and slide back out, instead of the generic pop. Works because swaync's
-- "layer-shell-cover-screen" is off, so its layer is only as wide as the panel.
hl.layer_rule({
	name = "swaync-slide",
	match = { namespace = "^(swaync-control-center|swaync-notification-window)$" },
	animation = "slide right",
})

---------------------------------------------
---- SMART GAPS: one window fills the screen ----
---------------------------------------------

-- A workspace with a single tiled window drops its gaps, border and rounding,
-- so nvim alone gets every pixel. Open a second window and the gaps come back.
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.window_rule({
	name = "smart-gaps",
	match = { float = false, workspace = "w[tv1]" },
	border_size = 0,
	rounding = 0,
})

----------------------
---- WINDOW RULES ----
----------------------

-- Every drop-down window (SoundCloud, WhatsApp, mail, music, terminal, btop,
-- Obsidian) floats in the same frame: 76% wide, 60% high, centred under the
-- bar, each in its own scratchpad so they slide in and out one at a time.
-- btop gets more height, Obsidian more of both, so notes stay easy to read.
local drop_w, drop_h = 0.76, 0.6
local function dropdown(name, match, scratchpad, opacity, height, width)
	local w, h = width or drop_w, height or drop_h
	hl.window_rule({
		name = name,
		match = match,
		float = true,
		size = { string.format("(monitor_w*%.2f)", w), string.format("(monitor_h*%.2f)", h) },
		move = { string.format("(monitor_w*%.2f)", (1 - w) / 2), 52 },
		opacity = opacity,
		workspace = "special:" .. scratchpad .. " silent",
	})
end

-- SoundCloud app (PWAsForFirefox), SUPER+S. Firefox isn't see-through on its
-- own, so it gets the same glass as kitty here.
-- Matched by the app's ID, not the page title: the title changes with every
-- page and track (and SoundCloud's home page even spells it "Soundcloud").
-- Use your own ID from `firefoxpwa profile list`. It starts hidden at login,
-- so SUPER+S is instant the first time too.
local soundcloud = "FFPWA-01M4E9WM9PSN126GWCCEG49J4C"
local soundcloud_cmd = "firefoxpwa site launch " .. soundcloud:sub(#"FFPWA-" + 1)
hl.on("hyprland.start", function()
	hl.exec_cmd(soundcloud_cmd)
end)
-- SUPER+S slides it in, and starts it again if you closed it.
hl.unbind(mod .. " + S")
hl.bind(mod .. " + S", hl.dsp.exec_cmd("scratch " .. soundcloud .. " scratch " .. soundcloud_cmd))
dropdown("soundcloud-scratch", { class = "^" .. soundcloud .. "$" }, "scratch", "0.92")
-- Proton Calendar app (PWAsForFirefox), SUPER+Y or a click on the clock.
-- Its ID is set in ~/.local/bin/calendar and read from there, so it lives in
-- one place. Started on first use only, it's another Firefox.
local calendar = "FFPWA-none"
local calfile = io.open(bin .. "/calendar")
if calfile then
	for line in calfile:lines() do
		calendar = line:match("^id=(FFPWA%-%w+)$") or calendar
	end
	calfile:close()
end
hl.bind(mod .. " + Y", hl.dsp.exec_cmd("calendar"))
dropdown("calendar", { class = "^" .. calendar .. "$" }, "calendar", "0.92")
-- Firefox resizes itself right after opening, so the size above can get lost.
-- Snap both web apps back into the drop-down frame whenever they open or
-- their title changes (every new track, every calendar view).
local web_apps = { [soundcloud] = true, [calendar] = true }
local function snap_web_app(w)
	if not (w and w.floating and web_apps[w.class]) then
		return
	end
	local m = w.monitor
	if not m then
		return
	end
	local mw, mh = m.width / m.scale, m.height / m.scale
	hl.dispatch(hl.dsp.window.resize({ x = math.floor(mw * drop_w), y = math.floor(mh * drop_h), window = w }))
	hl.dispatch(hl.dsp.window.move({ x = m.x + math.floor(mw * (1 - drop_w) / 2), y = m.y + 52, window = w }))
end
hl.on("window.open", snap_web_app)
hl.on("window.title", snap_web_app)
-- WhatsApp: nchat in a kitty (SUPER+I, ~/.local/bin/chat)
dropdown("chat", { class = "^chat$" }, "chat")
-- Mail: aerc in a kitty (SUPER+SHIFT+I, ~/.local/bin/inbox)
dropdown("mail", { class = "^mail$" }, "mail")
-- Music: rmpc in a kitty (SUPER+U, ~/.local/bin/music)
dropdown("music", { class = "^music$" }, "music")
-- Network settings (right-click the network icon): nmtui floating in the middle
hl.window_rule({
	name = "nmtui",
	match = { class = "^nmtui$" },
	float = true,
	size = { "(monitor_w*0.4)", "(monitor_h*0.55)" },
	center = true,
})
-- System monitor: btop (CTRL+SHIFT+Escape or click "stats", ~/.local/bin/sysmon).
-- Taller than the others, btop needs the rows.
dropdown("sysmon", { class = "^sysmon$" }, "sysmon", nil, 0.8)
-- "Update" in the update notification: the system update floating in the middle
hl.window_rule({
	name = "update",
	match = { class = "^update$" },
	float = true,
	size = { "(monitor_w*0.5)", "(monitor_h*0.5)" },
	center = true,
})
-- Drop-down terminal (SUPER+Z, ~/.local/bin/dropterm)
dropdown("dropterm", { class = "^dropterm$" }, "term")
-- Notes: Obsidian on the ~/notes vault (SUPER+O, ~/.local/bin/notes).
-- Bigger than the rest: 84% wide and nearly full height, for reading.
dropdown("notes", { class = "^md\\.obsidian\\.Obsidian$" }, "notes", nil, 0.88, 0.84)

-- Steam lives on workspace 5, together with the games it starts, so gaming
-- never reshuffles the workspaces you code on.
hl.window_rule({
	name = "steam-main",
	match = { class = "^steam$", title = "^Steam$" },
	workspace = "5 silent",
})
-- Friends list: a slim floating column at the right edge, under the bar.
hl.window_rule({
	name = "steam-friends",
	match = { class = "^steam$", title = "^Friends List$" },
	float = true,
	size = { 380, "(monitor_h*0.7)" },
	move = { "(monitor_w-390)", 52 },
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
-- Old School RuneScape: RuneLite, started from the Bolt launcher (SUPER+R).
-- It tiles like any other window and fills its tile (Resizable mode just
-- shows more of the world in a taller tile).
-- It's Java, so the class is its package name (net-runelite-client-RuneLite).
-- The screen stays awake while it has focus, since half of OSRS is standing
-- still clicking once a minute.
hl.window_rule({
	name = "runelite",
	match = { class = "(?i).*runelite.*", title = "RuneLite.*" }, -- rules must match the whole string
	content = "game",
	idle_inhibit = "focus",
	no_dim = true, -- stays bright on the side while you work, so you see when you stop fishing
})
-- Java opens every RuneLite tooltip and menu as its own window, titled
-- "win0", "win1" and so on (or nothing). Those float where they pop up and
-- never take focus, otherwise focus flickers between them and the game every
-- time you hover something. Dialogs with a real title behave normally.
hl.window_rule({
	name = "runelite-popups",
	match = { class = "(?i).*runelite.*", title = "(win\\d+)?" },
	float = true,
	no_focus = true,
	no_initial_focus = true,
})
-- When RuneLite opens:
-- 1. It comes to the workspace you're looking at. Hyprland opens windows where
--    their app was started, and RuneLite is started by Bolt, which may still
--    be sitting on another workspace from earlier.
-- 2. It gets its own full-height column (movetoroot swaps it with the other
--    column), 1300px wide. Tiling ignores Java's
--    minimum size, and the game plus plugin panel needs about 1050px, so a
--    quarter tile used to cut off the right edge. Alone on a workspace it
--    just takes the whole screen and the layout messages do nothing.
hl.on("window.open", function(w)
	if
		not (
			w
			and not w.floating
			and w.class
			and w.class:lower():find("runelite")
			and w.title
			and w.title:match("^RuneLite")
		)
	then
		return
	end
	local here = hl.get_active_workspace()
	if here and w.workspace and w.workspace.id ~= here.id then
		hl.dispatch(hl.dsp.window.move({ workspace = here, window = w }))
	end
	hl.dispatch(hl.dsp.focus({ window = w })) -- both layout messages act on the focused window
	hl.dispatch(hl.dsp.layout("movetoroot"))
	local mon, at = w.monitor, w.at
	if not (mon and at) then
		return
	end
	-- splitratio sizes the left column: 1.0 is half, 2.0 would be all of it
	local share = math.min(1.6, 2 * 1300 / mon.width)
	local left = at.x < mon.x + mon.width / 2
	hl.dispatch(hl.dsp.layout(string.format("splitratio %.3f exact", left and share or 2 - share)))
end)
-- Bolt (the login launcher) floats in the middle of the screen.
hl.window_rule({
	name = "bolt",
	match = { class = "(?i).*bolt.*", title = "negative:^$" },
	float = true,
	size = { "(monitor_w*0.5)", "(monitor_h*0.6)" },
	center = true,
})

-- GameMode for every game, no Steam launch options needed: when a game's
-- window opens, gamemoded switches it on for that process, and it switches
-- off by itself when the game quits. Each process is only asked once, since
-- asking twice would toggle it back off (launchers open several windows).
-- OSRS is left out on purpose: it barely uses the PC, and GameMode's
-- do-not-disturb would hide RuneLite's idle notifications ("you stopped
-- fishing"), which are the whole point of playing it on a second screen.
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

-- Audacity gets workspace 4 to itself, and while it's open the screen never
-- locks or suspends, so a long recording doesn't get cut off.
hl.window_rule({
	name = "audacity",
	match = { class = "(?i)audacity" },
	workspace = "4",
	idle_inhibit = "always",
})

-- Music making: Bitwig Studio on workspace 6. The screen stays on while it's
-- open, so it never locks halfway through arranging a track. Plugin windows (synths,
-- effects) run in Bitwig's plugin host and float on top instead of squeezing
-- the arrangement into a tile.
hl.window_rule({
	name = "bitwig",
	match = { class = "(?i).*bitwig.*" },
	workspace = "6",
	idle_inhibit = "always",
})
hl.window_rule({
	name = "bitwig-plugins",
	match = { class = "(?i).*pluginhost.*" },
	float = true,
	center = true,
})

-- DJ library: Mixo (AppImage) on workspace 7.
hl.window_rule({
	name = "mixo",
	match = { class = "^MIXO$" },
	workspace = "7",
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
-- gsettings: GTK apps and file pickers go dark (adw-gtk3 + Mocha gtk.css).
hl.on("hyprland.start", function()
	hl.exec_cmd(
		"gsettings set org.gnome.desktop.interface color-scheme prefer-dark; "
			.. "gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark; "
			.. "gsettings set org.gnome.desktop.interface accent-color purple; "
			.. "gsettings set org.gnome.desktop.interface cursor-theme catppuccin-mocha-dark-cursors"
	)
	hl.exec_cmd("udiskie")
	hl.exec_cmd("playerctld daemon")
	hl.exec_cmd("update-check --watch")
	hl.exec_cmd("/usr/lib/kdeconnectd")
	hl.exec_cmd("kdeconnect-indicator") -- optional tray icon
	-- Mail: Proton's Bridge in the tray, then aerc hidden in its drop-down so
	-- new mail shows up as notifications from the start
	hl.exec_cmd("protonmail-bridge --no-window")
	hl.exec_cmd("kitty --class mail -e aerc")
end)

-- Drop-down terminal on SUPER+Z (starts it the first time, then shows/hides it)
hl.bind(mod .. " + Z", hl.dsp.exec_cmd("dropterm"))
-- WhatsApp (nchat) on SUPER+I, same idea
hl.bind(mod .. " + I", hl.dsp.exec_cmd("chat"))
-- Mail (aerc) on SUPER+SHIFT+I, next to it
hl.bind(mod .. " + SHIFT + I", hl.dsp.exec_cmd("inbox"))
-- Music player (rmpc) on SUPER+U, same idea
hl.bind(mod .. " + U", hl.dsp.exec_cmd("music"))
-- Files: yazi in a kitty (SUPER+E)
hl.bind(mod .. " + E", hl.dsp.exec_cmd("kitty -e yazi"))
-- Task manager: btop slides down, same key as on Windows
hl.bind("CTRL + SHIFT + Escape", hl.dsp.exec_cmd("sysmon"))
-- Emoji picker in fuzzel, types the one you pick
hl.bind(mod .. " + period", hl.dsp.exec_cmd("emoji"))
-- Proton Pass. Pressing it again while it's open brings the window back.
hl.bind(mod .. " + SHIFT + P", hl.dsp.exec_cmd("proton-pass"))
-- Old School RuneScape: jumps to RuneLite if it's open, else starts Bolt
hl.bind(mod .. " + R", hl.dsp.exec_cmd("osrs"))
-- Unmount every USB stick so it is safe to pull out
hl.bind(mod .. " + SHIFT + U", hl.dsp.exec_cmd('udiskie-umount -ad && notify-send -a USB "Safe to unplug"'))
-- Tabbed groups: SUPER+G groups/ungroups, SUPER+Tab cycles the tabs
hl.bind(mod .. " + G", hl.dsp.group.toggle())
hl.bind(mod .. " + Tab", hl.dsp.group.next())
-- Next random wallpaper from ~/Pictures/walls (needs awww and wall-next)
hl.bind(mod .. " + W", hl.dsp.exec_cmd("wall-next"))
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
hl.bind(mod .. " + SHIFT + Escape", hl.dsp.exec_cmd("wlogout -b 5"))
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
-- Record a region to ~/Videos (press again to stop); waybar shows a red REC pill
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("rec-toggle"))
-- Window switcher: every open window in a fuzzel list, Enter jumps to it
hl.bind("ALT + Tab", hl.dsp.exec_cmd("winswitch"))
-- Hide or show the bar, for a clean screen while reading or sharing
hl.bind(mod .. " + SHIFT + B", hl.dsp.exec_cmd("pkill -SIGUSR1 waybar"))
-- Copy the text inside a screen region (OCR): error messages in videos, PDFs, screenshots
hl.bind(mod .. " + SHIFT + T", hl.dsp.exec_cmd("ocr"))
-- Notes: Obsidian drops down like the terminal, started on first use
hl.bind(mod .. " + O", hl.dsp.exec_cmd("notes"))
-- Every keybind in a searchable list (read from the README table)
hl.bind(mod .. " + F1", hl.dsp.exec_cmd("keys"))
-- Docs search: "h foldr", "w hyprland", "m printf" (see the docs script)
hl.bind(mod .. " + D", hl.dsp.exec_cmd("docs"))
-- Audacity, Bitwig and Mixo: start it, or jump to it if it's open
hl.bind(mod .. " + SHIFT + A", hl.dsp.exec_cmd("app '(?i)audacity' audacity"))
hl.bind(mod .. " + SHIFT + D", hl.dsp.exec_cmd("app '(?i)bitwig' bitwig-studio"))
hl.bind(mod .. " + SHIFT + M", hl.dsp.exec_cmd("app '^MIXO$' mixo"))
