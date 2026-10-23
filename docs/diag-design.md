# Diag desktop review

This pass keeps the desktop black, square, and deliberately technical. Colour
marks focus, selection, and status; it does not decorate entire panels.

| Role | Colour | Use |
| --- | --- | --- |
| Background | `#000000` | desktop, terminal, main app surfaces |
| Panel | `#0d1014` | input fields, menus, status lines |
| Row | `#161a1f` | hover and raised controls |
| Rule | `#3f4650` | separators and inactive frames |
| Secondary text | `#8a929c` | metadata and inactive labels |
| Text / emphasis | `#c4c9ce` / `#e6e8ea` | body text / active content |
| Focus | `#1793d1` | active border, key labels, selected tabs |
| Selection | `#0e3d5c` | selected text and lists with light foreground |
| Warning / error / success | `#ffb000` / `#e5484d` / `#75c94d` | semantic status |

Terminess remains the interface font. App content keeps its own typography:
websites, book pages, documents, photos, and video should remain readable.

## What changed

- Firefox: removed conflicting tab overrides and clipped backgrounds. Selected,
  multiselected, horizontal and vertical tabs retain their full surface; vertical
  tabs get a leading blue rule. The obsolete root pseudo-class was removed.
- Obsidian: one set of variables covers inputs, selection, links, code, menus,
  tabs, and focus. Document fonts are preserved; links have an underline.
- GTK 3/4: removed the blanket foreground override on labels/buttons that could
  mask selected and destructive states. Controls use square geometry, visible
  focus, consistent input surfaces, and readable text selection.
- Qt 6: the installer renders the absolute palette path for the target user,
  replacing the hardcoded `/home/sh0ds` path. Theme assets remain linked.
- SwayNC: removed repeated overrides, enlarged unreadably small action text,
  made the slider thumb less oversized, and replaced ambiguous quick-setting
  glyphs with compact labels. `wifi` opens the network picker; `night` remains
  a toggle. The panel still uses `fit-to-screen`.
- Waybar: media is bounded to 32 characters; the bar uses 18px text and tighter
  spacing. Expanded stats keep CPU/memory/temperature on the bar and put GPU
  and network detail in the tooltip. Sampling is serialized across monitors,
  GPU queries have a timeout, and network interface/counter resets cannot
  produce negative transfer rates. Rates use monotonic uptime.
- Power menu: every entry point uses `power-menu`, with logical-pixel sizing
  for HiDPI, portrait, and mixed monitors. Keys are visible; destructive actions
  receive an amber focus frame. The menu has an opaque background.
- Neovim: explicit lualine/bufferline styles prevent default colour fallbacks;
  comments are brighter and upright for the pixel font. Mode names remain
  visible even though all mode blocks share the same blue.
- btop, rmpc, Yazi, lazygit and aerc: focus/selection is consistent with Diag;
  btop uses solid graphs and grey structural borders. btop gets a copied config
  because it writes that file on exit. Its existing `sysmon` launcher already
  selected Diag; the defaults also cover direct launches.
- nchat: added a colour-only theme, including its list, input, top/status bars
  and sender names. Authentication and notification settings are untouched.
- mpv: stats now use the correct blue/grey palette in mpv's BGR format.
- Vesktop: filled blue buttons specify dark text, mentions/status colours
  match the palette, keyboard focus stays visible, and the broad container
  geometry override was narrowed to avoid affecting avatars/video containers.
- Lock screen: now-playing metadata is bounded and properly escapes Pango
  markup, including Bash 5.2's replacement-ampersand behaviour.

Kitty, tmux, fuzzel, zathura, imv, the wallpaper, Hyprlock's main layout, SDDM,
and Plymouth already use the Diag palette. Their existing design is retained.

## Motion and responsiveness

Hyprland's critically damped spring remains unchanged: mass 1, stiffness 1225,
damping 70 (`2 * sqrt(1225)`). It has no overshoot. Window travel stays small
(97% entry scale and 8% workspace shift); exits and focus fades remain short.
No blur, glow, shadows, continuous border animation, or moving bar was added.
Web app tab transitions honour `prefers-reduced-motion`. GTK controls retain
toolkit behaviour; this theme does not disable application animations globally.

The bar and power grid have more room at smaller logical resolutions, but
their complete layout must still be checked on the real monitor setup. Very
narrow screens or an unusually large system tray can still crowd the bar.

## Validation and limits

In the cloud workspace:

- Seven headless regression tests pass: installer backup/idempotence and Qt
  rendering (including spaces and ampersands), literal/bounded lock metadata,
  stats toggle/reset, and power layout across desktop, HiDPI and portrait sizes.
- ShellCheck warning-level checks pass for all `.local/bin` scripts and the
  installer, desktop checker and system installer. Shell syntax and Lua parsing
  pass; all 51 Hyprland config assignments were checked against upstream 0.56.1
  option names. This does not validate event handlers or compositor execution.
- GTK 3 parses its override, Waybar, wlogout and SwayOSD CSS. GTK 4 parses its
  override, SwayNC (including imports) and SwayOSD CSS. No parsing errors.
- tmux loads its existing config successfully. JSON/JSONC, TOML, YAML and SVG
  files receive structural validation.

No actual Arch/Hyprland desktop, GPU timing, lock authentication, nchat login,
MPD session, Firefox profile, Electron app or Qt application was exercised.
Browser/app updates can change selectors. Steam, Proton PWAs and proprietary
apps control parts of their own UI; GTK/Qt colours do not override all web
content. The checked-in screenshots predate Diag and are historical, not proof
of this version's appearance.

## Apply on the desktop

Review the diff and include the new files when committing or applying the
change. The installer deliberately installs **Git-tracked files only**. Close
nchat and btop before installation, since applications can rewrite configs.
Run `bash install-dotfiles.sh` from this checkout. Existing configs are moved
to unique directories under `~/.dotfiles-backup/`; Qt's rendered config and
btop's and nchat's writable configs are copied, while theme assets and other configs link
to the checkout. To inspect an isolated installation first:

```sh
bash install-dotfiles.sh --target /tmp/diag-preview
python3 -m unittest discover -s tests -v
```

Restart the affected desktop apps when convenient. Firefox chrome changes
need a browser restart and `firefox-style` if the profile has not been linked.
Enable the Obsidian snippet and Vesktop theme in their Appearance settings.
Hyprland reloads the linked config when saved; inspect `hyprctl configerrors`.
Run `bash check-desktop.sh` on the actual desktop and check the power menu,
keyboard focus, selected rows, notifications, audio, media text and both monitors.
SDDM/Plymouth are unchanged and do not need reinstalling for this pass.

Rollback is file based: restore the reviewed prior checkout and any replaced
local configs from the installer backup, then restart only the affected apps.
No production Pi configuration, service, or website source changed here.
