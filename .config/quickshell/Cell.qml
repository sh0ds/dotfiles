// A bar cell: Terminess text on a rounded hover pill. A short rounded line
// under the text marks state (the clock, hot readings). clicked(button) and
// scrolled(delta) for the actions.
import QtQuick

Item {
	id: cell
	property string text: ""
	property color textColor: Theme.fg
	property color hoverText: Theme.ink
	property color hoverColor: Theme.hover
	property color restColor: "transparent"
	property int pad: 10
	property int size: Theme.size
	property bool bold: false
	property string tip: ""
	property color underline: "transparent"
	readonly property bool hovered: mouse.containsMouse
	signal clicked(int button)
	signal scrolled(int delta)

	implicitWidth: label.implicitWidth + 2 * pad
	implicitHeight: Theme.height

	Rectangle {
		anchors { fill: parent; topMargin: 4; bottomMargin: 4; leftMargin: 2; rightMargin: 2 }
		radius: 7
		color: cell.hovered ? cell.hoverColor : cell.restColor
		Behavior on color { ColorAnimation { duration: Theme.ease; easing.type: Easing.OutQuint } }
	}
	Rectangle {
		anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 5 }
		width: label.implicitWidth * 0.6
		height: 2
		radius: 1
		color: cell.underline
		Behavior on color { ColorAnimation { duration: Theme.ease; easing.type: Easing.OutQuint } }
	}
	Text {
		id: label
		anchors.centerIn: parent
		// StyledText folds runs of spaces like HTML; keep them outside tags.
		text: cell.text.replace(/ (?![^<]*>)/g, "&nbsp;")
		textFormat: Text.StyledText
		color: cell.hovered ? cell.hoverText : cell.textColor
		font.family: Theme.font
		font.pixelSize: cell.size
		font.hintingPreference: Font.PreferFullHinting
		font.bold: cell.bold
		Behavior on color { ColorAnimation { duration: Theme.ease; easing.type: Easing.OutQuint } }
	}
	MouseArea {
		id: mouse
		anchors.fill: parent
		hoverEnabled: true
		acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
		onClicked: e => cell.clicked(e.button)
		onWheel: e => cell.scrolled(e.angleDelta.y)
	}
	Tip {
		target: cell
		text: cell.tip
		hovered: cell.hovered
	}
}
