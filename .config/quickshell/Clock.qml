// The clock in the middle, large and bright. Hover gives the date, click
// opens the month calendar.
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
	textColor: Theme.ink
	underline: cal.visible ? Theme.arch : "transparent"
	onClicked: cal.visible = !cal.visible

	Calendar { id: cal; target: clock; today: time.date }
}
