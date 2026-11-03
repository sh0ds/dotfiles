// The bar on one screen, laid out like the old Waybar rail:
// workspaces, LIVE/REC, media · clock · sys, pi, volume, msg, tray, [exit].
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
	id: bar
	required property ShellScreen modelData
	screen: modelData
	anchors { top: true; left: true; right: true }
	implicitHeight: Theme.height
	color: Theme.bg
	visible: Theme.barShown
	WlrLayershell.namespace: "diag-bar"
	WlrLayershell.layer: WlrLayer.Top

	Rectangle {
		anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
		height: 1
		color: Theme.rule
	}

	Row {
		anchors { left: parent.left; top: parent.top }
		Workspaces { screen: bar.modelData }
		Badge {
			text: Status.live.cls.includes("live") ? Status.live.text : ""
			fill: Theme.arch
		}
		Badge {
			text: Status.rec.cls.includes("rec") ? Status.rec.text : ""
			fill: Theme.warn
			onClicked: Quickshell.execDetached(["rec-toggle"])
		}
		Media {}
	}

	Clock { anchors { horizontalCenter: parent.horizontalCenter; top: parent.top } }

	Row {
		anchors { right: parent.right; top: parent.top }
		Cell {
			readonly property bool hot: Status.stats.cls.includes("hot")
			text: Theme.markup(Status.stats.text)
			tip: Status.stats.tooltip
			rule: false
			textColor: hot ? Theme.warn : Theme.fg
			restColor: Status.stats.cls.includes("open") ? Theme.panel : "transparent"
			underline: hot ? Theme.warn : "transparent"
			onClicked: b => b === Qt.RightButton ? Quickshell.execDetached(["sysmon"]) : Status.toggleStats()
		}
		Cell {
			text: Theme.markup(Status.pi.text)
			tip: Status.pi.tooltip
			onClicked: Quickshell.execDetached(["kitty", "-e", "ssh", "pi"])
		}
		Volume {}
		Cell {
			readonly property string alt: Status.notes.alt
			text: `<font color='${alt.endsWith("none") ? Theme.mid : Theme.arch}'>${alt.includes("dnd") ? "dnd" : "msg"}</font> ${Theme.esc(Status.notes.text)}`
			tip: Status.notes.tooltip
			onClicked: b => Quickshell.execDetached(b === Qt.RightButton
				? ["swaync-client", "-d", "-sw"] : ["swaync-client", "-t", "-sw"])
		}
		Tray { bar: bar }
		Cell {
			text: "[exit]"
			pad: 12
			textColor: Theme.arch
			hoverColor: Theme.arch
			hoverText: "#000000"
			onClicked: Quickshell.execDetached(["power-menu"])
		}
	}
}
