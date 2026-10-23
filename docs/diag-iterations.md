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
