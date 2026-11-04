"""gba / roms: launcher entries for Game Boy games and starting them. No mGBA needed."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
BIN = REPO / '.local/bin'


class Roms(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='gba-test-')
        self.home = Path(self.temp.name)
        self.games = self.home / 'games/roms/gba'
        self.games.mkdir(parents=True)
        fake = self.home / 'bin'
        fake.mkdir()
        for name in ('mgba-qt', 'notify-send', 'app'):
            (fake / name).write_text(f'#!/bin/sh\necho {name} "$@"\n')
            (fake / name).chmod(0o755)
        self.env = dict(os.environ, HOME=str(self.home), PATH=f'{fake}:{os.environ["PATH"]}')
        self.env.pop('XDG_DATA_HOME', None)
        self.apps = self.home / '.local/share/applications'

    def tearDown(self):
        self.temp.cleanup()

    def run_script(self, *args):
        return subprocess.run(['bash', str(BIN / args[0]), *args[1:]], env=self.env, capture_output=True, text=True)

    def entries(self):
        return {p.name: p.read_text() for p in self.apps.glob('rom-*.desktop')}

    def test_one_entry_per_game_without_region_tags(self):
        (self.games / "Legend of Zelda, The - Link's Awakening DX (USA, Europe) (Rev 2).gbc").touch()
        (self.games / 'Minish Cap (Europe) (En,Fr,De,Es,It).gba').touch()
        (self.games / 'notes.txt').touch()
        self.run_script('roms')
        texts = list(self.entries().values())
        self.assertEqual(len(texts), 2)
        self.assertTrue(any("Name=Legend of Zelda, The - Link's Awakening DX\n" in t and 'Game Boy Color' in t for t in texts))
        self.assertTrue(any('Name=Minish Cap\n' in t and 'Game Boy Advance' in t for t in texts))

    def test_removed_games_lose_their_entry(self):
        rom = self.games / 'Gone.gb'
        rom.touch()
        self.run_script('roms')
        rom.unlink()
        self.run_script('roms')
        self.assertEqual(self.entries(), {})

    def test_entry_starts_its_game_fullscreen(self):
        rom = self.games / 'It\'s "odd" $HOME 100%.gba'
        rom.touch()
        self.run_script('roms')
        exec_line = next(l for l in next(iter(self.entries().values())).splitlines() if l.startswith('Exec='))
        out = self.run_script('gba', *exec_line.split()[1:]).stdout
        self.assertIn('mgba-qt', out)
        self.assertIn('lockIntegerScaling=1', out)
        self.assertTrue(out.rstrip().endswith(f'-f {rom}'))

    def test_unknown_game_says_so(self):
        result = self.run_script('gba', '--game', 'ffffffffffff')
        self.assertEqual(result.returncode, 1)
        self.assertIn('Game not found', result.stdout)


if __name__ == '__main__':
    unittest.main()
