# DJ VM setup (Windows)

Lexicon, rekordbox and Traktor don't run on Linux, so everything DJ lives in a Windows 11 VM, Audacity included. Songs stay on the Arch side in `~/Music/DJ`, which Windows sees as drive `Z:`. Browse for songs in yazi, drop them in there, and they're in Windows straight away. Takes about an hour, once, mostly Windows installing itself.

## 1. Install

The packages are in the README's list. On top of that:

```
mkdir -p ~/Music/DJ
grep -q "^$USER:" /etc/subuid || sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 $USER
```

The second line is for the shared folder: it lets the VM run as you instead of root, so files Windows writes into `~/Music/DJ` belong to you.

## 2. Download

- Windows 11 from [microsoft.com](https://www.microsoft.com/en-us/software-download/windows11) ("Download Windows 11 Disk Image (ISO) for x64 devices"). Keep the name it comes with (`Win11_...iso`). If the site refuses (it does that behind a VPN), `yay -S quickemu`, then `quickget --download windows 11` fetches the same ISO straight from Microsoft. Move it to `~/Downloads/Win11.iso`.
- The drivers for the VM: [virtio-win.iso](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso).

Both go in `~/Downloads`. The virtio-win server is slow, so copy that link and run `dl` instead of downloading it in Firefox.

## 3. Make the VM

```
djvm create
```

That makes a VM called `dj` (8 GB RAM, 4 cores, a 120 GB disk that only takes up what Windows uses) and opens its window on workspace 7. Press a key when it says "Press any key to boot from CD".

In the Windows installer:

1. "I don't have a product key" and pick Home or Pro. It runs fine without activating, it just shows a watermark until you enter a key.
2. When it can't find a disk: Load driver, Browse, the virtio-win CD, `viostor\w11\amd64`. The disk shows up, install on it.
3. When it wants internet during setup, click "Install driver" and point it at `NetKVM\w11\amd64` on the virtio-win CD. Then log in with a Microsoft account, or make a local one if it offers you that.

## 4. Drivers and the shared folder

In Windows, open the virtio-win CD in Explorer and run `virtio-win-guest-tools.exe`. That brings the rest of the drivers, the window resizing with the viewer, a shared clipboard and the driver for the shared folder.

Then install [WinFsp](https://winfsp.dev/rel/) and run this in PowerShell as admin:

```
sc.exe config VirtioFsSvc start=auto
sc.exe start VirtioFsSvc
```

`~/Music/DJ` is now `Z:` in Explorer, and it comes back on its own every time Windows starts.

## 5. Declutter

Windows comes with a lot nobody asked for. [Win11Debloat](https://github.com/Raphire/Win11Debloat) clears most of it out and makes a restore point first. Paste this into PowerShell as admin (the clipboard is shared with Arch by now, so copy it from here):

```
& ([scriptblock]::Create((irm "https://debloat.raphi.re/"))) -Silent -CreateRestorePoint `
  -RemoveApps -RemoveGamingApps -DisableDVR -DisableGameBarIntegration `
  -DisableTelemetry -DisableSuggestions -DisableEdgeAds -DisableLockscreenTips -DisableBing `
  -DisableStoreSearchSuggestions -DisableCopilot -DisableRecall -DisableClickToDo -DisableAISvcAutoStart `
  -DisableWidgets -HideChat -ShowKnownFileExt -DisableDragTray -DisableModernStandbyNetworking `
  -DisableFastStartup -PreventUpdateAutoReboot -DisableDeliveryOptimization -DisableLocationServices -DisableFindMyDevice `
  -EnableDarkMode -DisableTransparency -DisableAnimations `
  -HideSearchTb -HideTaskview -DisableStartRecommended -DisableStartPhoneLink -ClearStart `
  -DisableSettingsHome -HideHome -HideGallery -ExplorerToThisPC
```

That takes out the preinstalled junk (Xbox, Clipchamp, Teams, Solitaire and so on), Copilot, Recall, the widgets, ads and tips everywhere, Bing in the Start menu and most of the telemetry. It also turns on dark mode and turns off transparency and animations, which matters here since the CPU draws everything. The taskbar ends up with just the Start button and your pinned apps, and Windows no longer restarts by itself for updates halfway through an export.

Then a few things that only matter in a VM, same PowerShell:

```
Add-MpPreference -ExclusionPath 'Z:\'
Set-Service WSearch -StartupType Disabled; Stop-Service WSearch
powercfg /hibernate off
powercfg /change standby-timeout-ac 0
powercfg /change monitor-timeout-ac 0
```

Defender stops scanning every song in the shared folder. No search indexing eating the CPU in the background. No hibernation file, and Windows never goes to sleep on its own, since Arch decides when the VM is on. Then OneDrive, in a normal PowerShell (not admin, since it's installed for your user only):

```
taskkill /f /im OneDrive.exe; winget uninstall --id Microsoft.OneDrive -e
```

Restart Windows once afterwards.

Edge stays: Windows and some installers need it under the hood. If something you miss is gone, type "restore point" in Start, then System Restore takes you back to before Win11Debloat ran.

## 6. More privacy, and Edge

Two scripts from this repo do the rest. Copy them into the shared folder on the Arch side:

```
cp ~/code/dotfiles/docs/windows/*.ps1 ~/Music/DJ/
```

Then in Windows, in PowerShell as admin:

```
powershell -ExecutionPolicy Bypass -File Z:\private.ps1
powershell -ExecutionPolicy Bypass -File Z:\edge.ps1
```

[`private.ps1`](windows/private.ps1) turns diagnostic data down as far as the edition allows and switches off the services and scheduled tasks that send it. It also turns off error reports, the advertising ID, activity history and the clipboard sync to other devices. Typing, inking and speech stay on the machine, and apps lose access to the webcam, contacts, calendar, mail and the other things a DJ VM never needs. The microphone stays on for Audacity.

[`edge.ps1`](windows/edge.ps1) sets Edge up through policies. That means no welcome tour, no Microsoft account or sync, strict tracking prevention and no third-party cookies. The new tab page is empty, and there's no Copilot, sidebar, shopping, rewards or promotions. Saving passwords is off (that's Proton Pass's job), and nothing keeps running after you close it. Edge shows "managed by your organization" afterwards, which is just these policies. `edge://policy` lists them.

Two things the policies can't do on a home PC, so do them by hand in Edge:

- Settings > Privacy, search and services > Address bar and search: pick DuckDuckGo.
- Get uBlock Origin Lite from Edge's add-on store.

Restart Windows, then delete the two scripts from `~/Music/DJ`.

## 7. The apps

- [Lexicon](https://www.lexicondj.com) for the library itself: tags, playlists, cleaning up, and syncing to the others.
- [rekordbox](https://rekordbox.com) for exporting to USB for Pioneer gear.
- Traktor Pro 4 through [Native Access](https://www.native-instruments.com/en/specials/native-access/).
- Audacity: `winget install Audacity.Audacity` in a terminal.

Point all of them at `Z:\` for music. To bring over older tracks, move them into `~/Music/DJ` on the Arch side first, then import them in Lexicon.

## Using it

- `SUPER+SHIFT+M` starts the VM and shows it, or jumps to it if it's already open. `djvm off` shuts Windows down. Log out, reboot and shut down in the power menu do that first and wait for it, so Windows never gets switched off like a power cut.
- Click into the window and it has your mouse and keyboard, `Ctrl+Alt` gets them back. The `SUPER` keys always stay with Hyprland, so open the Start menu with a click.
- USB sticks for exporting: plug it in, `SUPER+SHIFT+U` so Arch lets go of it, then in the viewer's menu File > USB device selection and tick it. Untick it when Windows is done and it comes back to Arch.
- Sound goes through the viewer, so previewing and recording work. There are no 3D graphics in the VM, so waveforms are drawn by the CPU. Fine for library work, not for mixing live.

## Starting over

```
virsh -c qemu:///session destroy dj
virsh -c qemu:///session undefine dj --nvram --tpm --remove-all-storage
```

That deletes Windows and everything installed in it. `~/Music/DJ` stays.
