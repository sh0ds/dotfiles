"""PICO-8 / Picotron helpers: token counts and which cart F5 runs. No consoles needed."""
import os
from pathlib import Path
import runpy
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
P8TOKENS = runpy.run_path(str(REPO / '.local/bin/p8tokens'))
count = P8TOKENS['count']

CART = """pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
#include src/main.lua
x=1
__gfx__
00000000
"""


class Tokens(unittest.TestCase):
    def test_free_things_are_free(self):
        self.assertEqual(count('local a=1'), 3)            # a = 1
        self.assertEqual(count('if a then b() end'), 5)    # if a then b (
        self.assertEqual(count('t={1,2,3}'), 6)            # t = { 1 2 3
        self.assertEqual(count('p.x=p.y'), 5)              # p x = p y
        self.assertEqual(count('a=1 -- comment\n// too\n--[[ and\nthis ]]'), 3)

    def test_pico8_syntax(self):
        self.assertEqual(count('x+=1'), 3)
        self.assertEqual(count('if (a!=b) c=1'), 8)        # if ( a != b c = 1
        self.assertEqual(count('?"hi"'), 2)
        self.assertEqual(count('x=a\\2'), 5)
        self.assertEqual(count('btn(❎)'), 3)

    def test_negative_literals(self):
        self.assertEqual(count('x=-1'), 3)                 # x = -1
        self.assertEqual(count('x=a-1'), 5)                # x = a - 1
        self.assertEqual(count('x=-a'), 4)                 # x = - a

    def test_strings_count_once(self):
        self.assertEqual(count('s="a b -- c" .. [[d\ne]]'), 5)


PLUGIN = REPO / '.local/share/fantasy-lua/pico8-plugin.lua'
DIFFS = """
local env = setmetatable({}, { __index = _ENV })
loadfile(arg[1], 't', env)()
local f = io.open(arg[2]); local text = f:read('a'); f:close()
for _, d in ipairs(env.OnSetText(arg[2], text)) do
  io.write(d.start, '\\t', d.finish, '\\t', (d.text:gsub('\\n', '\\\\n')), '\\n')
end
"""


@unittest.skipUnless(shutil.which('lua'), 'needs lua')
class LanguageServerPlugin(unittest.TestCase):
    """What the language server reads instead of the cart (pico8-plugin.lua)."""

    def seen(self, text, name='cart.p8'):
        with tempfile.TemporaryDirectory(prefix='pico8-plugin-') as tmp:
            src = Path(tmp) / name
            src.write_text(text)
            diffs = subprocess.run(['lua', '-', str(PLUGIN), str(src)], input=DIFFS,
                                   text=True, capture_output=True, check=True).stdout
        data = text.encode()
        edits = []
        for line in diffs.splitlines():
            start, finish, new = line.split('\t')
            edits.append((int(start), int(finish), new.replace('\\n', '\n').encode()))
        out, cur = b'', 1
        for start, finish, new in sorted(edits):
            out += data[cur - 1:start - 1] + new
            cur = finish + 1
        return (out + data[cur - 1:]).decode()

    def test_cart_sections_become_comments(self):
        seen = self.seen(CART)
        self.assertEqual(seen.splitlines()[:4], [
            '-- pico-8 cartridge // http://www.pico-8.com', '-- version 42', '-- __lua__',
            '-- #include src/main.lua'])
        self.assertIn('x=1\n-- __gfx__\n-- 00000000', seen)

    def test_shorthands(self):
        code = ('if (btn(❎)) x+=1 -- go\n'
                'while (y>0) y-=1\n'
                '?"hi",8,8\n'
                'a=b\\2 c=d^^1 e=@0x5f00 // done\n'
                's="if (a) b \\\\ // ?"\n')
        self.assertEqual(self.seen(code, 'main.lua'), (
            'if (btn(❎)) then x+=1 end -- go\n'
            'while (y>0) do y-=1 end\n'
            'print("hi",8,8)\n'
            'a=b//2 c=d~ 1 e= 0x5f00 -- done\n'
            's="if (a) b \\\\ // ?"\n'))

    def test_long_if_is_left_alone(self):
        code = 'if (a) then\n b()\nend\n'
        self.assertEqual(self.seen(code, 'main.lua'), code)


