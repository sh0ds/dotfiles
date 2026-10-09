-- ~/.config/hypr/rice.lua  (loaded from hyprland.lua with pcall(require, "rice"))
-- Visual extras from desktop-ricing-extras.md. An error in here shows the red
-- bar but leaves the rest of your config running. To turn it all off, comment
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

------------------------------
---- MOTION: smoother animations ----
------------------------------

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
-- Every scratchpad (music, drop-down terminal, quick note) slides all the way
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

-- The SoundCloud app (PWAsForFirefox) always opens into the music scratchpad.
hl.window_rule({
	name = "soundcloud-scratch",
	match = { class = "^FFPWA-", title = ".*SoundCloud.*" },
	float = true,
	size = { "(monitor_w*0.62)", "(monitor_h*0.45)" },
	move = { "(monitor_w*0.19)", 52 },
	opacity = "0.92",
	workspace = "special:scratch silent",
})

-- Drop-down terminal: a kitty with class "dropterm" lives in its own scratchpad.
hl.window_rule({
	name = "dropterm",
	match = { class = "^dropterm$" },
	float = true,
	size = { "(monitor_w*0.62)", "(monitor_h*0.45)" },
	move = { "(monitor_w*0.19)", 52 },
	workspace = "special:term silent",
})

-- Quick note: the same drop-down shape as dropterm, with nvim on ~/notes/inbox.md.
hl.window_rule({
	name = "quicknote",
	match = { class = "^quicknote$" },
	float = true,
	size = { "(monitor_w*0.62)", "(monitor_h*0.45)" },
	move = { "(monitor_w*0.19)", 52 },
	workspace = "special:notes silent",
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

-------------------------
---- TOOLS AND KEYS ----
-------------------------

-- Drop-down terminal on SUPER+Z (starts it the first time, then shows/hides it)
hl.bind(mod .. " + Z", hl.dsp.exec_cmd("dropterm"))
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
hl.bind(mod .. " + SHIFT + Escape", hl.dsp.exec_cmd("wlogout -b 4"))
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
-- Quick note: drop-down nvim on ~/notes/inbox.md, same slide as the terminal
hl.bind(mod .. " + O", hl.dsp.exec_cmd("quicknote"))
-- Docs search: "h foldr", "w hyprland", "m printf" (see the docs script)
hl.bind(mod .. " + D", hl.dsp.exec_cmd("docs"))
