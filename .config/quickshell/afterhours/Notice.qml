import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
Rectangle {
    id: card
    required property var notification
    property bool toast: false
    property bool timedOut: false
    visible: notification != null && !timedOut
    implicitHeight: timedOut ? 0 : body.implicitHeight + 28
    color: Theme.panel
    border.color: notification?.urgency === NotificationUrgency.Critical ? Theme.danger : Theme.line
    border.width: 1; radius: 3
    Timer {
        interval: Math.max(1000, ((card.notification?.expireTimeout ?? 0) > 0 ? card.notification.expireTimeout * 1000 : 6500))
        running: card.notification != null && card.toast && card.notification.urgency !== NotificationUrgency.Critical
        onTriggered: { if (!card.notification) return; if (card.notification.transient) card.notification.expire(); else card.timedOut = true; }
    }
    ColumnLayout {
        id: body
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
        spacing: 8
        RowLayout {
            Text { text: card.notification?.appName ?? ""; color: Theme.blue; font.family: Theme.mono; font.pixelSize: 10; textFormat: Text.PlainText; Layout.fillWidth: true; elide: Text.ElideRight }
            Cell { label: "×"; implicitWidth: 26; implicitHeight: 24; onClicked: card.notification?.dismiss() }
        }
        Text { text: card.notification?.summary ?? ""; color: Theme.text; font.family: Theme.sans; font.pixelSize: 14; font.bold: true; textFormat: Text.PlainText; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        Text { text: card.notification?.body ?? ""; color: Theme.muted; font.family: Theme.sans; font.pixelSize: 12; textFormat: Text.PlainText; wrapMode: Text.WordWrap; maximumLineCount: card.toast ? 3 : 12; elide: Text.ElideRight; Layout.fillWidth: true; visible: text.length > 0 }
        Flow {
            Layout.fillWidth: true; spacing: 6
            Repeater { model: card.notification?.actions ?? []; Cell { required property var modelData; label: modelData.text; onClicked: modelData.invoke() } }
        }
    }
}
