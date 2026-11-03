// LIVE and REC: black bold text on a colour block, only while active.
import QtQuick

Item {
	id: badge
	property string text: ""
	property color fill: Theme.arch
	signal clicked()
	visible: text !== ""
	implicitWidth: visible ? label.implicitWidth + 16 + 8 : 0
	implicitHeight: Theme.height - 1

	Rectangle {
		anchors { fill: parent; leftMargin: 4; rightMargin: 4; topMargin: 1; bottomMargin: 1 }
		color: badge.fill
		Text {
			id: label
			anchors.centerIn: parent
			text: badge.text
			color: "#000000"
			font.family: Theme.font
			font.pixelSize: Theme.size
			font.bold: true
		}
		MouseArea { anchors.fill: parent; onClicked: badge.clicked() }
	}
}
