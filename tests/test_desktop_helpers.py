"""Headless regressions: python3 -m unittest discover -s tests -v.

Uses isolated targets and command stubs; never installs into the real home,
starts a desktop, signals a recorder, or changes network/power state.
"""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET


REPO = Path(__file__).resolve().parents[1]


class Helpers(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="diag-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.env = dict(os.environ, PATH=f"{self.bin}:{os.environ['PATH']}")

    def stub(self, name, body):
        file = self.bin / name
        file.write_text("#!/usr/bin/env bash\n" + body + "\n")
        file.chmod(0o755)

    def run_helper(self, name, *args):
        return subprocess.run(
            ["bash", str(REPO / ".local/bin" / name), *args],
            env=self.env, text=True, capture_output=True, check=True, timeout=10,
        ).stdout

    def test_lock_metadata_is_literal_markup(self):
        self.stub("playerctl", 'printf "%s" "$PLAYER_METADATA"')
        self.env["PLAYER_METADATA"] = "A & B <live> - Title > edit"
        output = self.run_helper("np-title")
        self.assertEqual("".join(ET.fromstring(f"<root>{output}</root>").itertext()),
                         "play: A & B <live> - Title > edit\n")

    def test_long_lock_metadata_is_bounded(self):
        self.stub("playerctl", 'printf "%s" "$PLAYER_METADATA"')
        self.env["PLAYER_METADATA"] = "界" * 150
        output = self.run_helper("np-title")
        text = "".join(ET.fromstring(f"<root>{output}</root>").itertext())
        self.assertEqual(len(text.removeprefix("play: ").strip()), 90)
        self.assertTrue(text.endswith("…\n"))

    def test_installer_preserves_existing_files_and_is_repeatable(self):
        checkout = self.root / "checkout"
        checkout.mkdir()
        shutil.copy(REPO / "install-dotfiles.sh", checkout)
        shutil.copytree(REPO / ".config", checkout / ".config")
        shutil.copytree(REPO / ".local", checkout / ".local")
        subprocess.run(["git", "init", "-q", str(checkout)], check=True)
        subprocess.run(["git", "-C", str(checkout), "add", "."], check=True)
        target = self.root / "user & space"
        old = target / ".config/kitty/kitty.conf"
        old.parent.mkdir(parents=True)
        old.write_text("existing user config\n")
        # Retiring a helper removes only our own stale link, not an unrelated
        # dangling user link. This is how the Calendar launcher is retired.
        stale = target / ".local/bin/calendar"
        stale.parent.mkdir(parents=True)
        stale.symlink_to(checkout / ".local/bin/calendar")
        unrelated = target / ".local/bin/user-helper"
        unrelated.symlink_to(self.root / "external/missing")
        template = checkout / ".config/qt6ct/qt6ct.conf"
        before = template.read_bytes()
        command = ["bash", str(checkout / "install-dotfiles.sh"), "--target", str(target)]
        subprocess.run(command, check=True, capture_output=True, timeout=15)
        self.assertFalse(stale.is_symlink())
        self.assertTrue(unrelated.is_symlink())
        palette_config = target / ".config/qt6ct/qt6ct.conf"
        self.assertFalse(palette_config.is_symlink())
        self.assertIn(f"color_scheme_path={target}/.config/qt6ct/colors/diag.conf",
                      palette_config.read_text())
        backups = list((target / ".dotfiles-backup").iterdir())
        self.assertEqual(len(backups), 1)
        self.assertEqual((backups[0] / ".config/kitty/kitty.conf").read_text(),
                         "existing user config\n")
        subprocess.run(command, check=True, capture_output=True, timeout=15)
        self.assertEqual(len(list((target / ".dotfiles-backup").iterdir())), 1)
        self.assertTrue(old.is_symlink())
        self.assertEqual(template.read_bytes(), before)
        self.assertFalse((target / ".config/btop/btop.conf").is_symlink())
        self.assertEqual((target / ".config/btop/btop.conf").read_bytes(),
                         (checkout / ".config/btop/btop.conf").read_bytes())
        self.assertFalse((target / ".config/nchat/color.conf").is_symlink())


if __name__ == "__main__":
    unittest.main()
