// The volume popup, replacing swayosd: a glass pill near the bottom of the
// focused screen with a smooth blue meter, shown for 1.5 s whenever the
// output volume or mute changes (keys, scroll on the bar, pavucontrol).
// Clicks go through it.
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
	implicitWidth: 380
	implicitHeight: 48
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

	Glass {
		anchors.fill: parent
		radius: height / 2
		Text {
			id: label
			anchors { left: parent.left; leftMargin: 20; verticalCenter: parent.verticalCenter }
			text: osd.muted ? "mute" : "vol"
			color: Theme.mid
			font.family: Theme.font
			font.pixelSize: Theme.size
			font.hintingPreference: Font.PreferFullHinting
		}
		Rectangle {
			id: trough
			anchors { left: parent.left; leftMargin: 76; right: value.left; rightMargin: 14; verticalCenter: parent.verticalCenter }
			height: 8
			radius: 4
			color: "#1affffff"
			Rectangle {
				anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
				width: osd.muted ? 0 : trough.width * Math.min(osd.percent, 100) / 100
				radius: 4
				gradient: Gradient {
					orientation: Gradient.Horizontal
					GradientStop { position: 0; color: Theme.arch }
					GradientStop { position: 1; color: Theme.sky }
				}
				Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
			}
		}
		Text {
			id: value
			anchors { right: parent.right; rightMargin: 20; verticalCenter: parent.verticalCenter }
			width: 44
			horizontalAlignment: Text.AlignRight
			text: osd.muted ? "" : osd.percent + "%"
			color: Theme.ink
			font.family: Theme.font
			font.pixelSize: Theme.size
			font.hintingPreference: Font.PreferFullHinting
		}
	}
}
