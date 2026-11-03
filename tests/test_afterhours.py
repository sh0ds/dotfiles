"""Isolated shell-control and game-plan launch regressions. No GUI/power actions."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class Afterhours(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.calls = self.root / 'calls'
        self.env = dict(os.environ, HOME=str(self.root), PATH=f'{self.bin}:{os.environ["PATH"]}',
                        CALLS=str(self.calls), XDG_SESSION_ID='isolated-test')

    def stub(self, command, body='printf "%s\\n" "$@" > "$CALLS"'):
        path = self.bin / command
        path.write_text('#!/bin/bash\n' + body + '\n')
        path.chmod(0o755)

    def run_helper(self, name, *args):
        return subprocess.run(['bash', str(REPO / '.local/bin' / name), *args],
                              env=self.env, text=True, capture_output=True, timeout=10)

    def test_start_is_scoped_and_duplicate_safe(self):
        self.stub('quickshell')
        self.assertEqual(self.run_helper('afterhours', 'start').returncode, 0)
        self.assertEqual(self.calls.read_text().splitlines(), ['-c', 'afterhours', '--no-duplicate'])

    def test_panels_use_the_named_shell_ipc(self):
        self.stub('quickshell')
        for panel in ['studio', 'apps', 'inbox', 'session']:
            with self.subTest(panel=panel):
                self.assertEqual(self.run_helper('afterhours', panel).returncode, 0)
                self.assertEqual(self.calls.read_text().splitlines(), ['ipc', '-c', 'afterhours', 'call', 'shell', 'toggle', panel])
        self.assertEqual(self.run_helper('afterhours', 'unknown').returncode, 2)

    def test_studio_uses_quickshell(self):
        self.stub('afterhours')
        self.assertEqual(self.run_helper('game-dev').returncode, 0)
        self.assertEqual(self.calls.read_text().splitlines(), ['studio'])

    def test_code_directory_is_one_literal_argument(self):
        project = self.root / 'cart & source $(touch accidental)'
        project.mkdir()
        self.stub('zeditor')
        result = self.run_helper('game-dev', 'code', str(project))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls.read_text().splitlines(), ['--', str(project)])
        self.assertFalse((self.root / 'accidental').exists())
        self.assertNotEqual(self.run_helper('game-dev', 'code', str(project / 'absent')).returncode, 0)

    def test_plan_uses_explicit_checkout_without_writing_it(self):
        guides = self.root / 'my guides'
        plan = guides / 'gamedev/plan.md'
        plan.parent.mkdir(parents=True)
        plan.write_text('P1: change one Lua rule yourself.\n')
        self.env['GUIDES_DIR'] = str(guides)
        self.stub('kitty'); self.stub('less')
        self.assertEqual(self.run_helper('game-dev', 'plan').returncode, 0)
        self.assertEqual(self.calls.read_text().splitlines(), ['--title', 'Game plan', '-e', 'less', '--', str(plan)])
        self.assertEqual(plan.read_text(), 'P1: change one Lua rule yourself.\n')

    def test_art_and_audio_follow_the_plan(self):
        self.stub('pixelorama'); self.stub('aseprite', 'exit 7')
        self.assertEqual(self.run_helper('game-dev', 'art').returncode, 0)
        self.stub('pico8')
        self.assertEqual(self.run_helper('game-dev', 'audio').returncode, 0)
        self.stub('my-daw')
        self.env['GAME_DAW'] = 'my-daw'
        self.assertEqual(self.run_helper('game-dev', 'audio').returncode, 0)

    def test_suspend_waits_for_logind_lock(self):
        self.stub('pgrep', 'exit 0')
        self.stub('loginctl', 'echo yes')
        self.stub('systemctl')
        self.assertEqual(self.run_helper('afterhours-suspend').returncode, 0)
        self.assertEqual(self.calls.read_text().splitlines(), ['suspend'])

    def test_failed_lock_never_suspends(self):
        self.stub('pgrep', 'exit 0')
        self.stub('loginctl', 'echo no')
        self.stub('systemctl')
        self.stub('sleep', 'exit 0')
        self.stub('notify-send', 'exit 0')
        self.assertEqual(self.run_helper('afterhours-suspend').returncode, 1)
        self.assertFalse(self.calls.exists())


if __name__ == '__main__':
    unittest.main()
