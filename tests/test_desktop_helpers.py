"""Headless regressions: python3 -m unittest discover -s tests -v.

Uses isolated targets and command stubs; never installs into the real home,
starts a desktop, signals a recorder, or changes network/power state.
"""
import json
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

    def power_args(self, monitors):
        self.stub("hyprctl", 'printf "%s" "$MONITORS_FIXTURE"')
        self.stub("wlogout", 'printf "%s\\n" "$@"')
        self.env["MONITORS_FIXTURE"] = json.dumps(monitors)
        args = self.run_helper("power-menu").splitlines()
        return {flag: int(args[args.index(flag) + 1]) for flag in ["-b", "-L", "-R", "-T", "-B"]}

    def test_power_menu_desktop_and_hidpi(self):
        args = self.power_args([{"width": 1920, "height": 1080, "scale": 1}])
        self.assertEqual(args["-b"], 5)
        self.assertEqual(args["-L"], args["-R"])
        args = self.power_args([{"width": 1920, "height": 1080, "scale": 2}])
        self.assertEqual(args["-b"], 3)
        self.assertLess(args["-T"] * 2, 540)

    def test_power_menu_rotation_and_mixed_outputs(self):
        args = self.power_args([
            {"width": 1920, "height": 1080, "scale": 1},
            {"width": 1920, "height": 1080, "scale": 2, "transform": 1},
        ])
        self.assertEqual(args["-b"], 2)
        self.assertGreaterEqual(args["-L"], 16)

    def test_power_menu_without_compositor(self):
        self.assertEqual(self.power_args([])["-b"], 5)

    def test_bar_toggle_and_counter_reset(self):
        self.env["XDG_RUNTIME_DIR"] = str(self.root)
        self.stub("pkill", "exit 0")
        self.stub("nvidia-smi", "echo 42")
        self.stub("ip", "echo 'default dev lo'")
        closed = json.loads(self.run_helper("bar-stats"))
        self.assertEqual(closed["class"], "closed")
        self.run_helper("bar-stats", "toggle")
        opened = json.loads(self.run_helper("bar-stats"))
        self.assertIn(opened["class"], ["open", "hot"])
        self.assertNotIn("gpu:", opened["text"])
        self.assertIn("gpu: 42%", opened["tooltip"])
        # A previous interface had larger counters: resetting must not show
        # negative throughput or break JSON output.
        (self.root / "diag-bar/net").write_text("lo 999999999999 999999999999 0\n")
        sample = json.loads(self.run_helper("bar-stats"))
        self.assertIn("down 0B/s", sample["tooltip"])
        self.run_helper("bar-stats", "toggle")
        self.assertEqual(json.loads(self.run_helper("bar-stats"))["class"], "closed")

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
        template = checkout / ".config/qt6ct/qt6ct.conf"
        before = template.read_bytes()
        command = ["bash", str(checkout / "install-dotfiles.sh"), "--target", str(target)]
        subprocess.run(command, check=True, capture_output=True, timeout=15)
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
