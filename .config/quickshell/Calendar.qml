// Month calendar under the clock: week numbers on the left, Monday first,
// today in blue. Scroll changes the month, click on it closes it.
import QtQuick
import Quickshell

PopupWindow {
	id: cal
	required property Item target
	required property date today
	property int shift: 0

	anchor.item: target
	anchor.edges: Edges.Bottom
	anchor.gravity: Edges.Bottom
	visible: false
	onVisibleChanged: shift = 0
	color: "transparent"
	implicitWidth: grid.implicitWidth + 28
	implicitHeight: grid.implicitHeight + 24

	function isoWeek(d) {
		const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
		const day = t.getUTCDay() || 7;
		t.setUTCDate(t.getUTCDate() + 4 - day);
		const y0 = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
		return Math.ceil(((t - y0) / 86400000 + 1) / 7);
	}
	function cell(s, w) { return String(s).padStart(w).replace(/ /g, "&nbsp;"); }
	function render() {
		const first = new Date(today.getFullYear(), today.getMonth() + shift, 1);
		const days = new Date(first.getFullYear(), first.getMonth() + 1, 0).getDate();
		const lead = (first.getDay() + 6) % 7;
		const isMonth = shift === 0;
		let out = `<font color='#f4f6f8'><b>${Qt.formatDate(first, "MMMM yyyy")}</b></font><br>`;
		out += `<font color='${Theme.mid}'>${cell("", 3)} Mo Tu We Th Fr Sa Su</font><br>`;
		let d = 1 - lead;
		while (d <= days) {
			const monday = new Date(first.getFullYear(), first.getMonth(), Math.max(d, 1));
			let line = `<font color='${Theme.mid}'>${cell("W" + isoWeek(monday), 3)}</font>`;
			for (let i = 0; i < 7; i++, d++) {
				if (d < 1 || d > days) { line += cell("", 3); continue; }
				line += "&nbsp;" + (isMonth && d === today.getDate()
					? `<font color='${Theme.arch}'><b><u>${cell(d, 2)}</u></b></font>`
					: `<font color='${Theme.fg}'>${cell(d, 2)}</font>`);
			}
			out += line + "<br>";
		}
		return out;
	}

	Rectangle {
		anchors.fill: parent
		color: Theme.panel
		border.color: Theme.rule
		border.width: 1
		Rectangle {
			anchors { left: parent.left; right: parent.right; top: parent.top }
			height: 2
			color: Theme.arch
		}
		Text {
			id: grid
			anchors.centerIn: parent
			text: cal.render()
			textFormat: Text.StyledText
			font.family: Theme.font
			font.pixelSize: 16
			font.hintingPreference: Font.PreferFullHinting
		}
		MouseArea {
			anchors.fill: parent
			onClicked: cal.visible = false
			onWheel: e => cal.shift += e.angleDelta.y > 0 ? -1 : 1
		}
	}
}
