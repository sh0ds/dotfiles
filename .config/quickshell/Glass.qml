// A rounded glass panel: the panel colour at 82 % with a faint edge. Hyprland
// blurs whatever is behind it (rice.lua, layer rule "glass").
import QtQuick

Rectangle {
	color: Theme.glass
	radius: Theme.radius
	border.color: Theme.edge
	border.width: 1
}
