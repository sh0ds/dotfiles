"""torrent, dl and dl-done against a stubbed aria2-rpc (curl answers from a file)."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
BIN = REPO / '.local/bin'


class Torrent(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='torrent-test-')
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        fake = self.home / 'bin'
        fake.mkdir()
        (self.home / '.local/state/aria2').mkdir(parents=True)
        (self.home / '.local/state/aria2/secret').write_text('s3cret\n')
        self.requests = self.home / 'requests'
        self.calls = self.home / 'calls'
        self.reply = self.home / 'reply'
        self.reply.write_text('{"id":"torrent","jsonrpc":"2.0","result":"0123456789abcdef"}')
        stubs = {
            # The request body comes as -d @- (stdin) or -d '<json>'; one per line.
            'curl': 'body=; while (($#)); do [ "$1" = -d ] && body=$2; shift; done\n'
                    '[ "$body" = @- ] && body=$(cat)\n'
                    f'printf "%s\\n" "$body" >> "{self.requests}"; cat "{self.reply}"',
            'notify-send': f'echo "notify-send $*" >> "{self.calls}"',
            'thunar': f'echo "thunar $*" >> "{self.calls}"',
            'wl-paste': 'printf "%s" "magnet:?xt=urn:btih:abc&dn=Arch+Linux%202026.11.01"',
        }
        for name, body in stubs.items():
            (fake / name).write_text(f'#!/usr/bin/env bash\n{body}\n')
            (fake / name).chmod(0o755)
        self.env = dict(os.environ, HOME=str(self.home), PATH=f'{fake}:{BIN}:{os.environ["PATH"]}')
        self.env.pop('XDG_STATE_HOME', None)

    def run_bin(self, name, *args, ok=True):
        result = subprocess.run(['bash', str(BIN / name), *args], env=self.env, capture_output=True, text=True)
        if ok:
            self.assertEqual(result.returncode, 0, result.stderr)
        return result

    def sent(self):
        return [json.loads(line) for line in self.requests.read_text().splitlines()] if self.requests.exists() else []

    def notes(self):
        return self.calls.read_text().splitlines() if self.calls.exists() else []

    def test_magnet_from_the_clipboard_goes_to_aria2_with_the_token(self):
        self.run_bin('torrent')
        [request] = self.sent()
        self.assertEqual(request['method'], 'aria2.addUri')
        self.assertEqual(request['params'], ['token:s3cret', ['magnet:?xt=urn:btih:abc&dn=Arch+Linux%202026.11.01']])
        self.assertIn('Torrent added Arch Linux 2026.11.01', ' '.join(self.notes()))

    def test_torrent_file_is_sent_as_base64_also_from_a_file_link(self):
        file = self.home / 'my distro.torrent'
        file.write_bytes(b'd4:infod4:name3:isoee')
        self.run_bin('torrent', 'file://' + str(file).replace(' ', '%20'))
        [request] = self.sent()
        self.assertEqual(request['method'], 'aria2.addTorrent')
        self.assertEqual(request['params'], ['token:s3cret', 'ZDQ6aW5mb2Q0Om5hbWUzOmlzb2Vl'])

    def test_aria2_errors_and_junk_are_reported(self):
        result = self.run_bin('torrent', '/no/such/file', ok=False)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(self.sent(), [])
        self.reply.write_text('{"id":"torrent","jsonrpc":"2.0","error":{"code":1,"message":"Unauthorized"}}')
        result = self.run_bin('torrent', 'magnet:?xt=urn:btih:abc', ok=False)
        self.assertEqual(result.returncode, 1)
        self.assertIn('Unauthorized', result.stderr)

    def test_dl_hands_magnets_and_torrent_links_to_torrent(self):
        self.run_bin('dl', 'magnet:?xt=urn:btih:abc')
        self.run_bin('dl', 'https://example.org/arch.iso.torrent')
        self.assertEqual([r['params'][1] for r in self.sent()], [['magnet:?xt=urn:btih:abc'], ['https://example.org/arch.iso.torrent']])

    def test_dl_done_pings_once_per_torrent_with_its_name(self):
        # dl-done's exit code doesn't matter to aria2 (no click on the ping is 1).
        done = lambda *args: self.run_bin('dl-done', *args, ok=False)
        # Before seeding: still active, so it pings, with the torrent's name.
        self.reply.write_text('{"result":{"status":"active","bittorrent":{"info":{"name":"Arch Linux"}}}}')
        done('abc', '3', str(self.home / 'Downloads/Arch Linux/a.iso'))
        # After seeding: complete and a torrent, so it stays quiet.
        self.reply.write_text('{"result":{"status":"complete","bittorrent":{"info":{"name":"Arch Linux"}}}}')
        done('abc', '3', str(self.home / 'Downloads/Arch Linux/a.iso'))
        # A magnet link's info step: quiet without asking.
        done('def', '1', '[METADATA]Arch+Linux')
        # A plain download: pings.
        self.reply.write_text('{"result":{"status":"complete"}}')
        done('ghi', '1', str(self.home / 'Downloads/file.zip'))
        pings = [n for n in self.notes() if n.startswith('notify-send')]
        self.assertEqual(len(pings), 2, pings)
        self.assertTrue(pings[0].endswith('Download done Arch Linux'), pings[0])
        self.assertTrue(pings[1].endswith('Download done file.zip'), pings[1])
        self.assertEqual(len(self.sent()), 3)


if __name__ == '__main__':
    unittest.main()
