pragma Singleton
// The Diag palette and type, the same values as rice.lua, kitty and the CSS.
import QtQuick
import Quickshell

Singleton {
	readonly property color bg: "#000000"
	readonly property color panel: "#0d1014"
	readonly property color row: "#161a1f"
	readonly property color rule: "#3f4650"
	readonly property color mid: "#8a929c"
	readonly property color fg: "#c4c9ce"
	readonly property color ink: "#e6e8ea"
	readonly property color arch: "#1793d1"
	readonly property color warn: "#ffb000"
	readonly property color error: "#e5484d"

	readonly property string font: "Terminess Nerd Font"
	readonly property int size: 18
	readonly property int height: 32
	// Colour changes take the same 200 ms ease-out as Hyprland and the CSS.
	readonly property int ease: 200

	property bool barShown: true

	// The bar scripts print Waybar's Pango markup; Qt's StyledText wants <font>.
	function markup(s) {
		return (s || "").replace(/<span color=['"]([^'"]+)['"]>/g, "<font color='$1'>").replace(/<\/span>/g, "</font>");
	}
	function esc(s) {
		return (s || "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
	}
}
