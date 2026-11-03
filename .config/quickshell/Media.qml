// The playing MPRIS player (or the first one): "play  artist / title" with
// play in blue, "hold" in grey when paused. Click pauses, scroll skips.
import QtQuick
import Quickshell.Services.Mpris

Cell {
	id: media
	readonly property MprisPlayer player:
		Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

	function cut(s, n) {
		s = s || "";
		return s.length > n ? s.slice(0, n - 1) + "…" : s;
	}

	visible: player !== null
	pad: 12
	textColor: player?.isPlaying ? Theme.fg : Theme.mid
	text: !player ? "" :
		(player.isPlaying ? `<font color='${Theme.arch}'>play</font>` : `<font color='${Theme.mid}'>hold</font>`)
		+ "  " + Theme.esc(cut(player.trackArtist, 10)) + " / " + Theme.esc(cut(player.trackTitle, 20))
	tip: player ? `${player.trackArtist} / ${player.trackTitle}` : ""
	onClicked: player?.togglePlaying()
	onScrolled: d => d > 0 ? player?.next() : player?.previous()
}
