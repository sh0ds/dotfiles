# From power-on to the desktop

One picture carries the whole start: the Afterhours mark over charcoal, on the same pixels in every stage (its bottom edge 24 px above the middle of the screen). `bash system/install-system.sh` sets up everything here; the session part comes with `install-dotfiles.sh`. `bash check-desktop.sh` has a Boot section that says whether it's all in place.

## The chain

1. **Firmware.** Nothing of ours. The PC's own logo, if the BIOS shows one (turn off "Full screen logo" there).
2. **Boot menu, hidden.** systemd-boot with `timeout 0`, also in the firmware's stored timeout, which wins over `loader.conf`. To get the menu (for the LTS kernel): hold Space while the PC starts, or `systemctl reboot --boot-loader-menu=10`.
3. **The kernel image's picture.** `system/boot/splash-afterhours.bmp`, built into both kernel images through `--splash` in `/etc/mkinitcpio.d/*.preset`. It is the mark, still. The firmware starts the screen at 1024x768 here, so it looks soft; that part can't be changed from Linux.
4. **Early boot.** `/etc/mkinitcpio.conf.d/afterhours.conf`: systemd hooks, so nothing waits for USB devices, and the NVIDIA modules inside the image, so the splash has a real screen about a second in. `/etc/mkinitcpio.conf` itself stays as it was.
5. **Splash.** Plymouth theme `system/plymouth/afterhours`: the mark breathes, a notched meter with a counter slides in under it. Shutting down and restarting show the same with the meter draining. It ends on the mark alone.
6. **Login.** SDDM theme `system/sddm/afterhours` on weston, on the main screen only. It opens from the mark (wallpaper fades in, clock and password field rise) and after a correct password fades back to it.
7. **Session.** Hyprland's background is the same charcoal. The shell starts with `afterhours start --arrive`, which puts the mark over everything for half a second (`Arrive.qml`) and then lets go of the finished desktop. A shell restart never shows it.

Between 6 and 7 the screen is dark for a moment: the login's compositor has stopped and Hyprland is taking the graphics card. Nothing can draw then.

## Screens

`hyprland.lua` names the screens `main` and `side` by make, model and serial. Plug names like `DP-4` are not used anywhere: the kernel numbers plugs in the order the graphics drivers load, and step 4 changed that order. The rail and the overview treat the screen at 0x0 as main; `install-system.sh` reads the `main` line and finds its plug for the login screen. After swapping or adding a screen, edit that table and run `install-system.sh` again.

## Undo

Every system file the script changes is kept next to it as `*.before-afterhours` (the presets, `loader.conf`).

Early boot only:

```bash
sudo rm /etc/mkinitcpio.conf.d/afterhours.conf && sudo mkinitcpio -P
```

The first time the script sets up the early boot it keeps the kernel image you booted with as a second menu entry ending in `before-afterhours`. If the new one doesn't come up, hold Space at power-on and pick that. The next run of the script after a good boot removes it.
