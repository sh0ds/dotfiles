"""curseforge: picks up the downloaded AppImage, hands over the Forever folder once."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / '.local/bin/curseforge'


class Curseforge(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='curseforge-test-')
        self.home = Path(self.temp.name)
        fake = self.home / 'bin'
        fake.mkdir()
        self.log = self.home / 'calls'
        for name in ('app', 'notify-send', 'xdg-open', 'wl-copy'):
            (fake / name).write_text(f'#!/bin/sh\nprintf "{name} %s" "$*" >> "{self.log}"\n'
                                     f'[ {name} = wl-copy ] && printf " <%s>" "$(cat)" >> "{self.log}"\necho >> "{self.log}"\n')
            (fake / name).chmod(0o755)
        self.env = dict(os.environ, HOME=str(self.home), PATH=f'{fake}:{os.environ["PATH"]}')
        self.image = self.home / '.local/share/curseforge/CurseForge.AppImage'

    def tearDown(self):
        self.temp.cleanup()

    def run_script(self):
        result = subprocess.run(['bash', str(SCRIPT)], env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.log.read_text().splitlines()
        self.log.unlink()
        return calls

    def test_without_appimage_opens_the_download_page(self):
        calls = self.run_script()
        self.assertIn('xdg-open https://www.curseforge.com/download/app', calls)
        self.assertFalse(self.image.exists())

    def test_takes_the_download_and_tells_the_folder_once(self):
        downloads = self.home / 'Downloads'
        downloads.mkdir()
        (downloads / 'CurseForge-1.2.3.AppImage').write_text('x')
        forever = self.home / 'Games/battlenet/drive_c/Program Files (x86)/World of Warcraft/_forever_'
        forever.mkdir(parents=True)
        calls = self.run_script()
        self.assertTrue(os.access(self.image, os.X_OK))
        self.assertIn(f'wl-copy  <{forever}>', calls)
        self.assertIn(f'app (?i)^curseforge {self.image}', calls)
        calls = self.run_script()
        self.assertEqual(calls, [f'app (?i)^curseforge {self.image}'])


if __name__ == '__main__':
    unittest.main()
