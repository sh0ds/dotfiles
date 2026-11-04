import QtQuick
import QtQuick.Layouts
import Quickshell
// The month, for the dashboard. Monday first, ISO week numbers on the left,
// today as a violet pill. ‹ › or the wheel change the month, the month
// title jumps back to today.
// Not "Calendar" or "MonthGrid": QtQuick.Controls has types by those names.
Item {
    id: cal
    property int shift: 0
    readonly property date today: clockNow.date
    readonly property date first: new Date(today.getFullYear(), today.getMonth() + shift, 1)
    implicitWidth: body.implicitWidth
    implicitHeight: body.implicitHeight

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

    WheelHandler { onWheel: e => cal.shift += e.angleDelta.y > 0 ? -1 : 1 }
    // Changing month slides the days in from the side you're heading to.
    property int lastShift: 0
    onShiftChanged: { flip.dir = shift > lastShift ? 1 : -1; lastShift = shift; flip.restart(); }
    ParallelAnimation {
        id: flip
        property int dir: 1
        NumberAnimation { target: slide; property: "x"; from: 18 * flip.dir; to: 0; duration: Theme.spring; easing.type: Easing.OutBack; easing.overshoot: Theme.overshoot }
        NumberAnimation { target: dayGrid; property: "opacity"; from: 0.2; to: 1; duration: Theme.glide; easing.type: Easing.OutCubic }
    }

    ColumnLayout {
        id: body
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
            id: dayGrid
            transform: Translate { id: slide }
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
