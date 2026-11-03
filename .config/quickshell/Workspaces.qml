// Numbered workspaces of one screen. 1-5 always show on DP-4, even empty.
// A blue pill slides to the active one; urgent ones turn amber. Scroll
// walks through the open ones.
import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
	id: ws
	required property ShellScreen screen
	readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
	readonly property int activeId: monitor?.activeWorkspace?.id ?? -1
	property real pillX: 0
	property real pillW: 0

	implicitWidth: row.implicitWidth
	implicitHeight: Theme.height

	function ids() {
		const name = monitor?.name ?? "";
		const set = new Set(name === "DP-4" ? [1, 2, 3, 4, 5] : []);
		for (const w of Hyprland.workspaces.values)
			if (w.id > 0 && w.monitor?.name === name) set.add(w.id);
		return [...set].sort((a, b) => a - b);
	}
	function urgent(id) {
		const w = Hyprland.workspaces.values.find(w => w.id === id);
		return w ? w.urgent : false;
	}
	function go(target) {
		Hyprland.dispatch(`hl.dsp.focus({ workspace = ${target} })`);
	}

	// The pill glides with the same feel as Hyprland's workspace spring.
	Rectangle {
		x: ws.pillX + 2
		width: Math.max(0, ws.pillW - 4)
		anchors { top: parent.top; bottom: parent.bottom; topMargin: 4; bottomMargin: 4 }
		radius: 7
		color: Theme.tint
		border.color: "#801793d1"
		border.width: 1
		visible: ws.pillW > 0
		Behavior on x { NumberAnimation { duration: Theme.glide; easing.type: Easing.OutCubic } }
		Behavior on width { NumberAnimation { duration: Theme.glide; easing.type: Easing.OutCubic } }
	}

	Row {
		id: row
		Repeater {
			model: ws.ids()
			Cell {
				id: num
				required property int modelData
				readonly property bool active: modelData === ws.activeId
				readonly property bool hot: ws.urgent(modelData)
				text: String(modelData)
				pad: 11
				textColor: hot ? Theme.warn : active ? Theme.ink : Theme.mid
				hoverColor: active ? "transparent" : Theme.hover
				underline: hot ? Theme.warn : "transparent"
				onClicked: ws.go(modelData)
				onScrolled: d => ws.go(d > 0 ? '"e+1"' : '"e-1"')
				Binding { target: ws; property: "pillX"; value: num.x; when: num.active; restoreMode: Binding.RestoreNone }
				Binding { target: ws; property: "pillW"; value: num.width; when: num.active; restoreMode: Binding.RestoreNone }
			}
		}
	}
}
