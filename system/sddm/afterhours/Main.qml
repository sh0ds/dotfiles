// Afterhours login screen. The same picture as the lock screen
// (hyprlock.conf): the desktop wallpaper, a large clock with the date under
// it, and one notched password field. Your name sits above it as a chip; F3
// or the session block switches session, the square buttons bottom right
// suspend, reboot and power off. Only QtQuick, no Controls, so nothing gets
// styled behind our back. Qt 6 (metadata.desktop says QtVersion=6).
import QtQuick
import QtQuick.Shapes

Rectangle {
    id: root
    color: "#0d0c10"

    // The shell's Notch (afterhours/Notch.qml), copied here because the
    // greeter can't read your config: corners cut at 45 degrees instead of
    // rounded.
    component Cut: Item {
        id: cutBox
        property color color: "transparent"
        property color edge: "transparent"
        property real cut: 8
        property bool cutTopLeft: true
        property bool cutTopRight: true
        property bool cutBottomRight: true
        property bool cutBottomLeft: true
        readonly property real cutSize: Math.max(0, Math.min(cut, width / 2, height / 2))
        readonly property real tl: cutTopLeft ? cutSize : 0
        readonly property real tr: cutTopRight ? cutSize : 0
        readonly property real br: cutBottomRight ? cutSize : 0
        readonly property real bl: cutBottomLeft ? cutSize : 0
        readonly property real x0: 0.5
        readonly property real y0: 0.5
        readonly property real x1: width - 0.5
        readonly property real y1: height - 0.5
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: cutBox.color
                strokeColor: cutBox.edge
                strokeWidth: cutBox.edge.a > 0 ? 1 : -1
                joinStyle: ShapePath.MiterJoin
                PathSvg {
                    path: "M" + (cutBox.x0 + cutBox.tl) + "," + cutBox.y0
                        + " L" + (cutBox.x1 - cutBox.tr) + "," + cutBox.y0 + " L" + cutBox.x1 + "," + (cutBox.y0 + cutBox.tr)
                        + " L" + cutBox.x1 + "," + (cutBox.y1 - cutBox.br) + " L" + (cutBox.x1 - cutBox.br) + "," + cutBox.y1
                        + " L" + (cutBox.x0 + cutBox.bl) + "," + cutBox.y1 + " L" + cutBox.x0 + "," + (cutBox.y1 - cutBox.bl)
                        + " L" + cutBox.x0 + "," + (cutBox.y0 + cutBox.tl) + " Z"
                }
            }
        }
    }

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
    // It loads in the background and fades in over the charcoal, so the
    // screen never shows a half-drawn first picture.
    Image {
        id: wall
        anchors.fill: parent
        source: "background.jpg"
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
        opacity: 0
        onStatusChanged: if (status !== Image.Loading) intro.start()
    }

    // ---- Opening: the boot splash ends on its mark alone over charcoal,
    // so the login starts as that same picture (same pixels: the mark's
    // bottom edge sits 24 px above the middle) and opens out of it. The
    // wallpaper comes up, the mark lets go, then the clock and the field
    // rise in and the corners follow.
    property real chrome: 0
    Image {
        id: mark
        source: "logo.png"
        x: Math.round((root.width - width) / 2)
        y: Math.round(root.height / 2 - height - 24)
        smooth: false
    }
    ParallelAnimation {
        id: intro
        NumberAnimation { target: wall; property: "opacity"; to: 1; duration: 900; easing.type: Easing.OutCubic }
        SequentialAnimation {
            PauseAnimation { duration: 150 }
            NumberAnimation { target: mark; property: "opacity"; to: 0; duration: 450; easing.type: Easing.OutCubic }
        }
        SequentialAnimation {
            PauseAnimation { duration: 350 }
            ParallelAnimation {
                NumberAnimation { target: centre; property: "opacity"; to: 1; duration: 600; easing.type: Easing.OutCubic }
                NumberAnimation { target: centre; property: "rise"; to: 0; duration: 700; easing.type: Easing.OutCubic }
            }
        }
        SequentialAnimation {
            PauseAnimation { duration: 600 }
            NumberAnimation { target: root; property: "chrome"; to: 1; duration: 500; easing.type: Easing.OutCubic }
        }
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
        // Fades in and rises a little, like a window opening (see Opening).

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

        // Who: a square initial in violet and the name. Click (or F4) for
        // the next user when there is more than one.
        Cut {
            id: who
            anchors.horizontalCenter: parent.horizontalCenter
            height: 40
            width: whoRow.implicitWidth + 12 + 20
            cutTopRight: false; cutBottomLeft: false
            color: whoHover.hovered && root.userNames.length > 1 ? root.raised : Qt.rgba(0.075, 0.071, 0.094, 0.85)
            edge: root.line
            Behavior on color { ColorAnimation { duration: root.motion } }
            Row {
                id: whoRow
                x: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12
                Cut {
                    width: 28; height: 28
                    cut: 4; cutTopRight: false; cutBottomLeft: false
                    color: root.accentSoft
                    edge: root.line
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

        // The password field: a soft violet halo while it has focus,
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
            readonly property color edge: root.state_ === "fail" ? root.danger : root.line

            Cut {
                anchors.fill: field
                anchors.margins: -5
                cut: 11
                color: pill.edge
                opacity: root.state_ === "fail" ? 0.16 : 0
                Behavior on opacity { NumberAnimation { duration: root.motion } }
                Behavior on color { ColorAnimation { duration: root.motion } }
            }
            Cut {
                id: field
                anchors.fill: parent
                color: Qt.rgba(0.075, 0.071, 0.094, 0.92)
                edge: pill.edge
                Behavior on edge { ColorAnimation { duration: root.motion } }
                // Focus: a violet underline between the cut bottom corners.
                Rectangle {
                    anchors.bottom: parent.bottom
                    x: field.cutSize; width: parent.width - 2 * field.cutSize; height: 2
                    color: root.accent
                    opacity: password.activeFocus && root.state_ !== "fail" ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: root.motion } }
                }

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
                // Enter: a square violet arrow, three pulsing dots while the session starts.
                Cut {
                    id: go
                    anchors.right: parent.right
                    anchors.rightMargin: 7
                    anchors.verticalCenter: parent.verticalCenter
                    width: 38; height: 38
                    cut: 4; cutTopRight: false; cutBottomLeft: false
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
                                width: 5; height: 5; rotation: 45; color: "#0d0c10"
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

        // A quiet line under the field: the session starting, or a late-night nudge.
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

    // ---- Bottom: session block on the left of the buttons, power on the right ----
    component PowerButton: Cut {
        id: btn
        // Bottom right, so cut like the shell's right piece.
        cutTopLeft: false; cutBottomRight: false
        property string glyph
        property string tip
        property bool armed: false
        signal activated()
        width: 44; height: 44
        color: btnHover.hovered ? root.raised : Qt.rgba(0.075, 0.071, 0.094, 0.85)
        edge: btn.armed ? root.danger : root.line
        Behavior on color { ColorAnimation { duration: root.motion } }
        Behavior on edge { ColorAnimation { duration: root.motion } }
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
        opacity: root.chrome
        Cut {
            anchors.verticalCenter: parent.verticalCenter
            height: 44
            width: sessRow.implicitWidth + 36
            cutTopLeft: false; cutBottomRight: false
            color: sessHover.hovered ? root.raised : Qt.rgba(0.075, 0.071, 0.094, 0.85)
            edge: root.line
            Behavior on color { ColorAnimation { duration: root.motion } }
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
        PowerButton { visible: sddm.canSuspend; glyph: ""; tip: "sleep"; onActivated: sddm.suspend() }          // nf-fa-moon_o
        PowerButton { visible: sddm.canReboot; glyph: ""; tip: "reboot"; armed: root.armed === "reboot"; onActivated: root.confirm("reboot", () => sddm.reboot()) }
        PowerButton { visible: sddm.canPowerOff; glyph: ""; tip: "power off"; armed: root.armed === "off"; onActivated: root.confirm("off", () => sddm.powerOff()) }
    }

    // Top right: the host, quiet, like the rail's corner.
    Text {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 40
        text: "\uf303  " + sddm.hostName   // nf-linux-archlinux
        color: root.muted
        opacity: root.chrome
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
