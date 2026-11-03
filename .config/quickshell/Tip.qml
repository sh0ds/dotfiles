// Hover text under a bar cell, in the old Waybar tooltip style: panel
// colour, a rule border and a blue top edge. Shows after 400 ms of hover.
import QtQuick
import Quickshell

PopupWindow {
	id: tip
	required property Item target
	property string text: ""
	property bool hovered: false

	anchor.item: target
	anchor.edges: Edges.Bottom
	anchor.gravity: Edges.Bottom
	visible: wait.done && hovered && text !== ""
	color: "transparent"
	implicitWidth: body.implicitWidth + 14
	implicitHeight: body.implicitHeight + 14

	onHoveredChanged: { wait.done = false; if (hovered) wait.restart(); }
	Timer { id: wait; property bool done: false; interval: 400; onTriggered: done = true }

	Rectangle {
		anchors.fill: parent
		color: Theme.panel
		border.color: Theme.rule
		border.width: 1
		Rectangle {
			anchors { left: parent.left; right: parent.right; top: parent.top }
			height: 2
			color: Theme.arch
		}
		Text {
			id: body
			anchors.centerIn: parent
			text: tip.text
			textFormat: Text.PlainText
			color: Theme.ink
			font.family: Theme.font
			font.pixelSize: 16
		}
	}
}
