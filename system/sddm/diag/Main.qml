// Diag: SDDM login screen in the look of sh0ds.dev, recoloured in Arch blue.
// Same layout as the lock screen (hyprlock.conf): pixel Arch logo top left
// with diagnostic lines next to it, the clock and the prompt in the middle,
// keys along the bottom. Only QtQuick, no Controls, so nothing gets styled
// behind our back. Qt 6 (metadata.desktop says QtVersion=6).
import QtQuick

Rectangle {
    id: root
    color: "#000000"

    readonly property color rule: "#3f4650"
    readonly property color dim: "#8a929c"
    readonly property color ink: "#e6e8ea"
    readonly property color arch: "#1793d1"
    readonly property color warn: "#ffb000"
    readonly property color error: "#e5484d"
    // VT323 is only sharp at 25 px and multiples of it, so every text is 25
    // px (the clock 175) and the layout is measured in that unit too.
    readonly property int unit: 25

    FontLoader { id: vt; source: "VT323-Regular.ttf" }
    readonly property string mono: vt.status === FontLoader.Ready ? vt.font.family : "monospace"

    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property string state_: ""        // "" | "busy" | "fail"

    Connections {
        target: sddm
        function onLoginFailed() {
            root.state_ = "fail"
            password.text = ""
            password.forceActiveFocus()
        }
        function onLoginSucceeded() { root.state_ = "" }
    }

    function doLogin() {
        if (user.text === "" || password.text === "") return
        root.state_ = "busy"
        sddm.login(user.text, password.text, root.sessionIndex)
    }

    // Session names by index (sessionModel only hands them to delegates)
    property var sessionNames: []
    readonly property string sessionName: sessionNames[sessionIndex] || "-"
    Repeater {
        id: sessions
        model: sessionModel
        delegate: Item {
            Component.onCompleted: {
                var names = root.sessionNames.slice()
                names[index] = model.name
                root.sessionNames = names
            }
        }
    }

    // ---- Header: logo (46 x 46 pixels at 3x) and the lines next to it ----
    Image {
        id: logo
        source: "arch-logo.png"
        x: 48; y: 40
        width: 138; height: 138
        smooth: false
    }
    Column {
        x: logo.x + logo.width + 28
        y: logo.y - 4
        spacing: 4
        Text { text: "Arch Linux\u00a0\u00a0" + Qt.formatDate(clock.now, "yyyy-MM-dd"); color: root.dim; font.family: root.mono; font.pixelSize: root.unit; renderType: Text.NativeRendering }
        Text { textFormat: Text.StyledText; text: "<font color='#1793d1'>host:</font> " + sddm.hostName; color: root.ink; font.family: root.mono; font.pixelSize: root.unit; renderType: Text.NativeRendering }
        Text { textFormat: Text.StyledText; text: "<font color='#1793d1'>sess:</font> " + root.sessionName; color: root.ink; font.family: root.mono; font.pixelSize: root.unit; renderType: Text.NativeRendering }
        Text { textFormat: Text.StyledText; text: "<font color='#1793d1'>boot:</font> login"; color: root.ink; font.family: root.mono; font.pixelSize: root.unit; renderType: Text.NativeRendering }
    }

    // The site's double rule under the header
    Column {
        x: 48; y: logo.y + logo.height + 24
        width: root.width - 96
        spacing: 3
        Rectangle { width: parent.width; height: 2; color: root.rule }
        Rectangle { width: parent.width; height: 2; color: root.rule }
    }

    // One field: "key:" in blue, the value in a 2 px frame that turns blue on focus
    component Field: Row {
        id: field
        property alias key: label.text
        property alias input: inp
        property bool secret: false
        spacing: root.unit * 0.6
        Text {
            id: label
            width: root.unit * 5.5
            height: root.unit * 2
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            color: root.arch
            font.family: root.mono
            renderType: Text.NativeRendering
            font.pixelSize: root.unit
        }
        Rectangle {
            width: root.unit * 16
            height: root.unit * 2
            color: "#000000"
            border.width: 2
            border.color: inp.activeFocus ? root.arch : root.rule
            TextInput {
                id: inp
                anchors.fill: parent
                anchors.leftMargin: root.unit * 0.5
                anchors.rightMargin: root.unit * 0.5
                verticalAlignment: TextInput.AlignVCenter
                color: "#ffffff"
                selectionColor: root.arch
                selectedTextColor: "#000000"
                font.family: root.mono
                renderType: TextInput.NativeRendering
                font.pixelSize: root.unit
                echoMode: field.secret ? TextInput.Password : TextInput.Normal
                passwordCharacter: "*"
                clip: true
                cursorDelegate: Rectangle { width: root.unit * 0.6; color: root.arch; visible: inp.activeFocus }
            }
        }
    }


    // ---- Middle: clock and prompt ----
    QtObject {
        id: clock
        property date now: new Date()
    }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: clock.now = new Date() }

    Column {
        anchors.centerIn: parent
        spacing: root.unit

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(clock.now, "HH:mm")
            color: "#ffffff"
            font.family: root.mono
            renderType: Text.NativeRendering
            font.pixelSize: root.unit * 7
        }

        Field {
            id: userField
            anchors.horizontalCenter: parent.horizontalCenter
            key: "user:"
            Component.onCompleted: input.text = userModel.lastUser
        }
        Field {
            id: passField
            anchors.horizontalCenter: parent.horizontalCenter
            key: "password:"
            secret: true
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            textFormat: Text.StyledText
            text: root.state_ === "fail" ? "<font color='#e5484d'>fail:</font> wrong password"
                : root.state_ === "busy" ? "<font color='#1793d1'>load:</font> starting " + root.sessionName
                : (clock.now.getHours() < 5 ? "<font color='#ffb000'>warn:</font> it's late. go to bed." : " ")
            color: root.ink
            font.family: root.mono
            renderType: Text.NativeRendering
            font.pixelSize: root.unit
        }
    }

    // Short names for the two inputs
    readonly property var user: userField.input
    readonly property var password: passField.input

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_F1 && sddm.canPowerOff) { sddm.powerOff(); event.accepted = true }
        else if (event.key === Qt.Key_F2 && sddm.canReboot) { sddm.reboot(); event.accepted = true }
        else if (event.key === Qt.Key_F3 && sessions.count > 0) {
            root.sessionIndex = (root.sessionIndex + 1) % sessions.count; event.accepted = true
        }
    }

    Connections {
        target: userField.input
        function onAccepted() { passField.input.forceActiveFocus() }
    }
    Connections {
        target: passField.input
        function onAccepted() { root.doLogin() }
        function onTextEdited() { if (root.state_ === "fail") root.state_ = "" }
    }

    // ---- Bottom: the keys, like the hints on a boot screen ----
    Text {
        x: 48
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 36
        textFormat: Text.StyledText
        text: "<font color='#1793d1'>F1</font> halt&nbsp;&nbsp;&nbsp;<font color='#1793d1'>F2</font> reboot&nbsp;&nbsp;&nbsp;<font color='#1793d1'>F3</font> session&nbsp;&nbsp;&nbsp;<font color='#1793d1'>Enter</font> boot"
        color: root.dim
        font.family: root.mono
        renderType: Text.NativeRendering
        font.pixelSize: root.unit
    }

    // After the fields have their values (children finish loading in any order)
    Component.onCompleted: Qt.callLater(function() {
        if (userField.input.text === "") userField.input.forceActiveFocus()
        else passField.input.forceActiveFocus()
    })
}
