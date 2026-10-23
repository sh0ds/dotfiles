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
	mode = "highrr",
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
	hl.exec_cmd("hypridle")
	hl.exec_cmd("systemctl --user start hyprpolkitagent")
	hl.exec_cmd("wl-paste --watch cliphist store")
	hl.exec_cmd("swaync")
	hl.exec_cmd("swayosd-server")
	hl.exec_cmd("awww-daemon")
	-- Solid black instead of a picture. SUPER+W still picks one from ~/Pictures/walls.
	hl.exec_cmd("sleep 1 && awww clear 000000")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("XCURSOR_THEME", "Adwaita")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct") -- Qt apps in Diag (~/.config/qt6ct)
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- NVIDIA only. Delete these two lines on AMD or Intel.
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Plain defaults here, no animations; the Diag look (colours, gaps,
-- borders, animations) is set in rice.lua and overrides these.
hl.config({
	general = {
		gaps_in = 0,
		gaps_out = 0,
		border_size = 1,
		col = {
			active_border = "rgb(1793d1)",
			inactive_border = "rgb(2e353d)",
		},
		resize_on_border = true,
		allow_tearing = false,
		layout = "dwindle",
	},

	decoration = {
		rounding = 0,
		shadow = {
			enabled = false,
		},
		blur = {
			enabled = false,
		},
	},

	animations = {
		enabled = false,
	},
})

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
		-- German layout. Change to "us" if you type on US.
		kb_layout = "de",
		kb_variant = "",
		-- Caps Lock becomes Escape: you'll press Escape constantly in nvim and tmux copy mode.
		kb_options = "caps:escape",
		follow_mouse = 1,
		sensitivity = 0,
	},
})

---------------------
---- KEYBINDINGS ----
---------------------

local mod = "SUPER"

-- Apps
hl.bind(mod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + A", hl.dsp.exec_cmd(terminal .. " -e site-dev")) -- sh0ds.dev tmux session
hl.bind(mod .. " + Space", hl.dsp.exec_cmd(menu))
hl.bind(mod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mod .. " + Escape", hl.dsp.exec_cmd(lock))
hl.bind(mod .. " + SHIFT + V", hl.dsp.exec_cmd("cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"))

-- Screenshots: region to clipboard, the screen you're on to ~/Pictures
-- (plain grim would glue both monitors into one wide picture)
hl.bind("Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(
	"grim -o \"$(hyprctl activeworkspace -j | jq -r .monitor)\" ~/Pictures/shot-$(date +%Y%m%d-%H%M%S).png"
))

-- Windows
hl.bind(mod .. " + Q", hl.dsp.window.close())
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mod .. " + M", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mod .. " + P", hl.dsp.window.pseudo())
hl.bind(mod .. " + T", hl.dsp.layout("togglesplit"))

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
hl.bind(mod .. " + CTRL + S", hl.dsp.window.move({ workspace = "special:scratch" }))
-- Same as Windows: snip a region to the clipboard
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))

-- Mouse
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Media keys (work on the lock screen too). No brightness keys: a desktop
-- monitor's brightness is set on the monitor itself.
local media = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"), media)
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"), media)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), media)
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

-- The volume mixer floats instead of tiling.
hl.window_rule({
	name = "float-utilities",
	match = { class = "^org.pulseaudio.pavucontrol$" },
	float = true,
})

pcall(require, "rice")
