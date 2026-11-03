//@ pragma UseQApplication
// ~/.config/quickshell: the Diag shell. One bar per screen (Bar.qml) and the
// volume popup (Osd.qml), replacing Waybar and swayosd. Started by Hyprland
// as `qs`; `qs ipc call bar toggle` hides and shows the bars (SUPER+SHIFT+B).
import Quickshell
import Quickshell.Io

ShellRoot {
	Variants {
		model: Quickshell.screens
		Bar {}
	}

	Osd {}

	IpcHandler {
		target: "bar"
		function toggle(): void { Theme.barShown = !Theme.barShown }
	}
}
