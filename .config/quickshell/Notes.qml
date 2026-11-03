pragma Singleton
// The notification daemon, replacing swaync. Keeps every notification until
// it's dismissed (the centre lists them), shows new ones as popups unless
// quiet (do-not-disturb) is on, and answers `qs ipc call notes ...`:
//   toggle | open | close       the notification centre (SUPER+N)
//   quietOn | quietOff | quietToggle | quiet
// Quiet is mirrored to $XDG_RUNTIME_DIR/diag-dnd for frame and live-status.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
	id: notes
	property bool quiet: false
	property bool centerOpen: false
	// Popups on screen right now, newest first.
	property var popups: []
	// Arrival times by notification id, for "now", "4m", "2h".
	property var times: ({})
	readonly property var list: server.trackedNotifications.values
	readonly property int count: list.length
	readonly property string flag: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/diag-dnd"

	function removePopup(n) { popups = popups.filter(p => p !== n); }
	function clearAll() {
		for (const n of [...list]) n.dismiss();
		popups = [];
		centerOpen = false;
	}
	function setQuiet(on) {
		quiet = on;
		Quickshell.execDetached(on ? ["touch", flag] : ["rm", "-f", flag]);
	}
	function age(n) {
		const t = times[n.id];
		if (!t) return "";
		const m = Math.floor((clock.date - t) / 60000);
		return m < 1 ? "now" : m < 60 ? m + "m" : m < 1440 ? Math.floor(m / 60) + "h" : Math.floor(m / 1440) + "d";
	}

	SystemClock { id: clock; precision: SystemClock.Minutes }
	onCenterOpenChanged: if (centerOpen) popups = []

	// KDE Connect mirrors WhatsApp from the phone; nchat already alerts for
	// those (chat-notify), so the copies are dropped. Other phone apps stay.
	function ignored(n) {
		return /^(kde\s*connect|kdeconnect(d|\.daemon)?)$/i.test(n.appName)
			&& /^whatsapp( business)?$/i.test(n.summary);
	}

	NotificationServer {
		id: server
		keepOnReload: true
		actionsSupported: true
		imageSupported: true
		bodyMarkupSupported: true
		bodyHyperlinksSupported: true
		persistenceSupported: true
		onNotification: n => {
			if (notes.ignored(n)) return;
			n.tracked = true;
			notes.times[n.id] = new Date();
			n.closed.connect(() => notes.removePopup(n));
			const critical = n.urgency === NotificationUrgency.Critical;
			if (!notes.centerOpen && (!notes.quiet || critical))
				notes.popups = [n, ...notes.popups.filter(p => p !== n)].slice(0, 5);
		}
	}

	// Quiet survives a restart of the shell through the flag file.
	Process {
		running: true
		command: ["test", "-e", notes.flag]
		onExited: code => notes.quiet = code === 0
	}

	IpcHandler {
		target: "notes"
		function toggle(): void { notes.centerOpen = !notes.centerOpen; }
		function open(): void { notes.centerOpen = true; }
		function close(): void { notes.centerOpen = false; }
		function quietOn(): void { notes.setQuiet(true); }
		function quietOff(): void { notes.setQuiet(false); }
		function quietToggle(): void { notes.setQuiet(!notes.quiet); }
		function quiet(): string { return notes.quiet ? "true" : "false"; }
	}
}
