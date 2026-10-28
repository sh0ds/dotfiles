"""Isolated file-manager setup and action regressions; no desktop/library writes."""
import ctypes
import ctypes.util
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET

REPO = Path(__file__).resolve().parents[1]


class FileManager(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='diag-files-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root / "user's home & files"
        self.config = self.home / 'custom config'
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        (self.home / 'Music').mkdir(parents=True)
        (self.home / 'code').mkdir()
        self.env = dict(os.environ, HOME=str(self.home), XDG_CONFIG_HOME=str(self.config),
                        PATH=f'{self.bin}:{os.environ["PATH"]}',
                        DBUS_SESSION_BUS_ADDRESS='fixture',
                        XFCONF_STATE=str(self.root / 'xfconf.json'),
                        CALLS=str(self.root / 'calls.jsonl'))
        self.stub('thunar', 'pass')
        self.stub('notify-send', 'pass')
        self.stub('xfconf-query', '''
import os, json, sys
from pathlib import Path
path = Path(os.environ['XFCONF_STATE'])
data = json.loads(path.read_text()) if path.exists() else {}
args = sys.argv[1:]
key = args[args.index('--property') + 1]
if '--set' in args:
    data[key] = args[args.index('--set') + 1]
    path.write_text(json.dumps(data))
elif key not in data:
    sys.exit(1)
else:
    print(data[key])
''')

    def stub(self, name, body):
        path = self.bin / name
        path.write_text(f'#!{sys.executable}\n' + body + '\n')
        path.chmod(0o755)

    def recorder(self, name):
        self.stub(name, '''
import os, sys, json
with open(os.environ['CALLS'], 'a') as stream:
    stream.write(json.dumps([sys.argv[0].rsplit('/', 1)[-1], sys.argv[1:], sys.stdin.read()]) + '\\n')
''')

    def helper(self, name, *args, success=True):
        interpreter = sys.executable if name == 'thunar-action' else 'bash'
        result = subprocess.run([interpreter, str(REPO / '.local/bin' / name), *map(str, args)],
                                env=self.env, text=True, capture_output=True, timeout=15)
        if success:
            self.assertEqual(result.returncode, 0, result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0)
        return result

    def calls(self):
        return [json.loads(line) for line in (self.root / 'calls.jsonl').read_text().splitlines()]

    def test_setup_preserves_preferences_actions_and_bookmarks(self):
        actions = self.config / 'Thunar/uca.xml'
        actions.parent.mkdir(parents=True)
        actions.write_text('<actions><action><unique-id>personal</unique-id><command>mine %F</command></action></actions>')
        bookmarks = self.config / 'gtk-3.0/bookmarks'
        bookmarks.parent.mkdir()
        bookmarks.write_text('file:///srv/samples Samples\n')
        self.helper('thunar-setup')
        state = Path(self.env['XFCONF_STATE'])
        data = json.loads(state.read_text())
        self.assertEqual(data['/last-view'], 'ThunarDetailsView')
        self.assertEqual(data['/misc-date-custom-style'], '%Y-%m-%d %H:%M')
        data['/last-view'] = 'ThunarIconView'
        data['/personal'] = 'keep'
        state.write_text(json.dumps(data))
        helpers = self.config / 'xfce4/helpers.rc'
        helpers.write_text('WebBrowser=personal\nTerminalEmulator=personal-terminal\n')
        self.helper('thunar-setup')
        self.assertEqual(json.loads(state.read_text())['/last-view'], 'ThunarIconView')
        self.assertIn('TerminalEmulator=personal-terminal', helpers.read_text())
        self.helper('thunar-setup', '--apply')
        data = json.loads(state.read_text())
        self.assertEqual(data['/last-view'], 'ThunarDetailsView')
        self.assertEqual(data['/personal'], 'keep')
        self.assertIn('WebBrowser=personal', helpers.read_text())
        self.assertIn('TerminalEmulator=kitty', helpers.read_text())
        entries = ET.parse(actions).getroot().findall('action')
        self.assertEqual(len(entries), 6)
        self.assertEqual(entries[0].findtext('command'), 'mine %F')
        self.assertEqual({entry.findtext('command') for entry in entries[1:]},
                         {'thunar-action edit %F', 'thunar-action terminal %F', 'thunar-action git %F',
                          'thunar-action queue %F', 'thunar-action audacity %F'})
        lines = bookmarks.read_text().splitlines()
        self.assertEqual(len(lines), 3)
        self.assertIn('file:///srv/samples Samples', lines)
        self.assertIn((self.home / 'Music').as_uri() + ' Music', lines)

    def test_setup_requires_desktop_bus_before_writing(self):
        self.env.pop('DBUS_SESSION_BUS_ADDRESS')
        self.helper('thunar-setup', success=False)
        self.assertFalse(self.config.exists())
        self.assertFalse(Path(self.env['XFCONF_STATE']).exists())
        self.helper('thunar-setup', '--help')

    def test_existing_stock_terminal_action_is_not_duplicated(self):
        actions = self.config / 'Thunar/uca.xml'
        actions.parent.mkdir(parents=True)
        actions.write_text('<actions><action><unique-id>stock</unique-id>'
                           '<command>exo-open --launch TerminalEmulator</command></action></actions>')
        self.helper('thunar-setup')
        entries = ET.parse(actions).getroot().findall('action')
        self.assertEqual(len(entries), 5)
        self.assertNotIn('diag-terminal', [entry.findtext('unique-id') for entry in entries])

    def test_neovim_receives_literal_paths_and_project_directory(self):
        self.recorder('kitty')
        project = self.home / 'code' / '$(touch nope) & project'
        project.mkdir()
        self.helper('thunar-action', 'edit', project)
        file = project / '-script & "test".py'
        file.touch()
        self.helper('thunar-action', 'edit', file)
        calls = self.calls()
        self.assertEqual(calls[0][1], ['--directory', str(project), '-e', 'nvim', '--', str(project)])
        self.assertEqual(calls[1][1][-2:], ['--', str(file)])

    def test_queue_recurses_deduplicates_and_never_changes_playback(self):
        self.recorder('mpc')
        folder = self.home / 'Music/DJ & edits'
        folder.mkdir()
        track = folder / '-Artist "live".mp3'
        track.touch()
        (folder / '02 — mix.FLAC').touch()
        (folder / 'cover.png').touch()
        self.helper('thunar-action', 'queue', folder, track)
        calls = self.calls()
        self.assertEqual(calls[0][1], ['--host', '127.0.0.1', '--port', '6600', '--wait', 'update'])
        self.assertEqual(calls[1][1], ['--host', '127.0.0.1', '--port', '6600', 'add'])
        self.assertEqual(calls[1][2].splitlines(), ['DJ & edits/-Artist "live".mp3', 'DJ & edits/02 — mix.FLAC'])
        self.assertEqual(len(calls), 2)

    def test_terminal_and_git_actions_use_selected_folder(self):
        self.recorder('kitty')
        project = self.home / 'code/project & tracks'
        project.mkdir()
        subprocess.run(['git', 'init', '-q', str(project)], check=True)
        self.helper('thunar-action', 'terminal', project)
        self.helper('thunar-action', 'git', project)
        self.assertEqual(self.calls()[0][1], ['--directory', str(project)])
        self.assertEqual(self.calls()[1][1], ['--directory', str(project), '-e', 'lazygit'])
        self.helper('thunar-action', 'git', self.home / 'Music', success=False)
        self.assertEqual(len(self.calls()), 2)

    def test_outside_library_and_escaping_links_are_rejected_before_mpd(self):
        self.recorder('mpc')
        outside = self.home / 'outside.mp3'
        outside.touch()
        self.helper('thunar-action', 'queue', outside, success=False)
        link = self.home / 'Music/link.mp3'
        link.symlink_to(outside)
        self.helper('thunar-action', 'queue', self.home / 'Music', success=False)
        self.assertFalse((self.root / 'calls.jsonl').exists())

    def test_failed_database_update_does_not_append(self):
        self.stub('mpc', 'import sys; print("daemon unavailable", file=sys.stderr); sys.exit(1)')
        track = self.home / 'Music/track.mp3'
        track.touch()
        result = self.helper('thunar-action', 'queue', track, success=False)
        self.assertIn('daemon unavailable', result.stderr)

    def test_audacity_receives_selected_audio_only(self):
        self.recorder('audacity')
        track = self.home / 'Music/edit.wav'
        track.touch()
        self.helper('thunar-action', 'audacity', track)
        self.assertEqual(self.calls()[0][1], [str(track)])
        self.helper('thunar-action', 'audacity', self.home / 'Music', success=False)

    def test_archive_defaults_are_explicit(self):
        self.stub('xarchiver', 'pass')
        self.recorder('xdg-mime')
        self.helper('default-apps')
        calls = self.calls()
        self.assertEqual(calls[0][1], ['default', 'thunar.desktop', 'inode/directory'])
        self.assertEqual(calls[1][1][:2], ['default', 'xarchiver.desktop'])
        self.assertIn('application/zip', calls[1][1])
        self.assertIn('application/x-xz-compressed-tar', calls[1][1])


class DialogRules(unittest.TestCase):
    def test_actual_lua_config_keeps_browsers_tiled_and_dialogs_floating(self):
        library = ctypes.util.find_library('lua5.4')
        if not library:
            self.skipTest('Lua 5.4 shared library required')
        lua = ctypes.CDLL(library)
        pointer = ctypes.c_void_p
        lua.luaL_newstate.restype = pointer
        lua.luaL_openlibs.argtypes = [pointer]
        lua.luaL_loadstring.argtypes = [pointer, ctypes.c_char_p]
        lua.lua_pcallk.argtypes = [pointer, ctypes.c_int, ctypes.c_int, ctypes.c_int,
                                  ctypes.c_longlong, pointer]
        lua.lua_tolstring.argtypes = [pointer, ctypes.c_int, pointer]
        lua.lua_tolstring.restype = ctypes.c_char_p
        lua.lua_close.argtypes = [pointer]
        state = lua.luaL_newstate()
        try:
            lua.luaL_openlibs(state)
            shim = '''
local sink
sink = setmetatable({}, {__index=function() return sink end, __call=function() return sink end})
local rules = {}
hl = setmetatable({dsp=sink, get_windows=function() return {} end,
    window_rule=function(rule) rules[#rules+1]=rule; return sink end},
    {__index=function() return sink end})
package.path = %s .. '/.config/hypr/?.lua;' .. package.path
dofile(%s .. '/.config/hypr/rice.lua')
local result = {}
for _, r in ipairs(rules) do
    if r.name:match('^thunar') or r.name == 'file-manager-modal-dialogs' or r.name == 'archive-action-dialogs' then
        assert(r.float and r.center and r.max_size and not r.size)
        result[#result+1] = table.concat({r.match.class, r.match.title or '', tostring(r.match.modal)}, '\\t')
    end
end
return table.concat(result, '\\n')
''' % (json.dumps(str(REPO)), json.dumps(str(REPO)))
            status = lua.luaL_loadstring(state, shim.encode())
            if not status:
                status = lua.lua_pcallk(state, 0, 1, 0, 0, None)
            output = lua.lua_tolstring(state, -1, None).decode()
            self.assertEqual(status, 0, output)
        finally:
            lua.lua_close(state)
        rules = [line.split('\t') for line in output.splitlines()]
        self.assertEqual(len(rules), 4)

        def floating(app, title, modal=False):
            return any(re.search(app_re, app) and (not title_re or re.search(title_re, title))
                       and (hint != 'true' or modal) for app_re, title_re, hint in rules)

        for app, title, modal in [('Thunar', 'Rename "track.mp3"', False),
                                  ('org.xfce.thunar', '"track.mp3" umbenennen', False),
                                  ('Thunar', 'track.mp3 - Properties', False),
                                  ('Thunar', 'Copy confirmation', True),
                                  ('Xarchiver', 'Extract files', False),
                                  ('xarchiver', 'Multi-Extract', False),
                                  ('xarchiver', 'Dateien entpacken', False)]:
            self.assertTrue(floating(app, title, modal), (app, title))
        for app, title in [('Thunar', 'Downloads - Thunar'),
                           ('Thunar', 'Rename "files" - Thunar'),
                           ('Thunar', 'Properties - Thunar'),
                           ('Xarchiver', 'Music.zip - Xarchiver'),
                           ('Firefox', 'Extract files')]:
            self.assertFalse(floating(app, title), (app, title))


if __name__ == '__main__':
    unittest.main()
