import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
// One notification card. Clicking the card runs its default action (nchat's
// chat-notify opens WhatsApp that way); × dismisses it.
Rectangle {
    id: card
    required property var notification
    property bool toast: false
    readonly property bool hovered: hover.hovered
    readonly property var defaultAction: notification ? notification.actions.find(a => a.identifier === "default") ?? null : null
    visible: notification != null
    implicitHeight: body.implicitHeight + 28
    // A toast is glass of its own; in the inbox it sits in the sheet's glass.
    color: hover.hovered ? Theme.glassRaised : toast ? Theme.glass : Theme.well
    border.color: notification?.urgency === NotificationUrgency.Critical ? Theme.danger : Theme.edge
    border.width: 1
    radius: Theme.radius + 2
    Behavior on color { ColorAnimation { duration: Theme.motion; easing.type: Easing.OutCubic } }
    HoverHandler { id: hover }
    // Under the content, so the × and action buttons keep their own clicks.
    MouseArea {
        anchors.fill: parent
        cursorShape: card.defaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (card.defaultAction) card.defaultAction.invoke()
    }
    ColumnLayout {
        id: body
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 14 }
        spacing: 6
        RowLayout {
            spacing: 6
            // The sender's icon; apps without one just show their name.
            Image {
                id: appIcon
                readonly property string named: card.notification?.appIcon ?? ""
                source: named.startsWith("/") || named.startsWith("file:") ? named : (named.length > 0 ? Quickshell.iconPath(named, true) : "")
                visible: status === Image.Ready
                sourceSize { width: 32; height: 32 }
                Layout.preferredWidth: 16; Layout.preferredHeight: 16
                fillMode: Image.PreserveAspectFit; smooth: true
            }
            Text { text: (card.notification?.appName ?? "").toLowerCase(); color: Theme.muted; font.family: Theme.font; font.pixelSize: 11; textFormat: Text.PlainText; Layout.fillWidth: true; elide: Text.ElideRight }
            Cell { label: "×"; implicitWidth: 26; implicitHeight: 24; onClicked: card.notification?.dismiss() }
        }
        Text { text: card.notification?.summary ?? ""; color: Theme.text; font.family: Theme.font; font.pixelSize: 14; font.bold: true; textFormat: Text.PlainText; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        Text { text: card.notification?.body ?? ""; color: Theme.muted; font.family: Theme.font; font.pixelSize: 12; textFormat: Text.PlainText; wrapMode: Text.WordWrap; maximumLineCount: card.toast ? 3 : 12; elide: Text.ElideRight; Layout.fillWidth: true; visible: text.length > 0 }
        Flow {
            Layout.fillWidth: true; spacing: 6
            visible: actionRepeater.count > 0
            Repeater {
                id: actionRepeater
                model: (card.notification?.actions ?? []).filter(a => a.identifier !== "default")
                Cell { required property var modelData; label: modelData.text; fill: Theme.glassRaised; onClicked: modelData.invoke() }
            }
        }
    }
}
