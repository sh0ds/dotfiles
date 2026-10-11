-- ~/.config/hypr/rice.lua  (loaded from hyprland.lua with pcall(require, "rice"))
-- Everything that makes it look and move the way it does, plus the extra keys.
-- An error in here shows the red bar but leaves the rest of your config running. To turn it all off, comment
-- out the require line in hyprland.lua.
-- Every option below exists in Hyprland 0.56 (checked against the v0.56.1 source).

local mod = "SUPER"

-- Your scripts live in ~/.local/bin. A login through SDDM doesn't read
-- .bashrc, so Hyprland (and everything it starts: keybinds, swaync buttons,
-- hyprlock) wouldn't find them. Put the folder on Hyprland's own PATH.
local bin  = os.getenv("HOME") .. "/.local/bin"
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
        gaps_in  = 5,
        gaps_out = 10,
        -- Lets games marked "immediate" below skip vsync: lowest input lag.
        allow_tearing = true,
        -- Only the focused window carries the blue-to-mauve border; the rest
        -- fade to a near-invisible outline, so the screen reads calmer.
        col = {
            active_border   = { colors = {"rgba(89b4faee)", "rgba(cba6f7ee)"}, angle = 45 },
            inactive_border = "rgba(31324466)",
        },
    },
    decoration = {
        rounding       = 12,
        -- Softer "squircle" corners (2 is a plain circle arc).
        rounding_power = 3,
        -- Depth instead of decoration: a wide, soft shadow under the focused
        -- window and a fainter one under the rest.
        shadow = {
            enabled        = true,
            range          = 20,
            render_power   = 3,
            color          = 0x6611111b,
            color_inactive = 0x3311111b,
        },
        -- Unfocused windows 12% darker, so the focused one stands out.
        dim_inactive = true,
        dim_strength = 0.12,
        -- Soft mauve light inside the focused window's edge.
        glow = {
            enabled        = true,
            range          = 12,
            render_power   = 3,
            color          = 0x55cba6f7,
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
        vrr                     = 3,
        animate_manual_resizes  = true,
        -- Open mpv or imv from kitty and the image/video takes the terminal's place.
        enable_swallow = true,
        swallow_regex  = "^(kitty)$",
    },
    -- Tabbed groups (SUPER+G): Catppuccin tab bar above grouped windows.
    group = {
        col = {
            border_active   = "rgba(cba6f7ee)",
            border_inactive = "rgba(45475aaa)",
        },
        groupbar = {
            font_size   = 11,
            height      = 18,
            gradients   = true,
            rounding    = 6,
            text_color  = "rgba(1e1e2eff)",
            text_color_inactive = "rgba(cdd6f4ff)",
            col = {
                active   = "rgba(cba6f7ee)",
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
hl.curve("md3",   { type = "bezier", points = { {0.05, 0.7}, {0.1, 1} } })
hl.curve("md3in", { type = "bezier", points = { {0.3, 0},    {0.8, 0.15} } })

-- Windows: open with a gentle pop, move and resize on the spring, close fast.
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 4.5, spring = "glide", style = "popin 87%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4.5, spring = "glide" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 1.5, bezier = "md3in", style = "popin 87%" })
hl.animation({ leaf = "fadeIn",      enabled = true, speed = 3,   bezier = "md3" })
hl.animation({ leaf = "fadeOut",     enabled = true, speed = 2,   bezier = "md3in" })
-- Focus changes: border colour, glow and dimming cross-fade instead of jumping.
hl.animation({ leaf = "border",      enabled = true, speed = 5,   bezier = "md3" })
hl.animation({ leaf = "fadeSwitch",  enabled = true, speed = 5,   bezier = "md3" })
hl.animation({ leaf = "fadeDim",     enabled = true, speed = 5,   bezier = "md3" })
hl.animation({ leaf = "fadeGlow",    enabled = true, speed = 5,   bezier = "md3" })
hl.animation({ leaf = "fadeShadow",  enabled = true, speed = 5,   bezier = "md3" })
-- Bar, launcher, notifications, power menu: pop in, fade out.
hl.animation({ leaf = "layersIn",      enabled = true, speed = 3,   bezier = "md3",   style = "popin" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 2,   bezier = "md3in", style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 2.5, bezier = "md3" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.5, bezier = "md3in" })
-- Right-click menus and tooltips fade too.
hl.animation({ leaf = "fadePopupsIn",  enabled = true, speed = 2,   bezier = "md3" })
-- Workspaces slide 15% and cross-fade. Kept short (0.35 s): you switch
-- workspaces hundreds of times a day.
hl.animation({ leaf = "workspaces",       enabled = true, speed = 3.5, bezier = "md3", style = "slidefade 15%" })
-- Every scratchpad (SoundCloud, chat, music, btop, drop-down terminal, quick note) slides all the way
-- down from the top edge, the same way.
-- Plain "slidevert" picks the direction itself (SoundCloud came up from the
-- bottom), so pin it: in from the top edge, out back up through the top.
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 4,   bezier = "md3",   style = "slidevert top" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 3,   bezier = "md3in", style = "slidevert bottom" })

--------------------------------------
---- LAYERS: blur behind the bars ----
--------------------------------------

-- Frosted glass behind waybar, notifications, launcher, power menu and OSD.
-- Check the names with `hyprctl layers` if one isn't blurred.
hl.layer_rule({
    name  = "frosted-layers",
    match = { namespace = "^(waybar|swaync-control-center|swaync-notification-window|launcher|logout_dialog|swayosd)$" },
    blur  = true,
    ignore_alpha = 0.3,
})

-- The notification centre and notification popups slide in from the right
-- edge and slide back out, instead of the generic pop. Works because swaync's
-- "layer-shell-cover-screen" is off, so its layer is only as wide as the panel.
hl.layer_rule({
    name      = "swaync-slide",
    match     = { namespace = "^(swaync-control-center|swaync-notification-window)$" },
    animation = "slide right",
})

---------------------------------------------
---- SMART GAPS: one window fills the screen ----
---------------------------------------------

-- A workspace with a single tiled window drops its gaps, border and rounding,
-- so nvim alone gets every pixel. Open a second window and the gaps come back.
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.window_rule({
    name        = "smart-gaps",
    match       = { float = false, workspace = "w[tv1]" },
    border_size = 0,
    rounding    = 0,
})

----------------------
---- WINDOW RULES ----
----------------------

-- Every drop-down window (SoundCloud, WhatsApp, music, terminal, notes, btop)
-- floats in the same frame: 62% wide, 45% high (btop gets more height),
-- centred under the bar, each in its own scratchpad so they slide in and out
-- one at a time.
local function dropdown(name, match, scratchpad, opacity, height)
    hl.window_rule({
        name      = name,
        match     = match,
        float     = true,
        size      = { "(monitor_w*0.62)", "(monitor_h*" .. (height or 0.45) .. ")" },
        move      = { "(monitor_w*0.19)", 52 },
        opacity   = opacity,
        workspace = "special:" .. scratchpad .. " silent",
    })
end

-- SoundCloud app (PWAsForFirefox), SUPER+S. Firefox isn't see-through on its
-- own, so it gets the same glass as kitty here.
-- Matched by the app's ID, not the page title: the title changes with every
-- page and track (and SoundCloud's home page even spells it "Soundcloud").
-- Use your own ID from `firefoxpwa profile list` (same one as in hyprland.lua).
local soundcloud = "FFPWA-01M4E9WM9PSN126GWCCEG49J4C"
dropdown("soundcloud-scratch", { class = "^" .. soundcloud .. "$" }, "scratch", "0.92")
-- Firefox resizes itself right after opening, so the size above can get lost.
-- Snap SoundCloud back into the drop-down frame whenever it
-- opens or its title changes (every new track).
local function snap_soundcloud(w)
    if not (w and w.floating and w.class == soundcloud) then return end
    local m = w.monitor
    if not m then return end
    local mw, mh = m.width / m.scale, m.height / m.scale
    hl.dispatch(hl.dsp.window.resize({ x = math.floor(mw * 0.62), y = math.floor(mh * 0.45), window = w }))
    hl.dispatch(hl.dsp.window.move({ x = m.x + math.floor(mw * 0.19), y = m.y + 52, window = w }))
end
hl.on("window.open", snap_soundcloud)
hl.on("window.title", snap_soundcloud)
-- WhatsApp: nchat in a kitty (SUPER+I, ~/.local/bin/chat)
dropdown("chat",      { class = "^chat$" },      "chat")
-- Music: rmpc in a kitty (SUPER+U, ~/.local/bin/music)
dropdown("music",     { class = "^music$" },     "music")
-- Network settings (right-click the network icon): nmtui floating in the middle
hl.window_rule({
    name   = "nmtui",
    match  = { class = "^nmtui$" },
    float  = true,
    size   = { "(monitor_w*0.4)", "(monitor_h*0.55)" },
    center = true,
})
-- System monitor: btop (CTRL+SHIFT+Escape or click "stats", ~/.local/bin/sysmon).
-- Taller than the others, btop needs the rows.
dropdown("sysmon",    { class = "^sysmon$" },    "sysmon", nil, 0.7)
-- "Update" in the update notification: pacman -Syu floating in the middle
hl.window_rule({
    name   = "update",
    match  = { class = "^update$" },
    float  = true,
    size   = { "(monitor_w*0.5)", "(monitor_h*0.5)" },
    center = true,
})
-- Drop-down terminal (SUPER+Z, ~/.local/bin/dropterm)
dropdown("dropterm",  { class = "^dropterm$" },  "term")
-- Quick note: nvim on ~/notes/inbox.md (SUPER+O, ~/.local/bin/quicknote)
dropdown("quicknote", { class = "^quicknote$" }, "notes")

-- Steam lives on workspace 5, together with the games it starts, so gaming
-- never reshuffles the workspaces you code on.
hl.window_rule({
    name      = "steam-main",
    match     = { class = "^steam$", title = "^Steam$" },
    workspace = "5 silent",
})
-- Friends list: a slim floating column at the right edge, under the bar.
hl.window_rule({
    name  = "steam-friends",
    match = { class = "^steam$", title = "^Friends List$" },
    float = true,
    size  = { 380, "(monitor_h*0.7)" },
    move  = { "(monitor_w-390)", 52 },
})
-- Every other Steam window (settings, game properties, chats, update and
-- install dialogs) floats in the middle instead of squeezing the tiles.
-- Steam's own corner pop-ups (notificationtoasts_*) are left where Steam puts them.
hl.window_rule({
    name   = "steam-dialogs",
    match  = { class = "^steam$", title = "negative:^(Steam|Friends List|notificationtoasts_.*)$" },
    float  = true,
    center = true,
})
-- Games (Steam and Proton both name them steam_app_<id>): workspace 5, marked
-- as game content so misc.vrr = 3 turns adaptive sync on, allowed to tear for
-- the lowest input lag, and the screen never dims or locks mid-match.
hl.window_rule({
    name         = "steam-games",
    match        = { class = "^steam_app_\\d+$" },
    workspace    = "5",
    content      = "game",
    immediate    = true,
    idle_inhibit = "fullscreen",
})

-- Audacity gets workspace 4 to itself, and while it's open the screen never
-- locks or suspends, so a long recording doesn't get cut off.
hl.window_rule({
    name         = "audacity",
    match        = { class = "(?i)audacity" },
    workspace    = "4",
    idle_inhibit = "always",
})

-- Proton Pass (SUPER+SHIFT+P) floats in the middle instead of tiling.
-- The class is matched loosely since the app doesn't set one of its own.
hl.window_rule({
    name   = "proton-pass",
    match  = { class = "(?i)^proton.?pass$" },
    float  = true,
    size   = { "(monitor_w*0.5)", "(monitor_h*0.65)" },
    center = true,
})

-- Firefox picture-in-picture video: small, bottom right, on every workspace.
hl.window_rule({
    name  = "pip",
    match = { title = "^Picture-in-Picture$" },
    float = true,
    pin   = true,
    size  = { 480, 270 },
    move  = { "(monitor_w-500)", "(monitor_h-290)" },
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
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark; "
        .. "gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark; "
        .. "gsettings set org.gnome.desktop.interface accent-color purple; "
        .. "gsettings set org.gnome.desktop.interface cursor-theme catppuccin-mocha-dark-cursors")
    hl.exec_cmd("udiskie")
    hl.exec_cmd("playerctld daemon")
    hl.exec_cmd("update-check --watch")
end)

-- Drop-down terminal on SUPER+Z (starts it the first time, then shows/hides it)
hl.bind(mod .. " + Z",              hl.dsp.exec_cmd("dropterm"))
-- WhatsApp (nchat) on SUPER+I, same idea
hl.bind(mod .. " + I",              hl.dsp.exec_cmd("chat"))
-- Music player (rmpc) on SUPER+U, same idea
hl.bind(mod .. " + U",              hl.dsp.exec_cmd("music"))
-- Files: yazi in a kitty (SUPER+E)
hl.bind(mod .. " + E",              hl.dsp.exec_cmd("kitty -e yazi"))
-- Task manager: btop slides down, same key as on Windows
hl.bind("CTRL + SHIFT + Escape",    hl.dsp.exec_cmd("sysmon"))
-- Emoji picker in fuzzel, types the one you pick
hl.bind(mod .. " + period",         hl.dsp.exec_cmd("emoji"))
-- Proton Pass. Pressing it again while it's open brings the window back.
hl.bind(mod .. " + SHIFT + P",      hl.dsp.exec_cmd("proton-pass"))
-- Unmount every USB stick so it is safe to pull out
hl.bind(mod .. " + SHIFT + U",      hl.dsp.exec_cmd("udiskie-umount -ad && notify-send -a USB \"Safe to unplug\""))
-- Tabbed groups: SUPER+G groups/ungroups, SUPER+Tab cycles the tabs
hl.bind(mod .. " + G",              hl.dsp.group.toggle())
hl.bind(mod .. " + Tab",            hl.dsp.group.next())
-- Next random wallpaper from ~/Pictures/walls (needs awww and wall-next)
hl.bind(mod .. " + W",              hl.dsp.exec_cmd("wall-next"))
-- Notification centre (swaync)
hl.bind(mod .. " + N",              hl.dsp.exec_cmd("swaync-client -t -sw"))
-- Floating windows: SUPER+V now floats the window AND puts it in the middle of
-- the screen (the base config's SUPER+V only floated it where it was).
-- SUPER+X re-centres the focused floating window after you've dragged it.
hl.unbind(mod .. " + V")
hl.bind(mod .. " + V", function()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    hl.dispatch(hl.dsp.window.center())   -- no-op when it just went back to tiling
end)
hl.bind(mod .. " + X", hl.dsp.window.center())

-- Power menu (wlogout)
hl.bind(mod .. " + SHIFT + Escape", hl.dsp.exec_cmd("wlogout -b 4"))
-- Colour picker: click anywhere, hex code lands in the clipboard
hl.bind(mod .. " + SHIFT + C",      hl.dsp.exec_cmd("hyprpicker -a"))
-- Screenshot a region and draw on it before saving (satty)
hl.bind("CTRL + Print",             hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | satty --filename - --output-filename ~/Pictures/shot-%Y%m%d-%H%M%S.png --copy-command wl-copy"))
-- Calculator in fuzzel (qalc): "15% of 89", "300 EUR to USD"
hl.bind(mod .. " + C",              hl.dsp.exec_cmd("calc"))
-- Night light on/off
hl.bind(mod .. " + SHIFT + N",      hl.dsp.exec_cmd("nightlight"))
-- Record a region to ~/Videos (press again to stop); waybar shows a red REC pill
hl.bind(mod .. " + SHIFT + R",      hl.dsp.exec_cmd("rec-toggle"))
-- Window switcher: every open window in a fuzzel list, Enter jumps to it
hl.bind("ALT + Tab",                hl.dsp.exec_cmd("winswitch"))
-- Hide or show the bar, for a clean screen while reading or sharing
hl.bind(mod .. " + SHIFT + B",      hl.dsp.exec_cmd("pkill -SIGUSR1 waybar"))
-- Copy the text inside a screen region (OCR): error messages in videos, PDFs, screenshots
hl.bind(mod .. " + SHIFT + T",      hl.dsp.exec_cmd("ocr"))
-- Quick note: drop-down nvim on ~/notes/inbox.md, same slide as the terminal
hl.bind(mod .. " + O",              hl.dsp.exec_cmd("quicknote"))
-- Docs search: "h foldr", "w hyprland", "m printf" (see the docs script)
hl.bind(mod .. " + D",              hl.dsp.exec_cmd("docs"))
-- Audacity: starts it, or jumps to workspace 4 if it's already open
hl.bind(mod .. " + SHIFT + A",      hl.dsp.exec_cmd("pgrep -x audacity >/dev/null && hyprctl dispatch 'hl.dsp.focus({ workspace = 4 })' || audacity"))
