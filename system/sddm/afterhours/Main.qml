// Afterhours login screen. The same picture as the lock screen
// (hyprlock.conf): the desktop wallpaper, a large clock with the date under
// it, and one rounded password pill. Your name sits above it as a chip; F3
// or the session pill switches session, the round buttons bottom right
// suspend, reboot and power off. Only QtQuick, no Controls, so nothing gets
// styled behind our back. Qt 6 (metadata.desktop says QtVersion=6).
import QtQuick

Rectangle {
    id: root
    color: "#0d0c10"

    // The Afterhours palette (Theme.qml in the shell)
    readonly property color panel: "#131218"
    readonly property color raised: "#1b1a22"
    readonly property color line: "#35323f"
    readonly property color muted: "#948fa3"
    readonly property color ink: "#e0dde8"
    readonly property color accent: "#b49cf0"
    readonly property color accentSoft: "#2a2340"
    readonly property color amber: "#d99f66"
    readonly property color danger: "#d9786c"
    readonly property string font: "JetBrainsMono Nerd Font"
    // Same pace as the shell: 200 ms for colour, 320 ms for movement.
    readonly property int motion: 200
    readonly property int glide: 320

    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property string state_: ""        // "" | "busy" | "fail"
    property string userName: userModel.lastUser

    Connections {
        target: sddm
        function onLoginFailed() {
            root.state_ = "fail"
            password.text = ""
            shake.restart()
            password.forceActiveFocus()
        }
        function onLoginSucceeded() { root.state_ = "" }
    }

    function doLogin() {
        if (root.userName === "" || password.text === "") return
        root.state_ = "busy"
        sddm.login(root.userName, password.text, root.sessionIndex)
    }

    // Session and user names by index (the models only hand them to delegates)
    property var sessionNames: []
    readonly property string sessionName: sessionNames[sessionIndex] || "Hyprland"
    Repeater {
        id: sessions
        model: sessionModel
        delegate: Item {
            Component.onCompleted: {
                const names = root.sessionNames.slice()
                names[index] = model.name
                root.sessionNames = names
            }
        }
    }
    property var userNames: []
    Repeater {
        id: users
        model: userModel
        delegate: Item {
            Component.onCompleted: {
                const names = root.userNames.slice()
                names[index] = model.name
                root.userNames = names
            }
        }
    }
    function nextUser() {
        if (root.userNames.length < 2) return
        const i = root.userNames.indexOf(root.userName)
        root.userName = root.userNames[(i + 1) % root.userNames.length]
    }

    // ---- Background: the desktop wallpaper, so login, lock and desktop are one place ----
    Image {
        anchors.fill: parent
        source: "background.png"
        fillMode: Image.PreserveAspectCrop
        smooth: true
    }

    QtObject { id: clock; property date now: new Date() }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: clock.now = new Date() }

    // ---- Middle: clock, date, who, password ----
    Column {
        id: centre
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -root.height * 0.04 + rise
        spacing: 0
        opacity: 0
        property real rise: 16
        // Fades in and rises a little on start, like a window opening.
        Component.onCompleted: { intro.start() }
        ParallelAnimation {
            id: intro
            NumberAnimation { target: centre; property: "opacity"; to: 1; duration: 600; easing.type: Easing.OutCubic }
            NumberAnimation { target: centre; property: "rise"; to: 0; duration: 700; easing.type: Easing.OutCubic }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(clock.now, "HH:mm")
            color: root.ink
            font.family: root.font
            font.pixelSize: 112
            font.weight: Font.Light
            font.letterSpacing: -2
            renderType: Text.NativeRendering
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(clock.now, "dddd · d MMMM")
            color: root.muted
            font.family: root.font
            font.pixelSize: 17
            renderType: Text.NativeRendering
        }

        Item { width: 1; height: 56 }

        // Who: a round initial in violet and the name. Click (or F4) for
        // the next user when there is more than one.
        Rectangle {
            id: who
            anchors.horizontalCenter: parent.horizontalCenter
            height: 40
            width: whoRow.implicitWidth + 12 + 20
            radius: height / 2
            color: whoHover.hovered && root.userNames.length > 1 ? root.raised : Qt.rgba(0.075, 0.071, 0.094, 0.85)
            border.width: 1
            border.color: root.line
            Behavior on color { ColorAnimation { duration: root.motion } }
            Row {
                id: whoRow
                x: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12
                Rectangle {
                    width: 28; height: 28; radius: 14
                    color: root.accentSoft
                    border.width: 1
                    border.color: root.accent
                    Text {
                        anchors.centerIn: parent
                        text: (root.userName || "?").charAt(0).toUpperCase()
                        color: root.accent
                        font.family: root.font
                        font.pixelSize: 14
                        font.bold: true
                        renderType: Text.NativeRendering
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.userName || "nobody"
                    color: root.ink
                    font.family: root.font
                    font.pixelSize: 15
                    renderType: Text.NativeRendering
                }
            }
            HoverHandler { id: whoHover; cursorShape: root.userNames.length > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor }
            TapHandler { onTapped: root.nextUser() }
        }

        Item { width: 1; height: 16 }

        // The password pill: a soft violet halo while it has focus,
        // coral and a short shake after a wrong password.
        Item {
            id: pill
            anchors.horizontalCenter: parent.horizontalCenter
            width: 360; height: 52
            property real shakeX: 0
            SequentialAnimation {
                id: shake
                NumberAnimation { target: pill; property: "shakeX"; to: -10; duration: 50 }
                NumberAnimation { target: pill; property: "shakeX"; to: 8; duration: 70 }
                NumberAnimation { target: pill; property: "shakeX"; to: -5; duration: 70 }
                NumberAnimation { target: pill; property: "shakeX"; to: 0; duration: 90; easing.type: Easing.OutCubic }
            }
            transform: Translate { x: pill.shakeX }
            readonly property color edge: root.state_ === "fail" ? root.danger : password.activeFocus ? root.accent : root.line

            Rectangle {
                anchors.fill: field
                anchors.margins: -5
                radius: field.radius + 5
                color: "transparent"
                border.width: 4
                border.color: pill.edge
                opacity: password.activeFocus || root.state_ === "fail" ? 0.16 : 0
                Behavior on opacity { NumberAnimation { duration: root.motion } }
                Behavior on border.color { ColorAnimation { duration: root.motion } }
            }
            Rectangle {
                id: field
                anchors.fill: parent
                radius: height / 2
                color: Qt.rgba(0.075, 0.071, 0.094, 0.92)
                border.width: 1
                border.color: pill.edge
                Behavior on border.color { ColorAnimation { duration: root.motion } }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 22
                    anchors.verticalCenter: parent.verticalCenter
                    text: ""   // nf-fa-lock
                    color: root.state_ === "fail" ? root.danger : password.activeFocus ? root.accent : root.muted
                    font.family: root.font
                    font.pixelSize: 15
                    renderType: Text.NativeRendering
                    Behavior on color { ColorAnimation { duration: root.motion } }
                }
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 52
                    anchors.verticalCenter: parent.verticalCenter
                    visible: password.text.length === 0
                    text: root.state_ === "fail" ? "wrong password, try again" : "password"
                    color: root.state_ === "fail" ? root.danger : root.muted
                    font.family: root.font
                    font.pixelSize: 15
                    renderType: Text.NativeRendering
                }
                TextInput {
                    id: password
                    anchors.fill: parent
                    anchors.leftMargin: 52
                    anchors.rightMargin: 52
                    verticalAlignment: TextInput.AlignVCenter
                    color: root.ink
                    selectionColor: root.accent
                    selectedTextColor: "#0d0c10"
                    font.family: root.font
                    font.pixelSize: 18
                    font.letterSpacing: 4
                    renderType: TextInput.NativeRendering
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    clip: true
                    focus: true
                    enabled: root.state_ !== "busy"
                    cursorDelegate: Rectangle {
                        width: 2; color: root.accent
                        visible: password.activeFocus
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite; running: password.activeFocus
                            NumberAnimation { to: 0.15; duration: 900; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1; duration: 900; easing.type: Easing.InOutSine }
                        }
                    }
                    onAccepted: root.doLogin()
                    onTextEdited: if (root.state_ === "fail") root.state_ = ""
                }
                // Enter: a round violet arrow, three pulsing dots while the session starts.
                Rectangle {
                    id: go
                    anchors.right: parent.right
                    anchors.rightMargin: 7
                    anchors.verticalCenter: parent.verticalCenter
                    width: 38; height: 38; radius: 19
                    color: password.text.length > 0 || root.state_ === "busy" ? root.accent : root.raised
                    Behavior on color { ColorAnimation { duration: root.motion } }
                    Text {
                        anchors.centerIn: parent
                        visible: root.state_ !== "busy"
                        text: ""   // nf-fa-arrow_right
                        color: password.text.length > 0 ? "#0d0c10" : root.muted
                        font.family: root.font
                        font.pixelSize: 15
                        renderType: Text.NativeRendering
                    }
                    Row {
                        anchors.centerIn: parent
                        visible: root.state_ === "busy"
                        spacing: 4
                        Repeater {
                            model: 3
                            Rectangle {
                                required property int index
                                width: 5; height: 5; radius: 2.5; color: "#0d0c10"
                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite; running: root.state_ === "busy"
                                    PauseAnimation { duration: index * 150 }
                                    NumberAnimation { to: 0.2; duration: 300 }
                                    NumberAnimation { to: 1; duration: 300 }
                                    PauseAnimation { duration: (2 - index) * 150 }
                                }
                            }
                        }
                    }
                    TapHandler { onTapped: root.doLogin() }
                }
            }
        }

        Item { width: 1; height: 18 }

        // A quiet line under the pill: the session starting, or a late-night nudge.
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.state_ === "busy" ? "starting " + root.sessionName + "…"
                : clock.now.getHours() < 5 ? "it's late. make it small, then sleep."
                : " "
            color: root.state_ === "busy" ? root.accent : root.amber
            font.family: root.font
            font.pixelSize: 13
            renderType: Text.NativeRendering
        }
    }

    // ---- Bottom: session pill on the left of the buttons, power on the right ----
    component Round: Rectangle {
        id: btn
        property string glyph
        property string tip
        property bool armed: false
        signal activated()
        width: 44; height: 44; radius: 22
        color: btnHover.hovered ? root.raised : Qt.rgba(0.075, 0.071, 0.094, 0.85)
        border.width: 1
        border.color: btn.armed ? root.danger : btnHover.hovered ? root.accent : root.line
        Behavior on color { ColorAnimation { duration: root.motion } }
        Behavior on border.color { ColorAnimation { duration: root.motion } }
        Text {
            anchors.centerIn: parent
            text: btn.glyph
            color: btn.armed ? root.danger : btnHover.hovered ? root.accent : root.ink
            font.family: root.font
            font.pixelSize: 17
            renderType: Text.NativeRendering
            Behavior on color { ColorAnimation { duration: root.motion } }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.top
            anchors.bottomMargin: 8
            text: btn.armed ? "again to " + btn.tip : btn.tip
            color: btn.armed ? root.danger : root.muted
            opacity: btnHover.hovered || btn.armed ? 1 : 0
            font.family: root.font
            font.pixelSize: 12
            renderType: Text.NativeRendering
            Behavior on opacity { NumberAnimation { duration: root.motion } }
        }
        HoverHandler { id: btnHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: btn.activated() }
    }

    // Reboot and power off need a second click within 4 s, like the shell's
    // session menu. F1/F2 stay instant for the keyboard.
    property string armed: ""
    Timer { id: disarm; interval: 4000; onTriggered: root.armed = "" }
    function confirm(name, action) {
        if (root.armed === name) { root.armed = ""; action() }
        else { root.armed = name; disarm.restart() }
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 40
        spacing: 12
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            height: 44
            width: sessRow.implicitWidth + 36
            radius: 22
            color: sessHover.hovered ? root.raised : Qt.rgba(0.075, 0.071, 0.094, 0.85)
            border.width: 1
            border.color: sessHover.hovered ? root.accent : root.line
            Behavior on color { ColorAnimation { duration: root.motion } }
            Behavior on border.color { ColorAnimation { duration: root.motion } }
            Row {
                id: sessRow
                anchors.centerIn: parent
                spacing: 10
                Text { text: ""; color: root.accent; font.family: root.font; font.pixelSize: 14; renderType: Text.NativeRendering; anchors.verticalCenter: parent.verticalCenter }
                Text { text: root.sessionName; color: root.ink; font.family: root.font; font.pixelSize: 14; renderType: Text.NativeRendering; anchors.verticalCenter: parent.verticalCenter }
                Text { visible: sessions.count > 1; text: "F3"; color: root.muted; font.family: root.font; font.pixelSize: 11; renderType: Text.NativeRendering; anchors.verticalCenter: parent.verticalCenter }
            }
            HoverHandler { id: sessHover; cursorShape: sessions.count > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor }
            TapHandler { onTapped: if (sessions.count > 0) root.sessionIndex = (root.sessionIndex + 1) % sessions.count }
        }
        Round { visible: sddm.canSuspend; glyph: ""; tip: "sleep"; onActivated: sddm.suspend() }          // nf-fa-moon_o
        Round { visible: sddm.canReboot; glyph: ""; tip: "reboot"; armed: root.armed === "reboot"; onActivated: root.confirm("reboot", () => sddm.reboot()) }
        Round { visible: sddm.canPowerOff; glyph: ""; tip: "power off"; armed: root.armed === "off"; onActivated: root.confirm("off", () => sddm.powerOff()) }
    }

    // Top right: the host, quiet, like the rail's corner.
    Text {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 40
        text: "\uf303  " + sddm.hostName   // nf-linux-archlinux
        color: root.muted
        font.family: root.font
        font.pixelSize: 13
        renderType: Text.NativeRendering
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_F1 && sddm.canPowerOff) { sddm.powerOff(); event.accepted = true }
        else if (event.key === Qt.Key_F2 && sddm.canReboot) { sddm.reboot(); event.accepted = true }
        else if (event.key === Qt.Key_F3 && sessions.count > 0) {
            root.sessionIndex = (root.sessionIndex + 1) % sessions.count; event.accepted = true
        }
        else if (event.key === Qt.Key_F4) { root.nextUser(); event.accepted = true }
    }

    Component.onCompleted: Qt.callLater(() => password.forceActiveFocus())
}