class Carts(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='pico8-test-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.game = self.root / 'code/pico8/game'
        (self.game / 'src').mkdir(parents=True)
        (self.game / 'game.p8').write_text(CART)
        (self.game / 'src/main.lua').write_text('function _draw() cls() end\n')
        (self.game / 'other.p8').write_text('__lua__\ny=2\n')
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.log = self.root / 'log'
        for name in ('pico8', 'picotron', 'wtype', 'notify-send', 'zeditor', 'fuzzel'):
            self.stub(name, f'echo "{name} $*" >>"{self.log}"')
        self.stub('hyprctl', 'case $1 in clients) echo "${CLIENTS:-[]}" ;; '
                             f'*) echo "hyprctl $*" >>"{self.log}" ;; esac')
        self.stub('sleep', ':')
        self.stub('wl-copy', f'echo "wl-copy $(cat)" >>"{self.log}"')
        self.stub('setsid', '[ "$1" = -f ] && shift; "$@"')
        self.env = dict(os.environ, HOME=str(self.root),
                        PATH=f"{self.bin}:{os.environ['PATH']}")

    def stub(self, name, body):
        f = self.bin / name
        f.write_text('#!/usr/bin/env bash\n' + body + '\n')
        f.chmod(0o755)

    def cart_run(self, *args):
        subprocess.run(['bash', str(REPO / '.local/bin/cart-run'), *args], env=self.env,
                       text=True, capture_output=True, timeout=10)
        return self.log.read_text() if self.log.exists() else ''

    def test_tokens_follow_includes(self):
        parts = P8TOKENS['cart_parts'](self.game / 'game.p8')
        self.assertEqual([label for label, _ in parts], ['game.p8', 'src/main.lua'])
        self.assertEqual(sum(count(code) for _, code in parts), 3 + 5)

    def test_lua_file_finds_the_cart_that_includes_it(self):
        cart, _ = P8TOKENS['find_cart'](str(self.game / 'src/main.lua'))
        self.assertEqual(cart.name, 'game.p8')

    def test_f5_starts_pico8_with_the_including_cart(self):
        out = self.cart_run(str(self.game / 'src/main.lua'))
        self.assertIn(f'pico8 -run {self.game}/game.p8', out)

    def test_f5_reruns_an_open_pico8(self):
        self.env['CLIENTS'] = '[{"class": "pico8", "address": "0xabc"}]'
        out = self.cart_run(str(self.game / 'src/main.lua'))
        self.assertIn('address:0xabc', out)
        self.assertIn('wtype -M ctrl r -m ctrl', out)
        self.assertNotIn('pico8 -run', out)

    def test_f5_links_the_language_server_settings_into_the_cart_folder(self):
        nested = self.root / 'code/pico8/jams/tiny'
        nested.mkdir(parents=True)
        (nested / 'tiny.p8').write_text(CART)
        (self.root / 'code/pico8/.luarc.json').write_text('{}')
        self.cart_run(str(nested / 'tiny.p8'))
        self.cart_run(str(nested / 'tiny.p8'))
        self.assertEqual(os.readlink(nested / '.luarc.json'), '../../.luarc.json')
        self.assertEqual(os.readlink(nested.parent / '.luarc.json'), '../.luarc.json')
        self.assertFalse((self.root / 'code/pico8/.luarc.json').is_symlink())

    def test_f5_in_picotron_code_reruns_picotron(self):
        code = self.root / 'code/picotron/tiny'
        code.mkdir(parents=True)
        (code / 'main.lua').write_text('')
        self.env['CLIENTS'] = '[{"class": "picotron", "address": "0xdef"}]'
        out = self.cart_run(str(code / 'main.lua'))
        self.assertIn('address:0xdef', out)
        self.assertIn('wtype', out)

    def fake_pico8(self, *args):
        """A process whose command line looks like a PICO-8 started with args."""
        p = subprocess.Popen(['python3', '-c', 'import time; time.sleep(30)', *args])
        self.addCleanup(p.kill)
        return p.pid

    def test_f5_picks_the_pico8_that_has_this_cart(self):
        other = self.fake_pico8('-run', str(self.game / 'other.p8'))
        mine = self.fake_pico8('-run', str(self.game / 'game.p8'))
        self.env['CLIENTS'] = (f'[{{"class": "pico8", "address": "0x1", "pid": {other}}},'
                               f' {{"class": "pico8", "address": "0x2", "pid": {mine}}}]')
        out = self.cart_run(str(self.game / 'game.p8'))
        self.assertIn('address:0x2', out)
        self.assertNotIn('pico8 -run', out)

    def test_f5_opens_another_cart_in_its_own_pico8(self):
        other = self.fake_pico8('-run', str(self.game / 'other.p8'))
        self.env['CLIENTS'] = f'[{{"class": "pico8", "address": "0x1", "pid": {other}}}]'
        out = self.cart_run(str(self.game / 'game.p8'))
        self.assertIn(f'pico8 -run {self.game}/game.p8', out)
        self.assertNotIn('wtype', out)

    def test_a_launcher_pico8_belongs_to_the_first_cart_f5_runs_in_it(self):
        blank = self.fake_pico8()
        self.env['CLIENTS'] = f'[{{"class": "pico8", "address": "0x1", "pid": {blank}}}]'
        self.assertIn('address:0x1', self.cart_run(str(self.game / 'game.p8')))
        self.log.unlink()
        self.assertIn('address:0x1', self.cart_run(str(self.game / 'game.p8')))
        self.log.unlink()
        out = self.cart_run(str(self.game / 'other.p8'))
        self.assertIn(f'pico8 -run {self.game}/other.p8', out)

    def test_f5_saves_pico8s_art_and_runs_zeds_code(self):
        cart = self.game / 'game.p8'
        cart.write_text('pico-8 cartridge\n__lua__\nx=2\n__gfx__\n0000\n')  # Zed's save
        stale = 'pico-8 cartridge\n__lua__\nx=1\n__gfx__\n1111\n'           # PICO-8's ctrl+s
        self.stub('wtype', f'echo "wtype $*" >>"{self.log}"; '
                           f'[ "$3" = s ] && printf {stale!r} >"{cart}" || true')
        self.env['PATH'] = f"{self.bin}:{REPO / '.local/bin'}:{os.environ['PATH']}"
        self.env['XDG_CACHE_HOME'] = str(self.root / 'cache')
        self.env['CLIENTS'] = '[{"class": "pico8", "address": "0xabc"}]'
        out = self.cart_run(str(cart))
        self.assertEqual(cart.read_text(), 'pico-8 cartridge\n__lua__\nx=2\n__gfx__\n1111\n')
        self.assertLess(out.index('wtype -M ctrl s'), out.index('wtype -M ctrl r'))
        self.assertEqual(len(list((self.root / 'cache/pico8/overwritten').iterdir())), 1)

    def cart_new(self, *args):
        self.stub('cart-run', f'echo "cart-run $*" >>"{self.log}"')
        subprocess.run(['bash', str(REPO / '.local/bin/cart-new'), *args], env=self.env,
                       text=True, capture_output=True, timeout=10, check=True)
        return self.log.read_text()

    def test_new_cart_next_to_the_file_you_are_in(self):
        ex = self.root / 'code/pico8/quick-exercises'
        ex.mkdir(parents=True)
        out = self.cart_new('E8 Bounce', '--in', str(ex))
        cart = ex / 'e8-bounce.p8'
        self.assertEqual(cart.read_text().splitlines(), [
            'pico-8 cartridge // http://www.pico-8.com', 'version 43', '__lua__', ''])
        self.assertIn(f'cart-run {cart}', out)
        self.assertIn(f'zeditor {self.root}/code/pico8 {cart}:4', out)

    def test_new_cart_at_the_top_gets_a_folder(self):
        self.cart_new('dash', '--in', str(self.root / 'code/pico8'))
        self.assertTrue((self.root / 'code/pico8/dash/dash.p8').exists())

    def test_new_cart_never_overwrites(self):
        self.cart_new('game', '--in', str(self.game))
        self.assertEqual((self.game / 'game.p8').read_text(), CART)

    def test_new_picotron_cart(self):
        top = self.root / 'code/picotron'
        top.mkdir(parents=True)
        out = self.cart_new('cave', '--in', str(top))
        self.assertTrue((top / 'cave/main.lua').exists())
        self.assertIn('wl-copy cd("/code/cave")', out)
        self.assertIn('picotron', out)


GUARD = runpy.run_path(str(REPO / '.local/bin/p8guard'))


class Guard(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='p8guard-test-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.cart = self.root / 'a.p8'
        GUARD['main'].__globals__['CACHE'] = self.root / 'cache'
        GUARD['main'].__globals__['notify'] = lambda *a: None
        self.pico8_focused = True
        self.guard = GUARD['Guard'](self.root, lambda: self.pico8_focused)

    def save(self, code, gfx='0000'):
        self.cart.write_text(f'pico-8 cartridge\nversion 43\n__lua__\n{code}__gfx__\n{gfx}\n')
        st = self.cart.stat()
        os.utime(self.cart, ns=(st.st_atime_ns, st.st_mtime_ns + 10**9 * (len(self.guard.seen) + 1)))
        self.guard.seen.clear()
        self.guard.scan()
        return self.cart.read_text()

    def test_pico8_saving_old_code_keeps_zeds_code_and_its_art(self):
        self.save('x=1\n')                 # PICO-8 loads this
        self.save('x=2\n')                 # Zed changes the code
        text = self.save('x=1\n', '1111')  # PICO-8 saves new art with its old code
        self.assertIn('__lua__\nx=2\n__gfx__\n1111', text)
        backups = list((self.root / 'cache/overwritten').iterdir())
        self.assertEqual(len(backups), 1)
        self.assertIn('x=1', backups[0].read_text())

    def test_code_written_in_pico8_is_kept(self):
        self.save('x=1\n')
        self.save('x=2\n')
        self.assertIn('x=3', self.save('x=3\n', '1111'))

    def test_going_back_in_zed_is_kept(self):
        self.save('x=1\n')
        self.save('x=2\n')
        self.pico8_focused = False
        self.assertIn('__lua__\nx=1\n', self.save('x=1\n'))


class ZedExtension(unittest.TestCase):
    def test_setup_points_zed_at_the_committed_grammar(self):
        grammar = '.local/share/zed-pico8/grammar'
        rev = subprocess.run(['git', '-C', str(REPO), 'log', '-1', '--format=%H', '--', grammar],
                             capture_output=True, text=True).stdout.strip()
        dirty = subprocess.run(['git', '-C', str(REPO), 'status', '--porcelain', '--', grammar],
                               capture_output=True, text=True).stdout
        if not rev or dirty:
            self.skipTest('grammar not committed')
        with tempfile.TemporaryDirectory(prefix='zed-pico8-') as tmp:
            home, bin_ = Path(tmp), Path(tmp) / 'bin'
            ext = home / '.local/share/zed-pico8'
            ext.mkdir(parents=True)
            (ext / 'Cargo.toml').write_text('')
            bin_.mkdir()
            for name in ('lua-language-server', 'rustup'):
                (bin_ / name).write_text('#!/bin/sh\n')
                (bin_ / name).chmod(0o755)
            subprocess.run(['bash', str(REPO / '.local/bin/zed-pico8')], check=True,
                           capture_output=True, env=dict(os.environ, HOME=str(home),
                           PATH=f"{bin_}:{os.environ['PATH']}"))
            toml = (ext / 'extension.toml').read_text()
        self.assertIn(f'repository = "file://{REPO}"', toml)
        self.assertIn(f'rev = "{rev}"', toml)


if __name__ == '__main__':
    unittest.main()
