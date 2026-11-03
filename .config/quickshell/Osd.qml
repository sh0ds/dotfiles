// The volume popup, replacing swayosd: a framed meter near the bottom of the
// focused screen, shown for 1.5 s whenever the output volume or mute changes
// (keys, scroll on the bar, pavucontrol). Clicks go through it.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire

PanelWindow {
	id: osd
	readonly property PwNode sink: Pipewire.defaultAudioSink
	readonly property bool muted: sink?.audio?.muted ?? false
	readonly property int percent: Math.round((sink?.audio?.volume ?? 0) * 100)
	property bool shown: false
	property bool ready: false

	screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
	anchors.bottom: true
	margins.bottom: 120
	exclusiveZone: 0
	implicitWidth: 420
	implicitHeight: 44
	color: "transparent"
	visible: shown
	mask: Region {}
	WlrLayershell.namespace: "diag-osd"
	WlrLayershell.layer: WlrLayer.Overlay

	PwObjectTracker { objects: osd.sink ? [osd.sink] : [] }
	// Pipewire reports the starting volume once; that isn't a change.
	Timer { interval: 2000; running: true; onTriggered: osd.ready = true }
	Timer { id: hide; interval: 1500; onTriggered: osd.shown = false }
	function poke() { if (ready) { shown = true; hide.restart(); } }
	Connections {
		target: osd.sink?.audio ?? null
		function onVolumesChanged() { osd.poke(); }
		function onMutedChanged() { osd.poke(); }
	}

	Rectangle {
		anchors.fill: parent
		color: Theme.bg
		border.color: Theme.rule
		border.width: 1
		Rectangle {
			anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
			width: 2
			color: Theme.arch
		}
		Text {
			id: label
			anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
			text: "vol"
			color: Theme.mid
			font.family: Theme.font
			font.pixelSize: Theme.size
			font.hintingPreference: Font.PreferFullHinting
		}
		Rectangle {
			id: trough
			anchors { left: label.right; leftMargin: 12; right: value.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
			height: 14
			color: "transparent"
			border.color: Theme.mid
			border.width: 2
			Row {
				anchors { fill: parent; margins: 4 }
				spacing: 2
				Repeater {
					model: 20
					Rectangle {
						required property int index
						width: (parent.width - 19 * 2) / 20
						height: parent.height
						color: !osd.muted && index < Math.round(osd.percent / 5) ? Theme.arch : "transparent"
					}
				}
			}
		}
		Text {
			id: value
			anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
			text: osd.muted ? "mute" : String(osd.percent).padStart(3, " ") + "%"
			color: osd.muted ? Theme.mid : Theme.ink
			font.family: Theme.font
			font.pixelSize: Theme.size
			font.hintingPreference: Font.PreferFullHinting
		}
	}
}
