// The bar on one screen: a rounded glass strip floating 8 px under the top
// edge, lined up with the windows' outer gap. Workspaces, LIVE/REC and
// media on the left, the clock in the middle, sys, pi, volume, msg, tray
// and exit on the right.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
	id: bar
	required property ShellScreen modelData
	screen: modelData
	anchors { top: true; left: true; right: true }
	margins { top: 8; left: 14; right: 14 }
	implicitHeight: Theme.height + 2
	color: "transparent"
	visible: Theme.barShown
	WlrLayershell.namespace: "diag-bar"
	WlrLayershell.layer: WlrLayer.Top

	Glass { anchors.fill: parent }

	Row {
		anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
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

	Clock { anchors.centerIn: parent }

	Row {
		anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
		Cell {
			readonly property bool hot: Status.stats.cls.includes("hot")
			text: Theme.markup(Status.stats.text)
			tip: Status.stats.tooltip
			textColor: hot ? Theme.warn : Theme.fg
			restColor: Status.stats.cls.includes("open") ? Theme.hover : "transparent"
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
			text: "exit"
			pad: 12
			textColor: Theme.arch
			hoverColor: Theme.arch
			hoverText: "#000000"
			onClicked: Quickshell.execDetached(["power-menu"])
		}
	}
}
