// A small rounded button in the centre: text on faint glass, blue tint on
// hover, solid blue with black text when `on`.
import QtQuick

Rectangle {
	id: pill
	property string text: ""
	property bool on: false
	property int size: 16
	signal clicked()
	implicitWidth: label.implicitWidth + 24
	implicitHeight: 34
	radius: 8
	color: on ? Theme.arch : mouse.containsMouse ? Theme.tint : "#0fffffff"
	border.width: 1
	border.color: on ? Theme.arch : Theme.edge
	Behavior on color { ColorAnimation { duration: Theme.ease; easing.type: Easing.OutQuint } }
	Text {
		id: label
		anchors.centerIn: parent
		text: pill.text
		color: pill.on ? "#000000" : Theme.ink
		font.family: Theme.font
		font.pixelSize: pill.size
		font.hintingPreference: Font.PreferFullHinting
	}
	MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; onClicked: pill.clicked() }
}
