# DJ VM setup (Windows)

Lexicon, rekordbox and Traktor don't run on Linux, so everything DJ lives in a Windows 11 VM, Audacity included. Songs stay on the Arch side in `~/Music/DJ`, which Windows sees as drive `Z:`. Browse for songs in Thunar, drop them in there, and they're in Windows straight away. Takes about an hour, once, mostly Windows installing itself.

## 1. Install the helper and dependencies

Install the VM packages on Arch:

```sh
sudo pacman -S --needed python qemu-desktop libvirt virt-install virt-viewer edk2-ovmf swtpm virtiofsd passt
```

Update and install the helper from your existing dotfiles checkout:

```sh
git -C "$HOME/code/dotfiles" pull --ff-only origin main &&
bash "$HOME/code/dotfiles/install-dotfiles.sh"
mkdir -p "$HOME/Music/DJ"
djvm --help
```

Clone the repository first as described in the README if needed. Use your actual
checkout path if it is elsewhere. The helper uses
`qemu:///session`: run `djvm` and `virsh` as your normal user, without sudo.
This is separate from the system connection shown by `sudo virsh`.

For virtiofs, check that your user has subordinate UID **and** GID allocations:

```sh
grep "^${USER}:" /etc/subuid /etc/subgid
```

If either is missing, allocate unused ranges as described in the
[Arch libvirt guide](https://wiki.archlinux.org/title/Libvirt#Sharing_data_between_host_and_guest).
Do not reuse a hard-coded range that may belong to another user. Session QEMU
already runs as you; these allocations support the virtiofs user namespace.

## 2. Put the ISOs in their permanent directory

Use the same directory calculation as `djvm`:

```sh
iso_dir="${XDG_DATA_HOME:-$HOME/.local/share}/djvm/isos"
mkdir -p "$iso_dir"
printf 'Windows ISO: %s/windows11.iso\nVirtIO ISO:  %s/virtio-win.iso\n' "$iso_dir" "$iso_dir"
```

With the default configuration, the files are:

| File | Permanent path |
| --- | --- |
| Windows 11 installer | `~/.local/share/djvm/isos/windows11.iso` |
| VirtIO drivers | `~/.local/share/djvm/isos/virtio-win.iso` |
| VM definition backups | `~/.local/share/djvm/backups/dj-*.xml` |

If `XDG_DATA_HOME` is set, replace `~/.local/share` in that table with its value.
Keep that setting consistent when running the helper. These are ISO and backup
paths, not the Windows virtual disk location. Music stays in `~/Music/DJ`.

Download Windows 11 from [Microsoft](https://www.microsoft.com/en-us/software-download/windows11)
("Download Windows 11 Disk Image (ISO) for x64 devices"). In the browser's Save As
dialog, use the **absolute Windows ISO path printed above**, including the name
`windows11.iso`. If the browser already downloaded it elsewhere, use the import
option below instead of downloading it again.

Once `windows11.iso` is in that directory, run:

```sh
djvm setup
```

Setup uses that Windows ISO and downloads the stable VirtIO ISO directly from
[Fedora](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso)
into the same directory as `virtio-win.iso`. No manual VirtIO download is needed.
It checks ISO/UDF headers, rejects incomplete downloads when a content length is
provided, and stages downloads in `.part` files before installing them. These
checks do not replace verifying Microsoft's published Windows ISO SHA-256.

To check the resulting files in a new terminal, calculate the directory again:

```sh
iso_dir="${XDG_DATA_HOME:-$HOME/.local/share}/djvm/isos"
ls -lh -- "$iso_dir/windows11.iso" "$iso_dir/virtio-win.iso"
```

### Import ISOs you already have

`--windows` and `--virtio` are **source file paths**, not destination directories.
You can select an ISO from any folder. For example, if the files are already in
the permanent directory with their original names, list them first:

```sh
iso_dir="${XDG_DATA_HOME:-$HOME/.local/share}/djvm/isos"
find "$iso_dir" -maxdepth 1 -type f -iname '*.iso' -print
```

Use the actual filenames from that output with
`djvm setup --windows /absolute/path/to/windows-image.iso` and, if needed,
`--virtio /absolute/path/to/driver-image.iso`. Replace those example source paths;
they are not files created by the helper. Setup copies them to the canonical
names `windows11.iso` and `virtio-win.iso` under `iso_dir`.

It also discovers a single `Win11*.iso` / `windows11*.iso` and a VirtIO ISO whose
name contains `virtio-win` in Downloads or the existing VM's CD-ROM paths. It
**does not scan other filenames inside the permanent directory**: import those
explicitly or save them under the canonical names above. Multiple discovered
candidates require an explicit source path.

Original files are kept. Once setup succeeds, temporary copies in Downloads
are no longer needed. A different ISO cannot silently overwrite a permanent
copy. With the VM shut off, move that permanent copy aside first if you intend
to replace it.

### Repair an existing VM with a missing ISO

For `Cannot access storage file .../Downloads/virtio-win.iso`, update/install the
helper from your current checkout, then run:

```sh
djvm off && djvm setup && djvm
```

Setup must run while the VM is shut off, not suspended or paused. It reuses
permanent media, imports available old CD-ROM images, downloads missing VirtIO
media, and changes the persistent CD-ROM paths. Before attachment changes it
saves the original definition in the backup directory shown above. It does not
recreate the VM or modify the Windows disk or shared music.

If the Windows installer is also missing, provide it with `--windows`.
If Windows and its drivers are already installed and neither installer CD is
needed, you can instead use:

```sh
djvm off && djvm eject && djvm
```

`eject` removes only CD-ROM media attachments while the VM is off. It keeps the
optical drives, ISO files, Windows disk and shared music. `setup` repairs existing
attachments; it does not reinsert CDs into drives emptied by `eject`.

To inspect the current storage paths:

```sh
virsh -c qemu:///session domblklist dj --inactive --details
```

After setup, populated CD-ROM entries should point into the permanent ISO
directory. The Windows disk entry is separate and should retain its original
path. Backups can be inspected as XML and restored, while the VM is off, with
`virsh -c qemu:///session define /absolute/path/to/dj-backup.xml`.

## 3. Make a new VM

After staging the ISOs with setup:

```sh
djvm create
```

Or do both steps with `djvm create --windows /path/to/Win11.iso`. This refuses to
replace an existing `dj` VM; use `djvm setup` to repair one instead.

That makes a VM called `dj` (8 GB RAM, 4 cores, a 120 GB disk that only takes up what Windows uses) and opens its window on workspace 7. Press a key when it says "Press any key to boot from CD".

In the Windows installer:

1. "I don't have a product key" and pick Home or Pro. It runs fine without activating, it just shows a watermark until you enter a key.
2. When it can't find a disk: Load driver, Browse, the virtio-win CD, `viostor\w11\amd64`. The disk shows up, install on it.
3. When it wants internet during setup, click "Install driver" and point it at `NetKVM\w11\amd64` on the virtio-win CD. Then log in with a Microsoft account, or make a local one if it offers you that.

## 4. Drivers and the shared folder

In Windows, open the virtio-win CD in Explorer and run `virtio-win-guest-tools.exe`. That brings the rest of the drivers, the window resizing with the viewer, a shared clipboard and the driver for the shared folder.

Then install [WinFsp](https://winfsp.dev/rel/). Check that the VirtIO guest tools
installed the VirtioFsSvc service, then run this in PowerShell as admin:

```
Get-Service VirtioFsSvc
sc.exe config VirtioFsSvc start=auto
sc.exe start VirtioFsSvc
```

If the service is missing, install the VirtIO-FS component from the VirtIO driver
media before continuing. Check Explorer for the share tagged `dj`. It normally
uses `Z:` when that letter is available; verify the actual letter before pointing
apps at it. Substitute that letter for `Z:` in the commands below. Starting the
service automatically makes the share available after Windows boots.

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

- `SUPER+SHIFT+M` starts the VM and shows it, or jumps to it if it's already open. `djvm off` requests a clean Windows shutdown and waits up to 90 seconds. If Windows hangs, it reports an error and leaves the VM running. The power menu stops on that error so you can finish shutting Windows down yourself; it never forces power off.
- Click into the window and it has your mouse and keyboard, `Ctrl+Alt` gets them back. The `SUPER` keys always stay with Hyprland, so open the Start menu with a click.
- USB sticks for exporting: plug it in, `SUPER+SHIFT+U` so Arch lets go of it, then in the viewer's menu File > USB device selection and tick it. Untick it when Windows is done and it comes back to Arch.
- Sound goes through the viewer, so previewing and recording work. There are no 3D graphics in the VM, so waveforms are drawn by the CPU. Fine for library work, not for mixing live.

## Starting over

```
djvm off &&
djvm eject &&
virsh -c qemu:///session undefine dj --nvram --tpm --remove-all-storage
```

This permanently deletes the Windows VM and its virtual disk. Ejecting the CDs
first keeps installer ISOs out of storage removal. `~/Music/DJ` and the permanent
ISOs stay. The chain stops if Windows fails to shut down; do not force it off to
fix a missing-ISO error.
