"""cleanup: shows a plan, removes only caches and leftovers, never without a yes."""
import os
from pathlib import Path
import subprocess
import tempfile
import time
import unittest

REPO = Path(__file__).resolve().parents[1]
SCRIPT = REPO / '.local/bin/cleanup'
OLD = time.time() - 40 * 86400


class Cleanup(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='cleanup-test-')
        self.home = Path(self.temp.name)
        fake = self.home / 'bin'
        fake.mkdir()
        self.log = self.home / 'calls'
        stubs = {
            'pacman': '[ "$1" = -Qdtq ] && printf "libfoo\\nlibbar\\n"\n'
                      'if [ "$1" = -Qq ]; then case $2 in waybar|neovim|tmux) exit 0 ;; *) exit 1 ;; esac; fi\n'
                      # tmux is still needed by something else
                      'case "$*" in "-Rns --noconfirm -- tmux") exit 1 ;; esac',
            'gio': '[ "$1" = trash ] && mv -- "$3" "$HOME/.local/share/Trash/files/"',
            'paccache': 'echo "==> finished: 3 packages removed (disk space saved: 120 MiB)"',
            'journalctl': 'echo "Archived and active journals take up 1.2G in the file system."',
            'sudo': '"$@"',
            'pacdiff': 'true',
            'systemctl': 'true',
        }
        for name, body in stubs.items():
            (fake / name).write_text(f'#!/bin/sh\necho "{name} $*" >> "{self.log}"\n{body}\n')
            (fake / name).chmod(0o755)
        self.env = dict(os.environ, HOME=str(self.home), PATH=f'{fake}:{os.environ["PATH"]}')
        self.env.pop('XDG_CACHE_HOME', None)
        self.env.pop('XDG_DATA_HOME', None)

        def make(rel, old=False):
            path = self.home / rel
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('x')
            if old:
                os.utime(path, (OLD, OLD))
            return path

        self.old_thumb = make('.cache/thumbnails/large/old.png', old=True)
        self.new_thumb = make('.cache/thumbnails/large/new.png')
        self.yay_src = make('.cache/yay/quickshell-git/src/main.cpp')
        self.yay_pkg = make('.cache/yay/quickshell-git/quickshell-git-1-1-x86_64.pkg.tar.zst')
        self.yay_build = make('.cache/yay/quickshell-git/PKGBUILD')
        self.pip = make('.cache/pip/http/a')
        self.clip = make('.cache/cliphist/db', old=True)
        self.shader = make('.cache/nvidia/GLCache/x', old=True)
        self.old_trash = make('.local/share/Trash/files/old.txt', old=True)
        self.old_info = make('.local/share/Trash/info/old.txt.trashinfo', old=True)
        self.new_trash = make('.local/share/Trash/files/new.txt')
        self.new_info = make('.local/share/Trash/info/new.txt.trashinfo')
        self.download = make('Downloads/keep.zip', old=True)
        self.nvim = make('.config/nvim/init.lua')
        self.waybar = make('.config/waybar/config')
        self.kitty = make('.config/kitty/kitty.conf')
        self.old_backup = make('.dotfiles-backup/20261001-120000.aaaaaa/.bashrc')
        os.utime(self.old_backup.parent, (OLD, OLD))
        self.new_backup = make('.dotfiles-backup/20261110-120000.bbbbbb/.bashrc')

    def tearDown(self):
        self.temp.cleanup()

    def run_script(self, *args, stdin=''):
        result = subprocess.run(['bash', str(SCRIPT), *args], env=self.env, input=stdin, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.log.read_text().splitlines() if self.log.exists() else []
        return result.stdout, calls

    def assert_untouched(self):
        for path in (self.old_thumb, self.yay_src, self.yay_pkg, self.pip, self.old_trash, self.old_info,
                     self.nvim, self.waybar, self.old_backup):
            self.assertTrue(path.exists(), path)

    def test_dry_run_shows_the_plan_and_removes_nothing(self):
        out, calls = self.run_script('--dry')
        self.assertIn('2: libfoo libbar', out)
        self.assertIn('120 MiB', out)
        self.assertIn('1.2G now', out)
        self.assertIn('Nothing removed', out)
        self.assertIn('waybar neovim tmux', out)
        self.assertIn('~/.config/nvim', out)
        self.assertIn('~/.dotfiles-backup/20261001-120000.aaaaaa', out)
        self.assertNotIn('20261110', out)
        self.assert_untouched()
        self.assertFalse([c for c in calls if c.startswith('sudo') or '-Rns' in c or ' -r' in c or c.startswith('gio')])

    def test_no_answer_means_no(self):
        out, calls = self.run_script(stdin='\n\n')
        self.assertIn('Left as it is', out)
        self.assertIn('Left as they are', out)
        self.assert_untouched()
        self.assertFalse([c for c in calls if c.startswith('sudo') or c.startswith('gio')])

    def test_yes_removes_leftovers_and_keeps_the_rest(self):
        out, calls = self.run_script(stdin='y\nn\n')
        self.assertIn('pacman -Rns --noconfirm -- libfoo libbar', calls)
        self.assertNotIn('pacman -Rns --noconfirm -- waybar', calls)
        for kept in (self.nvim, self.waybar, self.old_backup):
            self.assertTrue(kept.exists(), kept)
        self.assertIn('paccache -rk2', calls)
        self.assertIn('paccache -ruk0', calls)
        self.assertIn('journalctl --vacuum-time=2weeks', calls)
        for gone in (self.old_thumb, self.yay_src, self.yay_pkg, self.pip, self.old_trash, self.old_info):
            self.assertFalse(gone.exists(), gone)
        for kept in (self.new_thumb, self.yay_build, self.clip, self.shader, self.new_trash, self.new_info, self.download):
            self.assertTrue(kept.exists(), kept)
        self.assertIn('~/Downloads', out)

    def test_replaced_apps_are_their_own_question(self):
        out, calls = self.run_script(stdin='n\ny\n')
        self.assertNotIn('paccache -rk2', calls)
        self.assertTrue(self.old_thumb.exists())
        self.assertIn('pacman -Rns --noconfirm -- waybar', calls)
        self.assertIn('pacman -Rns --noconfirm -- neovim', calls)
        self.assertIn('waybar uninstalled', out)
        self.assertIn('tmux kept', out)
        trash = self.home / '.local/share/Trash/files'
        for name in ('nvim', 'waybar', '20261001-120000.aaaaaa'):
            self.assertTrue((trash / name).exists(), name)
        self.assertFalse(self.nvim.exists())
        self.assertFalse(self.old_backup.exists())
        for kept in (self.kitty, self.new_backup, self.download):
            self.assertTrue(kept.exists(), kept)

    def test_yes_flag_skips_the_question(self):
        _, calls = self.run_script('--yes')
        self.assertIn('paccache -rk2', calls)
        self.assertFalse(self.old_thumb.exists())
        self.assertIn('pacman -Rns --noconfirm -- waybar', calls)
        self.assertFalse(self.nvim.exists())

    def test_unknown_argument_prints_usage(self):
        result = subprocess.run(['bash', str(SCRIPT), '--all'], env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 2)
        self.assertIn('cleanup --dry', result.stdout)
        self.assert_untouched()


if __name__ == '__main__':
    unittest.main()
