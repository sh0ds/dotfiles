# Five Diag design passes

These are five successive source-level design passes, not five observed desktop
sessions. The palette stays black, cool grey and Arch blue. Each pass revisits
shell, window frame, panel, launcher, notifications, applications and motion;
changes accumulate into one final rice on `diag-unify`. Live rendering and frame
pacing still need the user's Arch/Hyprland machine.

## 1 — Console

Reimagine the desktop as a compact instrument console. Start from a 4px spacing
unit, 1px separators and 2px focus marks. Retain clear text instead of adding
more decoration to every application. Set 8px outer/tile spacing, consistent
terminal padding, a smaller launcher with readable placeholder text, an 18px OSD,
and panel offsets that align with the top rail. Existing app content stays
readable; diagrams, web pages and media keep their original colours.

The distinction is structural: surfaces provide grouping, blue marks the thing
being used, and semantic warning/error colours retain meaning. The background
and login/lock artwork already fit that system and remain intact.

## 2 — Workbench

Reimagine the rice as a workbench rather than a screen full of competing active
blocks. Browser/editor navigation uses a small blue rule; terminal app tabs use
a blue label on a quiet panel. Apply that hierarchy to Firefox, Obsidian,
Neovim, kitty, tmux, Yazi, rmpc and aerc. The compositor's group and explicit
mode indicators keep native inversion where it carries useful state. Reset
tmux cells so active styling does not leak to neighbouring windows.

Proton Calendar is removed at the user's request: retire its helper, SUPER+Y
binding, PWA instructions and external clock launch. Retain the native Waybar
month/year view. Leave the aerc calendar attachment filter intact; it displays
mail content and is not the removed PWA.

## 3 — Readable instruments

Reimagine the full rice as a display you can read for hours, not a photo with
attractive but faint secondary text. Fix blue-on-amber text in lazygit and
amber-on-red errors in Yazi. Use amber explicitly for Yazi's select mode. Make
Qt inactive text/placeholders and quoted mail readable. Give Neovim diagnostics
quiet solid surfaces, GTK/SwayNC switches a visible thumb, and keyboard focus
its own outline in Firefox and Vesktop. Narrow Electron selectors to semantic
buttons rather than guessing every class containing "button".

Keep code/content typography and semantic colours intact. Native widgets use
one accent and a small number of surfaces; the panel's top edge becomes a thin
blue rule, leaving more attention for notification content. The launcher,
clock, session console and terminal retain the preceding pass's simpler layout.

## 4 — Quiet motion

Reimagine the desktop as an instrument that responds immediately and then gets
out of the way. The shell and apps keep their crisp geometry; launcher and
notification text now fade at native size instead of scaling or travelling
across the screen. The bar and capture tools remain still. Preserve toolkit
motion and web reduced-motion support rather than disabling animations in
applications indiscriminately.

Tighten the critically damped window/layout spring to mass 1, stiffness 1600,
damping 80, with roughly 97ms to 90% and 166ms to 99% of a step response.
Window entry scales only 2%, exit only 1%, workspace travel drops to 4%, and
layer/exit fades take 80ms. Focus and entry opacity retain 120ms, DPMS 400ms.
These are configured timings and analytical spring values, not measured frame
pacing. Terminal latency settings, opaque surfaces and disabled blur/shadow/
glow are retained. No scrolling marquee or perpetual decorative animation.

## 5 — Daily use

Reimagine the final rice around the states encountered in normal use: paused
music, no messages, a dim terminal colour, an inactive Qt window, keyboard
focus, a disconnected Pi and a retired launcher. Bring meaningful secondary
text up to the existing mid-grey instead of introducing a new colour. Keep
kitty and Neovim's embedded terminal palette synchronized. Apply the user's
explicit identity exception: red `pi`, green `:`, neutral `up`, red `down`.

Complete the integration review: the eight headless helper tests pass,
including safe removal of the retired Calendar symlink while keeping an
unrelated dangling user link. ShellCheck passes for the helpers and installers;
36 shell files and 11 Lua files parse; JSON/JSONC, TOML, YAML and SVG checks
pass. GTK 3 and GTK 4 parse their relevant styles and all notification imports.
The updated tmux config loads. Normal text on panel, selected text, and the
corrected amber/red states exceed a 4.5:1 contrast ratio (5.37:1 to 11.46:1 for
the measured pairs). The Pi outputs are checked in both mocked network states.

Refresh the README instead of advertising historical screenshots as the new
rice. Supply an exact capture list for the desktop, terminal, notifications,
session console and apps, plus motion/player recordings. Actual application
rendering, multi-monitor behaviour, authentication and compositor frame pacing
still need those desktop captures. Existing wallpaper/login/lock design and
production Pi services are preserved; Proton Calendar's installed browser PWA
must be removed through PWAsForFirefox if it is still present locally.
