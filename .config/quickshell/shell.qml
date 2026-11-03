//@ pragma UseQApplication
//@ pragma NativeTextRendering
// ~/.config/quickshell: the Diag shell. One bar per screen (Bar.qml), the
// volume popup (Osd.qml), notifications (Notes, Popups, Center), replacing
// Waybar, swayosd and swaync. Native text
// rendering with full hinting keeps Terminess pixel-sharp: Qt's default
// distance-field text smears it. Started by Hyprland
// as `qs`; `qs ipc call bar toggle` hides and shows the bars (SUPER+SHIFT+B).
import Quickshell
import Quickshell.Io

ShellRoot {
	Variants {
		model: Quickshell.screens
		Bar {}
	}

	Osd {}
	Popups {}
	Center {}

	IpcHandler {
		target: "bar"
		function toggle(): void { Theme.barShown = !Theme.barShown }
	}
}
