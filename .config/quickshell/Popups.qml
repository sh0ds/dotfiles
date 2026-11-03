// New notifications, top right under the bar. Each card slides in from the
// right and leaves after its timeout (low 3 s, normal 6 s, critical stays),
// paused while the pointer is on it. Only the cards take clicks.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications

PanelWindow {
	id: pop
	screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
	anchors { top: true; right: true }
	margins { top: 6; right: 10 }
	exclusiveZone: 0
	implicitWidth: 384
	implicitHeight: Math.max(1, stack.implicitHeight)
	color: "transparent"
	visible: Notes.popups.length > 0
	mask: Region { item: stack }
	WlrLayershell.namespace: "diag-notes"
	WlrLayershell.layer: WlrLayer.Overlay

	Column {
		id: stack
		width: parent.width
		spacing: 8
		Repeater {
			model: Notes.popups
			NoteCard {
				id: card
				required property Notification modelData
				note: modelData
				width: stack.width
				readonly property int timeout: modelData.expireTimeout > 0 ? modelData.expireTimeout
					: modelData.urgency === NotificationUrgency.Low ? 3000
					: modelData.urgency === NotificationUrgency.Critical ? 0 : 6000
				Timer {
					interval: card.timeout
					running: card.timeout > 0 && !card.hovered
					onTriggered: Notes.removePopup(card.modelData)
				}
				transform: Translate { id: slide; x: 0 }
				Component.onCompleted: enter.start()
				ParallelAnimation {
					id: enter
					NumberAnimation { target: slide; property: "x"; from: 60; to: 0; duration: Theme.glide; easing.type: Easing.OutCubic }
					NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: Theme.ease; easing.type: Easing.OutQuint }
				}
			}
		}
	}
}
