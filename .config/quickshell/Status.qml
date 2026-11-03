pragma Singleton
// The bar's script readings, run once for all screens. Each prints Waybar's
// JSON ({text, class, tooltip}); see Script.qml.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
	readonly property Script stats: Script { command: ["bar-stats"]; interval: 2000 }
	readonly property Script pi: Script { command: ["pi-status"]; interval: 30000 }
	readonly property Script rec: Script { command: ["rec-status"]; interval: 1000 }
	readonly property Script live: Script { command: ["live-status"] }
	readonly property Script notes: Script { command: ["swaync-client", "-swb"] }

	// sys: click opens or closes the readings, then read again at once.
	function toggleStats() { toggler.running = true; }
	Process {
		id: toggler
		command: ["bar-stats", "toggle"]
		onExited: stats.refresh()
	}
}
