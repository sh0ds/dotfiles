-- ~/.config/hypr/hyprland.lua  (Hyprland 0.55+, Lua config)
-- Built from the upstream v0.56.1 example config. Every hl.* call here exists
-- in that release. Reference: https://wiki.hypr.land/configuring/
-- Reload: Hyprland reloads this file on save. Errors show as a red bar on top.

------------------
---- MONITORS ----
------------------

-- `hyprctl monitors` lists names, e.g. "DP-1". One catch-all is enough to start.
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = "auto",
})

-----------------
---- PROGRAMS ---
-----------------

local terminal = "kitty"
local menu = "fuzzel"
local browser = "firefox"
local lock = "pidof hyprlock || hyprlock"

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
	hl.exec_cmd("waybar")
	hl.exec_cmd("mako")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("systemctl --user start hyprpolkitagent")
	hl.exec_cmd("wl-paste --watch cliphist store")
	-- Wallpaper: put an image at ~/Pictures/wall.png, or keep the solid colour.
	hl.exec_cmd(
		"if [ -f ~/Pictures/wall.png ]; then swaybg -m fill -i ~/Pictures/wall.png; else swaybg -c '#1e1e2e'; fi"
	)
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("XCURSOR_THEME", "catppuccin-mocha-dark-cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- NVIDIA only (see the install guide, step A3). Uncomment both lines.
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Colours: Catppuccin Mocha, shared with kitty, waybar, tmux, mako, fuzzel.
hl.config({
	general = {
		gaps_in = 4,
		gaps_out = 8,
		border_size = 2,
		col = {
			active_border = { colors = { "rgba(89b4faee)", "rgba(cba6f7ee)" }, angle = 45 },
			inactive_border = "rgba(45475aaa)",
		},
		resize_on_border = true,
		allow_tearing = false,
		layout = "dwindle",
	},

	decoration = {
		rounding = 8,
		rounding_power = 2,
		active_opacity = 1.0,
		inactive_opacity = 0.95,
		shadow = {
			enabled = true,
			range = 6,
			render_power = 3,
			color = 0xee11111b,
		},
		blur = {
			enabled = true,
			size = 4,
			passes = 2,
			vibrancy = 0.1696,
		},
	},

	animations = {
		enabled = true,
	},
})

-- Snappier than the defaults: you'll switch workspaces hundreds of times a day.
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 3.5, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3, bezier = "easeOutQuint", style = "popin 90%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.5, bezier = "linear", style = "popin 90%" })
hl.animation({ leaf = "fade", enabled = true, speed = 2.5, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "easeOutQuint" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.8, bezier = "almostLinear", style = "fade" })

hl.config({
	dwindle = {
		preserve_split = true,
	},
	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
	},
})

---------------
---- INPUT ----
---------------

hl.config({
	input = {
		-- German layout assumed (Europe/Berlin install). Change to "us" if you type on US.
		kb_layout = "de",
		kb_variant = "",
		-- Caps Lock becomes Escape: you'll press Escape constantly in nvim and tmux copy mode.
		kb_options = "caps:escape",
		follow_mouse = 1,
		sensitivity = 0,
		touchpad = {
			natural_scroll = true,
		},
	},
})

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

---------------------
---- KEYBINDINGS ----
---------------------

local mod = "SUPER"

-- Apps
hl.bind(mod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + A", hl.dsp.exec_cmd(terminal .. " -e arena-dev")) -- Pi Arena tmux session
hl.bind(mod .. " + Space", hl.dsp.exec_cmd(menu))
hl.bind(mod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mod .. " + Escape", hl.dsp.exec_cmd(lock))
hl.bind(mod .. " + SHIFT + V", hl.dsp.exec_cmd("cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"))

-- Screenshots: region to clipboard, full screen to ~/Pictures
hl.bind("Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("grim ~/Pictures/shot-$(date +%Y%m%d-%H%M%S).png"))

-- Windows
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mod .. " + M", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mod .. " + P", hl.dsp.window.pseudo())
hl.bind(mod .. " + T", hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + SHIFT + E", hl.dsp.exit())

-- Focus, move, resize with vim keys (arrows work too)
local dirs = { H = "left", J = "down", K = "up", L = "right", left = "left", down = "down", up = "up", right = "right" }
local step = { left = { x = -40, y = 0 }, right = { x = 40, y = 0 }, up = { x = 0, y = -40 }, down = { x = 0, y = 40 } }
for key, dir in pairs(dirs) do
	hl.bind(mod .. " + " .. key, hl.dsp.focus({ direction = dir }))
	hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = dir }))
	hl.bind(
		mod .. " + CTRL + " .. key,
		hl.dsp.window.resize({ x = step[dir].x, y = step[dir].y, relative = true }),
		{ repeating = true }
	)
end

-- Workspaces 1-10, move window with SHIFT
for i = 1, 10 do
	local key = i % 10
	hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scratchpad
hl.bind(mod .. " + S", hl.dsp.workspace.toggle_special("scratch"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:scratch" }))

-- Mouse
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media and brightness keys (work on the lock screen too)
local media = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), media)
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), media)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), media)
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), media)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), media)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), media)
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

hl.window_rule({
	name = "suppress-maximize-events",
	match = { class = ".*" },
	suppress_event = "maximize",
})

hl.window_rule({
	name = "fix-xwayland-drags",
	match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
	no_focus = true,
})

-- Small utility windows float instead of tiling.
-- Erlang's observer (week 18) is a wx window; it tiles, which suits it.
hl.window_rule({
	name = "float-utilities",
	match = { class = "^(org.pulseaudio.pavucontrol|nm-connection-editor|blueman-manager)$" },
	float = true,
})
