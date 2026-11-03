"""Isolated shell-control and game-plan launch regressions. No GUI/power actions."""
import os
from pathlib import Path
import subprocess
import tempfile
import time
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
        # start detaches (setsid -f), so the stub may finish a moment later.
        for _ in range(50):
            if self.calls.exists() and self.calls.read_text().endswith('\n'):
                break
            time.sleep(0.05)
        self.assertEqual(self.calls.read_text().splitlines(), ['-c', 'afterhours', '--no-duplicate'])

    def test_panels_use_the_named_shell_ipc(self):
        self.stub('quickshell')
        for panel in ['apps', 'inbox', 'session']:
            with self.subTest(panel=panel):
                self.assertEqual(self.run_helper('afterhours', panel).returncode, 0)
                self.assertEqual(self.calls.read_text().splitlines(), ['ipc', '-c', 'afterhours', 'call', 'shell', 'toggle', panel])
        self.assertEqual(self.run_helper('afterhours', 'unknown').returncode, 2)

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
