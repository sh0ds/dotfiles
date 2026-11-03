// One notification on a glass card: icon, app and age, summary, body,
// action buttons and a close button. Clicking the card runs its default
// action (chat-notify uses that to open WhatsApp). Critical ones get a red
// edge. Used by the popups and the centre.
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

Rectangle {
	id: card
	required property Notification note
	property bool solid: true
	readonly property bool hovered: hover.hovered
	readonly property bool critical: note?.urgency === NotificationUrgency.Critical
	readonly property string icon: {
		const n = note;
		if (!n) return "";
		if (n.image) return n.image;
		const a = n.appIcon;
		if (!a) return "";
		if (a.startsWith("/") || a.startsWith("file:") || a.startsWith("image:")) return a;
		return Quickshell.iconPath(a, true);
	}
	readonly property var defaultAction: note ? note.actions.find(a => a.identifier === "default") ?? null : null

	implicitHeight: content.implicitHeight + 24
	radius: 12
	color: solid ? Theme.glass : (hovered ? Theme.hover : "#0dffffff")
	border.width: 1
	border.color: critical ? "#b3e5484d" : Theme.edge
	Behavior on color { ColorAnimation { duration: Theme.ease; easing.type: Easing.OutQuint } }

	HoverHandler { id: hover }
	TapHandler { onTapped: if (card.defaultAction) card.defaultAction.invoke() }

	Row {
		id: content
		anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
		spacing: 12

		IconImage {
			id: img
			visible: card.icon !== ""
			source: card.icon
			implicitSize: 40
		}
		Column {
			width: content.width - (img.visible ? img.width + content.spacing : 0)
			spacing: 4
			Item {
				width: parent.width
				height: app.implicitHeight
				Text {
					id: app
					anchors.left: parent.left
					width: parent.width - 60
					elide: Text.ElideRight
					text: (card.note?.appName || "notification").toLowerCase() + "  " + Notes.age(card.note)
					color: Theme.mid
					font.family: Theme.font
					font.pixelSize: 15
					font.hintingPreference: Font.PreferFullHinting
				}
				Rectangle {
					anchors { right: parent.right; verticalCenter: parent.verticalCenter }
					width: 22; height: 22; radius: 11
					color: closeBtn.containsMouse ? Theme.error : "#14ffffff"
					opacity: card.hovered ? 1 : 0
					Behavior on opacity { NumberAnimation { duration: Theme.ease } }
					Behavior on color { ColorAnimation { duration: Theme.ease } }
					Text {
						anchors.centerIn: parent
						text: "×"
						color: closeBtn.containsMouse ? "#000000" : Theme.fg
						font.family: Theme.font
						font.pixelSize: 16
					}
					MouseArea { id: closeBtn; anchors.fill: parent; hoverEnabled: true; onClicked: card.note.dismiss() }
				}
			}
			Text {
				width: parent.width
				text: card.note?.summary ?? ""
				color: Theme.ink
				font.family: Theme.font
				font.pixelSize: Theme.size
				font.bold: true
				font.hintingPreference: Font.PreferFullHinting
				elide: Text.ElideRight
				textFormat: Text.PlainText
			}
			Text {
				width: parent.width
				visible: text !== ""
				text: card.note?.body ?? ""
				color: Theme.fg
				font.family: Theme.font
				font.pixelSize: 16
				font.hintingPreference: Font.PreferFullHinting
				wrapMode: Text.Wrap
				maximumLineCount: 4
				elide: Text.ElideRight
				textFormat: Text.StyledText
				onLinkActivated: link => Qt.openUrlExternally(link)
			}
			Flow {
				width: parent.width
				spacing: 6
				topPadding: 4
				visible: actions.count > 0
				Repeater {
					id: actions
					model: (card.note?.actions ?? []).filter(a => a.identifier !== "default")
					Rectangle {
						required property NotificationAction modelData
						width: label.implicitWidth + 24
						height: 30
						radius: 8
						color: act.containsMouse ? Theme.tint : "#14ffffff"
						Behavior on color { ColorAnimation { duration: Theme.ease } }
						Text {
							id: label
							anchors.centerIn: parent
							text: modelData.text
							color: Theme.ink
							font.family: Theme.font
							font.pixelSize: 16
							font.hintingPreference: Font.PreferFullHinting
						}
						MouseArea { id: act; anchors.fill: parent; hoverEnabled: true; onClicked: modelData.invoke() }
					}
				}
			}
		}
	}
}
