import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Services.Mpris
// The lock screen, drawn by the shell: the haze, a big clock, the date,
// now playing, and one password field shared by every monitor.
// `afterhours lock` (and so loginctl lock-session, hypridle, the session
// menu) locks; hyprlock stays installed as the fallback when the shell
// isn't running. If the shell ever dies while locked, Hyprland keeps the
// screen locked; misc.allow_session_lock_restore lets hyprlock take over
// (see docs/desktop-rebuild.md).
Scope {
    id: lockRoot
    property alias locked: session.locked
    readonly property bool secure: session.secure
    property string typed: ""
    property string message: ""
    property bool checking: false
    property bool leaving: false
    property int shakes: 0
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? null

    function lock() {
        if (session.locked) return;
        typed = ""; message = ""; leaving = false; checking = false;
        session.locked = true;
    }
    function submit() {
        if (checking || typed.length === 0) return;
        checking = true;
        message = "";
        pam.start();
    }
    // logind's LockedHint: afterhours-suspend waits for it before suspending.
    function hint(on) {
        Quickshell.execDetached(["busctl", "call", "org.freedesktop.login1", "/org/freedesktop/login1/session/auto",
                                 "org.freedesktop.login1.Session", "SetLockedHint", "b", on ? "true" : "false"]);
    }
    onSecureChanged: if (secure) hint(true)

    PamContext {
        id: pam
        configDirectory: "pam"
        config: "password.conf"
        onResponseRequiredChanged: {
            if (!responseRequired) return;
            respond(lockRoot.typed);
            lockRoot.typed = "";
        }
        onCompleted: result => {
            lockRoot.checking = false;
            if (result === PamResult.Success) {
                lockRoot.leaving = true;
                away.start();
            } else {
                lockRoot.message = result === PamResult.MaxTries ? "Too many tries. Wait a moment." : "Wrong password";
                lockRoot.shakes++;
            }
        }
    }
    // Let the fade finish, then hand the screens back.
    Timer {
        id: away
        interval: Theme.glide + 120
        onTriggered: { session.locked = false; lockRoot.hint(false); lockRoot.leaving = false; }
    }

    WlSessionLock {
        id: session
        WlSessionLockSurface {
            id: surface
            color: Theme.background
            Image {
                anchors.fill: parent
                source: Quickshell.env("HOME") + "/.local/share/backgrounds/afterhours-haze.jpg"
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(surface.width, surface.height)
                scale: lockRoot.leaving ? 1.04 : 1
                Behavior on scale { NumberAnimation { duration: Theme.glide + 120; easing.type: Easing.OutCubic } }
            }
            Rectangle { anchors.fill: parent; color: Theme.background; opacity: lockRoot.leaving ? 0 : 0.45; Behavior on opacity { NumberAnimation { duration: Theme.glide } } }
            SystemClock { id: lockClock; precision: SystemClock.Seconds }
            Item {
                id: content
                anchors.fill: parent
                opacity: lockRoot.leaving ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: Theme.glide; easing.type: Easing.OutCubic } }
                // Comes up from slightly below each time the screen locks.
                Component.onCompleted: rise.start()
                transform: Translate { id: lift }
                NumberAnimation { id: rise; target: lift; property: "y"; from: 24; to: 0; duration: 600; easing.type: Easing.OutCubic }

                ColumnLayout {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -40
                    spacing: 6
                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        Text { text: Qt.formatDateTime(lockClock.date, "HH"); color: Theme.text; font.family: Theme.font; font.pixelSize: 128; font.bold: true }
                        Text {
                            text: ":"; color: Theme.accent; font.family: Theme.font; font.pixelSize: 128; font.bold: true
                            opacity: lockClock.date.getSeconds() % 2 === 0 ? 1 : 0.3
                            Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.InOutSine } }
                        }
                        Text { text: Qt.formatDateTime(lockClock.date, "mm"); color: Theme.text; font.family: Theme.font; font.pixelSize: 128; font.bold: true }
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatDateTime(lockClock.date, "dddd").toUpperCase() + "  ·  " + Qt.formatDateTime(lockClock.date, "d MMMM")
                        color: Theme.muted; font.family: Theme.font; font.pixelSize: 14; font.letterSpacing: 3
                    }
                    // The password field: one dot per character, a violet
                    // underline while it has focus, a shake on a wrong password.
                    Notch {
                        id: field
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 48
                        implicitWidth: 320; implicitHeight: 48
                        color: Theme.glass
                        edge: lockRoot.message ? Theme.danger : Theme.edge
                        Behavior on edge { ColorAnimation { duration: Theme.motion } }
                        // Between the cut bottom corners.
                        Rectangle {
                            anchors.bottom: parent.bottom
                            x: Theme.notch; width: parent.width - 2 * Theme.notch; height: 2
                            color: Theme.accent
                            opacity: input.activeFocus && !lockRoot.message ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Theme.motion } }
                        }
                        transform: Translate { id: shake }
                        Connections {
                            target: lockRoot
                            function onShakesChanged() { wobble.restart(); }
                        }
                        SequentialAnimation {
                            id: wobble
                            NumberAnimation { target: shake; property: "x"; to: -10; duration: 50 }
                            NumberAnimation { target: shake; property: "x"; to: 10; duration: 80 }
                            NumberAnimation { target: shake; property: "x"; to: -6; duration: 70 }
                            NumberAnimation { target: shake; property: "x"; to: 0; duration: 60 }
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: lockRoot.typed.length === 0
                            text: lockRoot.checking ? "checking…" : "password"
                            color: Theme.muted; font.family: Theme.font; font.pixelSize: 13
                        }
                        Row {
                            anchors.centerIn: parent
                            spacing: 8
                            Repeater {
                                model: Math.min(lockRoot.typed.length, 18)
                                Rectangle { width: 7; height: 7; rotation: 45; color: Theme.accent }   // a diamond per character
                            }
                        }
                        TextInput {
                            id: input
                            anchors.fill: parent
                            opacity: 0
                            focus: true
                            echoMode: TextInput.Password
                            enabled: !lockRoot.checking
                            text: lockRoot.typed
                            onTextEdited: { lockRoot.typed = text; lockRoot.message = ""; }
                            onAccepted: lockRoot.submit()
                            Keys.onEscapePressed: { lockRoot.typed = ""; text = ""; }
                            Component.onCompleted: forceActiveFocus()
                            // Disabled while PAM checks, which drops focus; take it back.
                            onEnabledChanged: if (enabled) forceActiveFocus()
                            // Every monitor shares one password; keep this field in step.
                            Connections { target: lockRoot; function onTypedChanged() { if (input.text !== lockRoot.typed) input.text = lockRoot.typed; } }
                        }
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: 18
                        text: lockRoot.message
                        color: Theme.danger; font.family: Theme.font; font.pixelSize: 12
                    }
                }
                // Now playing along the bottom, when something plays.
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom; anchors.bottomMargin: 48
                    spacing: 10
                    visible: lockRoot.player !== null
                    Text { text: ""; color: Theme.accent; font.family: Theme.font; font.pixelSize: 13 }
                    Text {
                        text: (lockRoot.player?.trackArtist ? lockRoot.player.trackArtist + " – " : "") + (lockRoot.player?.trackTitle ?? "")
                        color: Theme.muted; font.family: Theme.font; font.pixelSize: 13; textFormat: Text.PlainText
                        width: Math.min(implicitWidth, 600); elide: Text.ElideRight
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top; anchors.topMargin: 40
                    text: "AFTERHOURS  ·  " + (Quickshell.env("USER") ?? "")
                    color: Theme.muted; opacity: 0.7; font.family: Theme.font; font.pixelSize: 11; font.letterSpacing: 4
                }
            }
        }
    }
}
