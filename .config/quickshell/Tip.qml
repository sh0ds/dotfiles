// Hover text under a bar cell: a small glass card. Shows after 400 ms of
// hover and fades in.
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
	anchor.margins.top: 6
	visible: wait.done && hovered && text !== ""
	color: "transparent"
	implicitWidth: body.implicitWidth + 24
	implicitHeight: body.implicitHeight + 16

	onHoveredChanged: { wait.done = false; if (hovered) wait.restart(); }
	Timer { id: wait; property bool done: false; interval: 400; onTriggered: done = true }

	Glass {
		anchors.fill: parent
		opacity: tip.visible ? 1 : 0
		Behavior on opacity { NumberAnimation { duration: Theme.ease; easing.type: Easing.OutQuint } }
		Text {
			id: body
			anchors.centerIn: parent
			text: tip.text
			textFormat: Text.PlainText
			color: Theme.ink
			font.family: Theme.font
			font.pixelSize: 16
			font.hintingPreference: Font.PreferFullHinting
		}
	}
}
