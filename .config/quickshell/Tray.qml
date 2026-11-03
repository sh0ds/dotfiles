// Tray icons at 14 px. Click activates the app, right-click opens its menu.
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray

Rectangle {
	id: tray
	required property QsWindow bar
	visible: SystemTray.items.values.length > 0
	implicitWidth: icons.implicitWidth + 16
	implicitHeight: Theme.height - 1
	color: "transparent"

	Rectangle {
		width: 1
		anchors { left: parent.left; top: parent.top; bottom: parent.bottom; topMargin: 3; bottomMargin: 3 }
		color: Theme.rule
	}
	Row {
		id: icons
		anchors.centerIn: parent
		spacing: 6
		Repeater {
			model: SystemTray.items.values
			IconImage {
				id: icon
				required property SystemTrayItem modelData
				source: modelData.icon
				implicitSize: 14
				MouseArea {
					anchors.fill: parent
					acceptedButtons: Qt.LeftButton | Qt.RightButton
					onClicked: e => {
						const item = icon.modelData;
						if ((e.button === Qt.RightButton || item.onlyMenu) && item.hasMenu) {
							const p = icon.mapToItem(null, 0, tray.height);
							item.display(tray.bar, p.x, p.y);
						} else {
							item.activate();
						}
					}
				}
			}
		}
	}
}
