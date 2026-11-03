import QtQuick
import QtQuick.Layouts
import Quickshell
// Month calendar under the rail's clock. Monday first, ISO week numbers on
// the left, today as a violet pill. ‹ › or the wheel change the month,
// the month title jumps back to today; a click outside closes it.
PopupWindow {
    id: cal
    required property Item target
    property int shift: 0
    readonly property date today: clockNow.date
    readonly property date first: new Date(today.getFullYear(), today.getMonth() + shift, 1)

    anchor.item: target
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 10
    grabFocus: true
    visible: false
    color: "transparent"
    implicitWidth: 308
    implicitHeight: body.implicitHeight + 32
    onVisibleChanged: if (visible) { shift = 0; intro.restart(); }

    SystemClock { id: clockNow; precision: SystemClock.Hours }

    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        t.setUTCDate(t.getUTCDate() + 4 - (t.getUTCDay() || 7));
        const y0 = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
        return Math.ceil(((t - y0) / 86400000 + 1) / 7);
    }
    // Six rows of seven days starting on the Monday on or before the 1st.
    readonly property var days: {
        const lead = (first.getDay() + 6) % 7;
        const out = [];
        for (let i = 0; i < 42; i++) out.push(new Date(first.getFullYear(), first.getMonth(), 1 - lead + i));
        return out;
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Theme.radiusLarge
        color: Theme.panel
        border.width: 1
        border.color: Theme.line
        opacity: 0
        transform: Translate { id: drop; y: -6 }
        ParallelAnimation {
            id: intro
            NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: Theme.motion; easing.type: Easing.OutCubic }
            NumberAnimation { target: drop; property: "y"; from: -6; to: 0; duration: Theme.glide; easing.type: Easing.OutCubic }
        }

        WheelHandler { onWheel: e => cal.shift += e.angleDelta.y > 0 ? -1 : 1 }

        ColumnLayout {
            id: body
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Cell { label: "‹"; size: 15; implicitWidth: 32; onClicked: cal.shift-- }
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 32
                    Text {
                        anchors.centerIn: parent
                        text: Qt.formatDate(cal.first, "MMMM yyyy")
                        color: cal.shift === 0 ? Theme.text : Theme.accent
                        font.family: Theme.font; font.pixelSize: 14; font.bold: true
                    }
                    MouseArea { anchors.fill: parent; cursorShape: cal.shift ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: cal.shift = 0 }
                }
                Cell { label: "›"; size: 15; implicitWidth: 32; onClicked: cal.shift++ }
            }

            GridLayout {
                columns: 8
                columnSpacing: 2
                rowSpacing: 2
                Layout.alignment: Qt.AlignHCenter
                Repeater {
                    model: ["", "Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                    Text {
                        required property string modelData
                        Layout.preferredWidth: 32
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: modelData === "Sa" || modelData === "Su" ? Theme.amber : Theme.muted
                        opacity: 0.8
                        font.family: Theme.font; font.pixelSize: 11
                    }
                }
                Repeater {
                    model: 48
                    Item {
                        id: slot
                        required property int index
                        readonly property bool week: index % 8 === 0
                        readonly property date day: cal.days[Math.floor(index / 8) * 7 + (index % 8) - 1] ?? new Date()
                        readonly property bool inMonth: !week && day.getMonth() === cal.first.getMonth()
                        readonly property bool isToday: !week && day.toDateString() === cal.today.toDateString()
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 30
                        Rectangle {
                            anchors.centerIn: parent
                            width: 30; height: 26
                            radius: 13
                            visible: slot.isToday
                            color: Theme.accent
                        }
                        Text {
                            anchors.centerIn: parent
                            text: slot.week ? cal.isoWeek(cal.days[Math.floor(slot.index / 8) * 7]) : slot.day.getDate()
                            color: slot.isToday ? Theme.background
                                : slot.week ? Theme.muted
                                : slot.inMonth ? Theme.text : Theme.line
                            font.family: Theme.font
                            font.pixelSize: slot.week ? 10 : 13
                            font.bold: slot.isToday
                            opacity: slot.week ? 0.55 : 1
                        }
                    }
                }
            }
        }
    }
}
