// The clock in the middle: big, bold, on the panel colour with a blue
// underline. Hover gives the date, click opens the month calendar.
import QtQuick
import Quickshell

Cell {
	id: clock
	SystemClock { id: time; precision: SystemClock.Minutes }

	text: Qt.formatTime(time.date, "HH:mm")
	tip: Qt.formatDate(time.date, "dddd · yyyy-MM-dd")
	size: 22
	bold: true
	pad: 14
	ruleRight: true
	textColor: Theme.ink
	restColor: Theme.panel
	underline: Theme.arch
	onClicked: cal.visible = !cal.visible

	Calendar { id: cal; target: clock; today: time.date }
}
