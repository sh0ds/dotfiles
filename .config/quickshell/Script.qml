// One bar script. interval > 0: run it every interval ms and keep its last
// line. interval 0: it streams lines (live-status, swaync-client -swb) and is
// started again 5 s after it exits.
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
	id: script
	required property list<string> command
	property int interval: 0
	property string text: ""
	property string cls: ""
	property string alt: ""
	property string tooltip: ""

	function refresh() { proc.running = true; }

	Process {
		id: proc
		command: script.command
		running: true
		stdout: SplitParser {
			onRead: data => {
				try {
					const j = JSON.parse(data);
					script.text = String(j.text ?? "");
					script.cls = Array.isArray(j.class) ? j.class.join(" ") : String(j.class ?? "");
					script.alt = String(j.alt ?? "");
					script.tooltip = String(j.tooltip ?? "");
				} catch (e) {}
			}
		}
		onExited: if (script.interval === 0) restart.start()
	}
	Timer {
		interval: Math.max(script.interval, 1000)
		running: script.interval > 0
		repeat: true
		onTriggered: proc.running = true
	}
	Timer { id: restart; interval: 5000; onTriggered: proc.running = true }
}
