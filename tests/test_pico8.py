"""PICO-8 / Picotron helpers: token counts and which cart F5 runs. No consoles needed."""
import os
from pathlib import Path
import runpy
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
        for name in ('pico8', 'picotron', 'wtype', 'notify-send'):
            self.stub(name, f'echo "{name} $*" >>"{self.log}"')
        self.stub('hyprctl', 'case $1 in clients) echo "${CLIENTS:-[]}" ;; '
                             f'*) echo "hyprctl $*" >>"{self.log}" ;; esac')
        self.stub('sleep', ':')
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


if __name__ == '__main__':
    unittest.main()
