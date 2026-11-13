# From power-on to the desktop

One picture carries the whole start: the Afterhours mark over charcoal, on the same pixels in every stage (its bottom edge 24 px above the middle of the screen). `bash system/install-system.sh` sets up everything here; the session part comes with `install-dotfiles.sh`. `bash check-desktop.sh` has a Boot section that says whether it's all in place.

## The chain

1. **Firmware.** Nothing of ours. The PC's own logo, if the BIOS shows one (turn off "Full screen logo" there).
2. **Boot menu, hidden.** systemd-boot with `timeout 0`, also in the firmware's stored timeout, which wins over `loader.conf`. To get the menu (for the LTS kernel): hold Space while the PC starts, or `systemctl reboot --boot-loader-menu=10`.
3. **The kernel image's picture.** `system/boot/splash-afterhours.bmp`, built into both kernel images through `--splash` in `/etc/mkinitcpio.d/*.preset`. It is the mark, still. The firmware starts the screen at 1024x768 here, so it looks soft; that part can't be changed from Linux.
4. **Early boot.** `/etc/mkinitcpio.conf.d/afterhours.conf`: systemd hooks, so nothing waits for USB devices, and the NVIDIA modules inside the image, so the splash has a real screen about a second in. `/etc/mkinitcpio.conf` itself stays as it was.
5. **Splash.** Plymouth theme `system/plymouth/afterhours`: the mark breathes, a notched meter with a counter slides in under it. Shutting down and restarting show the same with the meter draining. It ends on the mark alone, and that last frame stays on screen when Plymouth quits (`plymouth quit --retain-splash`, a drop-in for `plymouth-quit.service`) until Hyprland draws over it.
6. **Session.** SDDM logs you in by itself (`/etc/sddm.conf.d/20-afterhours-autologin.conf`) and starts Hyprland straight away, so there's no second compositor and no handover between them. Hyprland's background is the same charcoal. `afterhours start --arrive` puts the mark up with swaybg (`afterhours-arrive.png`, same pixels) while the shell loads.
7. **Login.** The shell's lock screen is the login. For a session SDDM started by itself (logind says `sddm-autologin`), the shell locks the moment it starts, and the lock opens from the mark: the haze comes up, the mark lets go, the clock and the password field rise. The right password unlocks the keyring too (`pam/password.conf`) and the lock fades to the finished desktop.

One compositor runs from the splash to the desktop. The only thing left is Hyprland's first mode set on the graphics card, which may blank the screen for a blink right after the splash.

Safety: until the lock holds (about a second after Hyprland starts) the session is open, though nothing but the mark is on screen. If the shell hasn't locked 6 s in, `afterhours start` runs hyprlock instead. A session you start from the login screen yourself (after logging out) is not locked again.

If Hyprland ever fails to start, the retained splash stays up and the PC looks stuck on the mark. `Ctrl + Alt + F3` gives a text login.

The themed SDDM login (`system/sddm/afterhours`, on weston, main screen only) still shows after you log out.

## Screens

`hyprland.lua` names the screens `main` and `side` by make, model and serial. Plug names like `DP-4` are not used anywhere: the kernel numbers plugs in the order the graphics drivers load, and step 4 changed that order. The rail and the overview treat the screen at 0x0 as main; `install-system.sh` reads the `main` line and finds its plug for the login screen. After swapping or adding a screen, edit that table and run `install-system.sh` again.

## Undo

Every system file the script changes is kept next to it as `*.before-afterhours` (the presets, `loader.conf`).

Early boot only:

```bash
sudo rm /etc/mkinitcpio.conf.d/afterhours.conf && sudo mkinitcpio -P
```

The first time the script sets up the early boot it keeps the kernel image you booted with as a second menu entry ending in `before-afterhours`. If the new one doesn't come up, hold Space at power-on and pick that. The next run of the script after a good boot removes it.
