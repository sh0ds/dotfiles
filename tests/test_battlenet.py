"""battlenet: install on the first start, launch after that. No Proton needed."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / '.local/bin/battlenet'
CLIENT = 'Games/battlenet/drive_c/Program Files (x86)/Battle.net/Battle.net Launcher.exe'


class Battlenet(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='battlenet-test-')
        self.home = Path(self.temp.name)
        fake = self.home / 'bin'
        fake.mkdir()
        self.log = self.home / 'calls'
        for name in ('umu-run', 'notify-send', 'app'):
            (fake / name).write_text(f'#!/bin/sh\necho "{name} $* | $WINEPREFIX $GAMEID $PROTONPATH" >> "{self.log}"\n')
            (fake / name).chmod(0o755)
        # curl writes a stand-in installer to --output.
        (fake / 'curl').write_text(f'#!/bin/sh\necho "curl $*" >> "{self.log}"\n'
                                   'while [ $# -gt 0 ]; do [ "$1" = --output ] && echo exe > "$2"; shift; done\n')
        (fake / 'curl').chmod(0o755)
        self.env = dict(os.environ, HOME=str(self.home), PATH=f'{fake}:{os.environ["PATH"]}')

    def tearDown(self):
        self.temp.cleanup()

    def run_script(self):
        result = subprocess.run(['bash', str(SCRIPT)], env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        return self.log.read_text().splitlines()

    def test_first_start_downloads_and_runs_the_installer(self):
        calls = self.run_script()
        self.assertTrue(any(c.startswith('curl ') and 'gameProgram=BATTLENET_APP' in c for c in calls), calls)
        setup = self.home / '.cache/battlenet/Battle.net-Setup.exe'
        self.assertTrue(setup.exists())
        prefix = self.home / 'Games/battlenet'
        self.assertIn(f'umu-run {setup} | {prefix} umu-battlenet GE-Proton', calls)

    def test_installed_launches_through_app(self):
        client = self.home / CLIENT
        client.parent.mkdir(parents=True)
        client.touch()
        calls = self.run_script()
        self.assertEqual(calls, [f'app ^steam_app_battlenet$ umu-run {client} | {self.home}/Games/battlenet umu-battlenet GE-Proton'])

    def test_unfinished_install_is_kept_aside(self):
        stale = self.home / 'Games/battlenet/drive_c'
        stale.mkdir(parents=True)
        self.run_script()
        kept = [p.name for p in (self.home / 'Games').iterdir() if p.name.startswith('battlenet.broken-')]
        self.assertEqual(len(kept), 1)
        self.assertTrue((self.home / 'Games' / kept[0] / 'drive_c').is_dir())
        self.assertFalse((self.home / 'Games/battlenet/drive_c').exists())


if __name__ == '__main__':
    unittest.main()
