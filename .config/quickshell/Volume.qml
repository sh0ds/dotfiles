// Default output: "vol  42%" or "vol mute" in grey. Click: pavucontrol,
// right-click: mute, scroll: 5 % steps.
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Cell {
	id: vol
	readonly property PwNode sink: Pipewire.defaultAudioSink
	readonly property bool muted: sink?.audio?.muted ?? false
	readonly property int percent: Math.round((sink?.audio?.volume ?? 0) * 100)

	PwObjectTracker { objects: vol.sink ? [vol.sink] : [] }

	visible: sink !== null
	text: muted ? "vol mute" : "vol " + String(percent).padStart(3) + "%"
	textColor: muted ? Theme.mid : Theme.fg
	onClicked: b => {
		if (b === Qt.RightButton) sink.audio.muted = !sink.audio.muted;
		else Quickshell.execDetached(["pavucontrol"]);
	}
	onScrolled: d => sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + (d > 0 ? 0.05 : -0.05)))
}
