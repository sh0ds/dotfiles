// Tray icons at 16 px. Click activates the app, right-click opens its menu.
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray

Item {
	id: tray
	required property QsWindow bar
	visible: SystemTray.items.values.length > 0
	implicitWidth: icons.implicitWidth + 20
	implicitHeight: Theme.height

	Row {
		id: icons
		anchors.centerIn: parent
		spacing: 8
		Repeater {
			model: SystemTray.items.values
			IconImage {
				id: icon
				required property SystemTrayItem modelData
				source: modelData.icon
				implicitSize: 16
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
