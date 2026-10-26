"""DJ VM regressions: isolated files, simulated libvirt, no real VM or downloads."""
import io
import os
from pathlib import Path
import runpy
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch
import xml.etree.ElementTree as ET

SCRIPT = Path(__file__).resolve().parents[1] / '.local/bin/djvm'
ISO = b'\0' * 32769 + b'CD001' + b'\0' * 4096


class Djvm(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='djvm-test-')
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name) / 'user & space'
        self.home.mkdir()
        env = patch.dict(os.environ, HOME=str(self.home), XDG_DATA_HOME=str(self.home / '.local/share'))
        env.start()
        self.addCleanup(env.stop)
        namespace = runpy.run_path(str(SCRIPT))
        self.g = namespace['main'].__globals__
        self.definition = ET.Element('domain')
        devices = ET.SubElement(self.definition, 'devices')
        self.disk = ET.SubElement(devices, 'disk', type='file', device='disk')
        ET.SubElement(self.disk, 'source', file=str(self.home / 'windows.qcow2'))
        ET.SubElement(self.disk, 'target', dev='vda', bus='virtio')
        self.running = False
        self.present = True
        self.calls = []
        self.g['virsh'] = self.virsh
        self.download = Mock(return_value=io.BytesIO(ISO))
        self.urlpatch = patch('urllib.request.urlopen', self.download)
        self.urlpatch.start()
        self.addCleanup(self.urlpatch.stop)
        self.args = type('Args', (), {'windows': None, 'virtio': None})()

    def virsh(self, *args):
        self.calls.append(args)
        if args[0] == 'list':
            return 'dj' if self.present else ''
        if args[0] == 'domstate':
            return 'running' if self.running else 'shut off'
        if args[0] == 'dumpxml':
            return ET.tostring(self.definition, encoding='unicode')
        if args[0] == 'update-device':
            new = ET.parse(args[2]).getroot()
            devices = self.definition.find('devices')
            old = next(d for d in devices if d.find('target').get('dev') == new.find('target').get('dev'))
            devices.remove(old)
            devices.append(new)
            return ''
        if args[0] == 'destroy':
            self.fail('must not force power off')
        if args[0] == 'start':
            self.running = True
        return ''

    def cd(self, path, target):
        disk = ET.SubElement(self.definition.find('devices'), 'disk', type='file', device='cdrom')
        ET.SubElement(disk, 'source', file=str(path), startupPolicy='mandatory')
        ET.SubElement(disk, 'target', dev=target, bus='sata')
        ET.SubElement(disk, 'readonly')

    def local_iso(self, name):
        path = self.home / 'Downloads' / name
        path.parent.mkdir(exist_ok=True)
        path.write_bytes(ISO)
        return path

    def test_setup_repairs_missing_virtio_and_migrates_windows_without_touching_disk(self):
        windows = self.local_iso('Win11_English.iso')
        missing = self.home / 'Downloads/virtio-win.iso'
        self.cd(windows, 'sda')
        self.cd(missing, 'sdb')
        before = ET.tostring(self.disk)
        definition = ET.tostring(self.definition, encoding='unicode')
        self.g['setup'](self.args)
        self.download.assert_called_once()
        for disk in self.g['optical'](self.definition):
            path = self.g['source'](disk)
            self.assertEqual(path.parent, self.g['MEDIA'])
            self.assertEqual(path.read_bytes(), ISO)
            self.assertEqual(disk.find('source').get('startupPolicy'), 'mandatory')
        self.assertEqual(windows.read_bytes(), ISO)
        self.assertEqual(ET.tostring(self.disk), before)
        backup = next((self.g['DATA'] / 'backups').glob('*.xml'))
        self.assertEqual(backup.read_text(), definition + '\n')
        self.g['setup'](self.args)
        self.assertEqual(self.download.call_count, 1)
        self.assertEqual(len([c for c in self.calls if c[0] == 'update-device']), 2)

    def test_failed_download_leaves_definition_and_media_unchanged(self):
        self.cd(self.home / 'Downloads/virtio-win.iso', 'sda')
        self.download.return_value = io.BytesIO(b'<html>temporary error</html>')
        before = ET.tostring(self.definition)
        with self.assertRaisesRegex(RuntimeError, 'not an ISO'):
            self.g['setup'](self.args)
        self.assertEqual(ET.tostring(self.definition), before)
        self.assertFalse((self.g['MEDIA'] / 'virtio-win.iso').exists())
        self.assertEqual(list(self.g['MEDIA'].glob('*.part')), [])

    def test_truncated_download_is_not_installed(self):
        response = io.BytesIO(ISO)
        response.headers = {'Content-Length': str(len(ISO) + 100)}
        self.download.return_value = response
        with self.assertRaisesRegex(RuntimeError, 'incomplete'):
            self.g['setup'](self.args)
        self.assertFalse((self.g['MEDIA'] / 'virtio-win.iso').exists())
        self.assertFalse(any(c[0] == 'update-device' for c in self.calls))

    def test_power_action_is_cancelled_when_vm_shutdown_fails(self):
        bin_dir = self.home / 'bin'
        bin_dir.mkdir()
        marker = self.home / 'power-called'
        for name, body in [('djvm', 'exit 1'), ('notify-send', 'exit 0'),
                           ('systemctl', 'touch "$POWER_MARKER"'),
                           ('hyprctl', 'touch "$POWER_MARKER"')]:
            stub = bin_dir / name
            stub.write_text('#!/usr/bin/env bash\n' + body + '\n')
            stub.chmod(0o755)
        env = dict(os.environ, PATH=f"{bin_dir}:{os.environ['PATH']}",
                   POWER_DETACHED='1', POWER_MARKER=str(marker))
        for action in ('logout', 'reboot', 'poweroff'):
            result = subprocess.run(['bash', str(SCRIPT.parent / 'power'), action],
                                    env=env, capture_output=True, timeout=5)
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse(marker.exists())

    def test_running_vm_refuses_media_changes_before_network_or_copy(self):
        self.running = True
        with self.assertRaisesRegex(RuntimeError, 'shut Windows down'):
            self.g['setup'](self.args)
        self.download.assert_not_called()
        self.assertFalse(self.g['MEDIA'].exists())

    def test_start_missing_media_has_actionable_error_and_never_starts(self):
        self.cd(self.home / 'Downloads/virtio-win.iso', 'sda')
        with patch.object(sys, 'argv', ['djvm']):
            with self.assertRaisesRegex(RuntimeError, 'djvm setup'):
                self.g['main']()
        self.assertFalse(any(c[0] == 'start' for c in self.calls))
        self.download.assert_not_called()

    def test_eject_changes_only_optical_sources_and_preserves_files(self):
        windows = self.local_iso('Win11.iso')
        self.cd(windows, 'sda')
        before = ET.tostring(self.disk)
        with patch.object(sys, 'argv', ['djvm', 'eject']):
            self.g['main']()
        self.assertTrue(windows.is_file())
        self.assertEqual(ET.tostring(self.disk), before)
        self.assertTrue(all(self.g['source'](d) is None for d in self.g['optical'](self.definition)))

    def test_setup_refuses_ambiguous_windows_and_overwriting_existing_iso(self):
        self.local_iso('Win11_A.iso')
        second = self.local_iso('Win11_B.iso')
        with self.assertRaisesRegex(RuntimeError, 'multiple windows'):
            self.g['setup'](self.args)
        self.g['MEDIA'].mkdir(parents=True)
        target = self.g['MEDIA'] / 'windows11.iso'
        target.write_bytes(ISO + b'other version')
        self.args.windows = str(second)
        with self.assertRaisesRegex(RuntimeError, 'different contents'):
            self.g['setup'](self.args)
        self.assertEqual(target.read_bytes(), ISO + b'other version')
        self.download.assert_not_called()

    def test_off_timeout_does_not_destroy_or_start_viewer(self):
        self.running = True
        with patch('time.sleep'), patch('subprocess.run'), patch.object(sys, 'argv', ['djvm', 'off']):
            with self.assertRaisesRegex(RuntimeError, 'leaving it running'):
                self.g['main']()
        self.assertTrue(self.running)
        self.assertFalse(any(c[0] in ('destroy', 'start') for c in self.calls))

    def test_create_uses_persistent_isos_and_returns_to_viewer(self):
        self.present = False
        windows = self.local_iso('Win11.iso')
        virtio = self.local_iso('virtio-win.iso')
        def create(args, **kwargs):
            self.present = True
            self.running = True
            return subprocess.CompletedProcess(args, 0)
        with patch('subprocess.run', side_effect=create) as install, patch('os.execvp') as viewer:
            with patch.object(sys, 'argv', ['djvm', 'create', '--windows', str(windows), '--virtio', str(virtio)]):
                self.g['main']()
        command = install.call_args.args[0]
        self.assertNotIn(str(windows), command)
        self.assertEqual(command[command.index('--cdrom') + 1], str(self.g['MEDIA'] / 'windows11.iso'))
        self.assertIn(str(self.g['MEDIA'] / 'virtio-win.iso') + ',device=cdrom', command)
        viewer.assert_called_once()
        self.download.assert_not_called()


if __name__ == '__main__':
    unittest.main()
