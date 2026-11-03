// A bar cell: a 1 px rule on the left, the row colour on hover, Terminess
// text. clicked(button) and scrolled(delta) for the actions.
import QtQuick

Rectangle {
	id: cell
	property string text: ""
	property color textColor: Theme.fg
	property color hoverText: Theme.ink
	property color hoverColor: Theme.row
	property color restColor: "transparent"
	property bool rule: true
	property bool ruleRight: false
	property int size: Theme.size
	property bool bold: false
	property int pad: 8
	property string tip: ""
	property color underline: "transparent"
	readonly property bool hovered: mouse.containsMouse
	signal clicked(int button)
	signal scrolled(int delta)

	implicitWidth: label.implicitWidth + 2 * pad
	implicitHeight: Theme.height - 1
	color: hovered ? hoverColor : restColor
	Behavior on color { ColorAnimation { duration: Theme.ease; easing.type: Easing.OutQuint } }

	Rectangle {
		visible: cell.rule
		width: 1
		anchors { left: parent.left; top: parent.top; bottom: parent.bottom; topMargin: 3; bottomMargin: 3 }
		color: Theme.rule
	}
	Rectangle {
		visible: cell.ruleRight
		width: 1
		anchors { right: parent.right; top: parent.top; bottom: parent.bottom; topMargin: 3; bottomMargin: 3 }
		color: Theme.rule
	}
	Rectangle {
		anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
		height: 2
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
