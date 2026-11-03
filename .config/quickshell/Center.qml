// The notification centre, replacing swaync's panel: a glass column on the
// right with quiet (do-not-disturb), eight quick buttons, the player, the
// volume and every notification still around. SUPER+N, the msg cell, Esc or
// a click anywhere else closes it.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.Notifications

PanelWindow {
	id: center
	screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
	anchors { top: true; right: true; bottom: true }
	margins { top: 6; right: 10; bottom: 10 }
	exclusiveZone: 0
	implicitWidth: 400
	color: "transparent"
	visible: Notes.centerOpen
	WlrLayershell.namespace: "diag-center"
	WlrLayershell.layer: WlrLayer.Overlay
	WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

	readonly property PwNode sink: Pipewire.defaultAudioSink
	readonly property MprisPlayer player:
		Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
	property bool night: false

	function run(cmd) {
		Notes.centerOpen = false;
		Quickshell.execDetached(["sh", "-c", cmd]);
	}

	PwObjectTracker { objects: center.sink ? [center.sink] : [] }
	HyprlandFocusGrab {
		windows: [center]
		active: center.visible
		onCleared: Notes.centerOpen = false
	}
	Process {
		id: nightCheck
		command: ["pgrep", "-x", "hyprsunset"]
		onExited: code => center.night = code === 0
	}
	onVisibleChanged: if (visible) { nightCheck.running = true; body.forceActiveFocus(); }
	Timer { id: recheck; interval: 400; onTriggered: nightCheck.running = true }

	Glass {
		id: body
		anchors.fill: parent
		radius: 14
		focus: true
		Keys.onEscapePressed: Notes.centerOpen = false

		Column {
			id: head
			anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
			spacing: 14

			// notifications: 3                                   clear
			Item {
				width: parent.width
				height: 34
				Text {
					anchors.verticalCenter: parent.verticalCenter
					text: `notifications: <font color='${Theme.mid}'>${Notes.count}</font>`
					textFormat: Text.StyledText
					color: Theme.ink
					font.family: Theme.font
					font.pixelSize: 20
					font.bold: true
					font.hintingPreference: Font.PreferFullHinting
				}
				Pill {
					anchors { right: parent.right; verticalCenter: parent.verticalCenter }
					text: "clear"
					visible: Notes.count > 0
					onClicked: Notes.clearAll()
				}
			}

			// quiet:                                              [ o]
			Item {
				width: parent.width
				height: 28
				Text {
					anchors.verticalCenter: parent.verticalCenter
					text: "quiet:"
					color: Theme.fg
					font.family: Theme.font
					font.pixelSize: Theme.size
					font.hintingPreference: Font.PreferFullHinting
				}
				Rectangle {
					id: sw
					anchors { right: parent.right; verticalCenter: parent.verticalCenter }
					width: 46; height: 24; radius: 12
					color: Notes.quiet ? Theme.arch : "#26ffffff"
					Behavior on color { ColorAnimation { duration: Theme.ease } }
					Rectangle {
						y: 3; width: 18; height: 18; radius: 9
						x: Notes.quiet ? sw.width - width - 3 : 3
						color: Notes.quiet ? "#000000" : Theme.fg
						Behavior on x { NumberAnimation { duration: Theme.ease; easing.type: Easing.OutCubic } }
					}
					MouseArea { anchors.fill: parent; onClicked: Notes.setQuiet(!Notes.quiet) }
				}
			}

			Grid {
				id: grid
				width: parent.width
				columns: 4
				spacing: 6
				readonly property real cell: (width - 3 * spacing) / 4
				Pill { width: grid.cell; text: "wifi"; onClicked: center.run("wifi") }
				Pill { width: grid.cell; text: "night"; on: center.night
					onClicked: { Quickshell.execDetached(["nightlight"]); recheck.restart(); } }
				Pill { width: grid.cell; text: "capture"
					onClicked: center.run("sleep 0.4; grim -g \"$(slurp)\" - | satty --filename - --copy-command wl-copy") }
				Pill { width: grid.cell; text: "record"; onClicked: center.run("rec-toggle") }
				Pill { width: grid.cell; text: "calc"; onClicked: center.run("calc") }
				Pill { width: grid.cell; text: "term"; onClicked: center.run("kitty") }
				Pill { width: grid.cell; text: "lock"; onClicked: center.run("loginctl lock-session") }
				Pill { width: grid.cell; text: "halt"; onClicked: center.run("power-menu") }
			}

			// The player: art, title, artist and three round buttons.
			Rectangle {
				width: parent.width
				height: 64
				radius: 10
				visible: center.player !== null
				color: "#0fffffff"
				border.width: 1
				border.color: Theme.edge
				Row {
					anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 12 }
					spacing: 12
					ClippingRectangle {
						width: 40; height: 40; radius: 6
						visible: (center.player?.trackArtUrl ?? "") !== ""
						color: Theme.row
						Image { anchors.fill: parent; source: center.player?.trackArtUrl ?? ""; fillMode: Image.PreserveAspectCrop; asynchronous: true }
					}
					Column {
						anchors.verticalCenter: parent.verticalCenter
						width: 200
						Text {
							width: parent.width
							elide: Text.ElideRight
							text: center.player?.trackTitle ?? ""
							color: Theme.ink
							font.family: Theme.font
							font.pixelSize: Theme.size
							font.bold: true
							font.hintingPreference: Font.PreferFullHinting
						}
						Text {
							width: parent.width
							elide: Text.ElideRight
							text: center.player?.trackArtist ?? ""
							color: Theme.mid
							font.family: Theme.font
							font.pixelSize: 16
							font.hintingPreference: Font.PreferFullHinting
						}
					}
				}
				Row {
					anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 12 }
					spacing: 4
					Repeater {
						model: [
							{ glyph: "󰒮", go: () => center.player?.previous() },
							{ glyph: center.player?.isPlaying ? "󰏤" : "󰐊", go: () => center.player?.togglePlaying() },
							{ glyph: "󰒭", go: () => center.player?.next() }
						]
						Rectangle {
							required property var modelData
							width: 30; height: 30; radius: 15
							color: btn.containsMouse ? Theme.arch : "transparent"
							Behavior on color { ColorAnimation { duration: Theme.ease } }
							Text {
								anchors.centerIn: parent
								text: modelData.glyph
								color: btn.containsMouse ? "#000000" : Theme.fg
								font.family: Theme.font
								font.pixelSize: 18
							}
							MouseArea { id: btn; anchors.fill: parent; hoverEnabled: true; onClicked: modelData.go() }
						}
					}
				}
			}

			// vol: ━━━━━━━━━━━○──────  42%
			Item {
				width: parent.width
				height: 28
				visible: center.sink !== null
				Text {
					id: volLabel
					anchors.verticalCenter: parent.verticalCenter
					text: "vol:"
					color: Theme.arch
					font.family: Theme.font
					font.pixelSize: Theme.size
					font.hintingPreference: Font.PreferFullHinting
				}
				Text {
					id: volValue
					anchors { right: parent.right; verticalCenter: parent.verticalCenter }
					width: 44
					horizontalAlignment: Text.AlignRight
					text: center.sink?.audio?.muted ? "mute" : Math.round((center.sink?.audio?.volume ?? 0) * 100) + "%"
					color: Theme.fg
					font.family: Theme.font
					font.pixelSize: 16
					font.hintingPreference: Font.PreferFullHinting
				}
				Rectangle {
					id: trough
					anchors { left: volLabel.right; leftMargin: 12; right: volValue.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
					height: 8; radius: 4
					color: "#1affffff"
					readonly property real level: Math.min(1, center.sink?.audio?.volume ?? 0)
					Rectangle {
						width: trough.width * trough.level
						height: parent.height; radius: 4
						gradient: Gradient {
							orientation: Gradient.Horizontal
							GradientStop { position: 0; color: Theme.arch }
							GradientStop { position: 1; color: Theme.sky }
						}
					}
					Rectangle {
						x: trough.width * trough.level - width / 2
						anchors.verticalCenter: parent.verticalCenter
						width: 16; height: 16; radius: 8
						color: Theme.ink
					}
					MouseArea {
						anchors { fill: parent; topMargin: -10; bottomMargin: -10 }
						function set(mx) { if (center.sink) center.sink.audio.volume = Math.max(0, Math.min(1, mx / trough.width)); }
						onPressed: e => set(e.x)
						onPositionChanged: e => set(e.x)
						onWheel: e => set(trough.width * (trough.level + (e.angleDelta.y > 0 ? 0.05 : -0.05)))
					}
				}
			}
		}

		ListView {
			id: listView
			anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: parent.bottom; margins: 16; topMargin: 18 }
			clip: true
			spacing: 8
			model: [...Notes.list].reverse()
			delegate: NoteCard {
				required property Notification modelData
				note: modelData
				solid: false
				width: listView.width
			}
			add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.ease } }
			displaced: Transition { NumberAnimation { property: "y"; duration: Theme.glide; easing.type: Easing.OutCubic } }
			Text {
				anchors.centerIn: parent
				visible: Notes.count === 0
				text: "nothing new"
				color: Theme.mid
				font.family: Theme.font
				font.pixelSize: Theme.size
				font.hintingPreference: Font.PreferFullHinting
			}
		}
	}
}
