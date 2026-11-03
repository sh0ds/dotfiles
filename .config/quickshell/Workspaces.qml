// Numbered workspaces of one screen. 1-5 always show on DP-4, even empty.
// Blue underline for the active one, amber for urgent. Scroll walks through
// the open ones like Waybar did.
import QtQuick
import Quickshell
import Quickshell.Hyprland

Row {
	id: ws
	required property ShellScreen screen
	readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
	readonly property int activeId: monitor?.activeWorkspace?.id ?? -1

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

	Repeater {
		model: ws.ids()
		Cell {
			required property int modelData
			readonly property bool active: modelData === ws.activeId
			readonly property bool hot: ws.urgent(modelData)
			text: String(modelData)
			rule: false
			pad: 9
			textColor: hot ? Theme.warn : active ? Theme.ink : Theme.mid
			restColor: active ? Theme.panel : "transparent"
			underline: hot ? Theme.warn : active ? Theme.arch : "transparent"
			onClicked: ws.go(modelData)
			onScrolled: d => ws.go(d > 0 ? '"e+1"' : '"e-1"')
		}
	}
}
