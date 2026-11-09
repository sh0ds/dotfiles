import QtQuick
import QtQuick.Layouts
// A small heading over a block: violet caps, then a hairline running to
// the end of the block, so every section reads like a labelled panel.
RowLayout {
    id: caption
    property string text: ""
    Layout.fillWidth: true
    spacing: 8
    Text {
        text: caption.text
        color: Theme.accent
        font.family: Theme.font; font.pixelSize: 10; font.letterSpacing: 2; font.bold: true
        textFormat: Text.PlainText
    }
    Rectangle { Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; implicitHeight: 1; color: Theme.line }
}
