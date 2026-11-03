// LIVE and REC: black bold text on a rounded colour pill, only while active.
import QtQuick

Item {
	id: badge
	property string text: ""
	property color fill: Theme.arch
	signal clicked()
	visible: text !== ""
	implicitWidth: visible ? label.implicitWidth + 20 + 8 : 0
	implicitHeight: Theme.height

	Rectangle {
		anchors { fill: parent; leftMargin: 4; rightMargin: 4; topMargin: 5; bottomMargin: 5 }
		radius: height / 2
		color: badge.fill
		Text {
			id: label
			anchors.centerIn: parent
			text: badge.text
			color: "#000000"
			font.family: Theme.font
			font.pixelSize: 16
			font.hintingPreference: Font.PreferFullHinting
			font.bold: true
		}
		MouseArea { anchors.fill: parent; onClicked: badge.clicked() }
	}
}
