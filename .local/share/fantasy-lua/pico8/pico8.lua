---@meta pico8
-- PICO-8's API for lua-language-server: hover docs, completion, argument
-- hints and "undefined global" warnings in Zed. Only used for completion,
-- never run. Function docs generated from japhib/pico8-ls (builtins.ts):
--
-- Copyright 2022 JanPaul Bergeson
--
-- Permission is hereby granted, free of charge, to any person obtaining a
-- copy of this software and associated documentation files (the "Software"),
-- to deal in the Software without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
-- IN THE SOFTWARE.

-- Button glyphs (shift+L/R/U/D/O/X in PICO-8), so btn(❎) works here too.
⬅️ = 0
➡️ = 1
⬆️ = 2
⬇️ = 3
🅾️ = 4
❎ = 5

-- The other shift+letter glyphs are fill patterns for fillp(); PICO-8 knows
-- their values, the editor only needs to know they exist.
---@type number
█ = nil
---@type number
▒ = nil
---@type number
🐱 = nil
---@type number
░ = nil
---@type number
✽ = nil
---@type number
● = nil
---@type number
♥ = nil
---@type number
☉ = nil
---@type number
웃 = nil
---@type number
⌂ = nil
---@type number
😐 = nil
---@type number
♪ = nil
---@type number
◆ = nil
---@type number
… = nil
---@type number
★ = nil
---@type number
⧗ = nil
---@type number
ˇ = nil
---@type number
∧ = nil
---@type number
▤ = nil
---@type number
▥ = nil

--- `abs( num )`
---
--- Returns the absolute value of a number.
---@param num any The number.
---@return any # The absolute value of num.
function abs(num) end

--- `add( table, value, [index] )`
---
--- Adds a element to the end of a sequence in a table.
---@param table any The table.
---@param value any The value to add.
---@param index? any The index for the value to be inserted.
---@return any # The value that was passed in.
function add(table, value, index) end

--- `all( tbl )`
---
--- Returns an iterator for all non-nil items in a sequence in a table, for use with for...in.
---@param tbl any The table to iterate.
---@return any # An interator function that can be used with for...in to iterate over tbl.
function all(tbl) end

--- `assert( cond, [message] )`
---
--- Causes a runtime error if a conditional expression is false.
---@param cond any The conditional expression to assert.
---@param message? any A message to print when the assertion fails.
---@return any # All arguments as passed to assert() in a tuple (if the assert didn't fail).
function assert(cond, message) end

--- `atan2( dx, dy )`
---
--- Calculates the arctangent of dy/dx, the angle formed by the vector on the unit circle. The result is adjusted to represent the full circle.
---@param dx any The horizontal component.
---@param dy any The vertical component.
---@return any # The angle of the line from 0,0 to dx,dy.
function atan2(dx, dy) end

--- `band( first, second )`
---
--- Calculates the bitwise-and of two numbers.
---@deprecated
---@param first any The first number.
---@param second any The second number.
---@return any # The bitwise-and of first and second.
function band(first, second) end

--- `bnot( num )`
---
--- Calculates the bitwise not of a number.
---@deprecated
---@param num any The number.
---@return any # The bitwise-not of num.
function bnot(num) end

--- `bor( first, second )`
---
--- Calculates the bitwise-or of two numbers.
---@deprecated
---@param first any The first number.
---@param second any The second number.
---@return any # The bitwise-or of first and second.
function bor(first, second) end

--- `btn( [i,] [p] )`
---
--- Tests if a button is being pressed at this moment.
---@param i? any The button number.
---@param p? any The player number.
---@return any # If a button is specified, then true or false, otherwise a bitfield for multiple players.
function btn(i, p) end

--- `btnp( [i,] [p] )`
---
--- Tests if a button has just been pressed, with keyboard-style repeating.
---@param i? any The button number.
---@param p? any The player number.
---@return any # If a button is specified, then true or false, otherwise a bitfield for multiple players.
function btnp(i, p) end

--- `bxor( first, second )`
---
--- Calculates the bitwise-xor (exclusive or) of two numbers.
---@deprecated
---@param first any The first number.
---@param second any The second number.
---@return any # The bitwise-xor of first and second.
function bxor(first, second) end

--- `camera( [x,] [y] )`
---
--- Sets the camera offset in the draw state.
---@param x? any The x offset, in pixels, to subtract from future draw coordinates. (default 0)
---@param y? any The y offset, in pixels, to subtract from future draw coordinates. (default 0)
---@return any # An x,y tuple representing the previous camera offset.
function camera(x, y) end

--- `cartdata( id )`
---
--- Sets up cartridge data for the cart.
---@param id any A string that is likely to be unique across all PICO-8 carts.
function cartdata(id) end

--- `ceil( num )`
---
--- Returns the nearest integer at or above a number (its "ceiling").
---@param num any The number.
---@return any # The nearest integer at or above num.
function ceil(num) end

--- `chr( ord, ... )`
---
--- Gets the character(s) corresponding to an ordinal(s) (numeric) value.
---@param ord any
---@param ... any
---@return any # A string consisting of a single character corresponding to the given ordinal number or a string of characters if an array was provided
function chr(ord, ...) end

--- `circ( x, y, [r,] [col] )`
---
--- Draws a circle shape, without fill.
---@param x any The x coordinate of the center of the circle.
---@param y any The y coordinate of the center of the circle.
---@param r? any The radius of the circle, in pixels. If omitted, the radius will be 4.
---@param col? any The color of the circle and fill. If omitted, the color from the draw state is used.
function circ(x, y, r, col) end

--- `circfill( x, y, [r,] [col] )`
---
--- Draws a filled-in circle shape.
---@param x any The x coordinate of the center of the circle.
---@param y any The y coordinate of the center of the circle.
---@param r? any The radius of the circle, in pixels. If omitted, the radius will be 4.
---@param col? any The color of the circle and fill. If omitted, the color from the draw state is used.
function circfill(x, y, r, col) end

--- `clip( x, y, w, h, [clip_previous] )`
---
--- Sets the clipping region in the draw state.
---@param x any The x coordinate of the upper left corner of the clipping rectangle.
---@param y any The y coordinate of the upper left corner of the clipping rectangle.
---@param w any The width of the clipping rectangle, in pixels.
---@param h any The height of the clipping rectangle, in pixels.
---@param clip_previous? any If true, the new clipping rectangle is formed by clipping it to the area of the one currently specified within the draw state.
---@return any # An x,y,w,h tuple representing the previous clipping rectangle.
function clip(x, y, w, h, clip_previous) end

--- `cls( [color] )`
---
--- Clears the graphics buffer.
---@param color? any A color to use for the background. The default is 0 (black).
function cls(color) end

--- `cocreate( func )`
---
--- Creates a coroutine from a function.
---@param func any The function for the coroutine to run.
---@return any # A new coroutine.
function cocreate(func) end

--- `color( [col] )`
---
--- Sets the draw color in the draw state.
---@param col? any The color number. Default is 6 (light gray).
function color(col) end

--- `coresume( cor, [...] )`
---
--- Starts a coroutine, or resumes a suspended coroutine.
---@param cor any The coroutine, as created by cocreate().
---@param ... any The arguments to pass to the coroutine's function or the coroutine's subsequent yields.
function coresume(cor, ...) end

--- `cos( angle )`
---
--- Calculates the cosine of an angle.
---@param angle any The angle, using a full circle range of 0.0-1.0.
function cos(angle) end

--- `costatus( cor )`
---
--- Tests a coroutine and returns a string representing its status.
---@param cor any The coroutine to test.
function costatus(cor) end

--- `count( tbl, [v] )`
---
--- Returns the length of a table, or the number of instances of a value within a table.
---@param tbl any The table.
---@param v? any Value to count occurrences of.
function count(tbl, v) end

--- `yield( ... )`
---@param ... any
function coyield(...) end

--- `cstore( destaddr, sourceaddr, len, [filename] )`
---
--- Store a region of memory in the cartridge file, or another cartridge file.
---@param destaddr any The address of the first byte of the destination in the cartridge.
---@param sourceaddr any The address of the first byte in memory to copy.
---@param len any The length of the memory region to copy, as a number of bytes.
---@param filename? any If specified, the filename of a cartridge to which data is written. The default is to write to the currently loaded cartridge.
function cstore(destaddr, sourceaddr, len, filename) end

--- `cursor( [x,] [y,] [col] )`
---
--- Sets the left-margin cursor position for print().
---@param x? any The x coordinate of the upper left corner of the line. The default is 0.
---@param y? any The y coordinate of the upper left corner of the line. The default is 0.
---@param col? any (Optional) The palette index to set the pen color to.
---@return any # An x,y,c tuple representing the previous cursor position and color.
function cursor(x, y, col) end

--- `del( table, value )`
---
--- Deletes the first occurrence of a value from a sequence in a table.
---@param table any The table.
---@param value any The value to match and remove.
function del(table, value) end

--- `deli( table, [index] )`
---
--- Removes the element at the given index of a sequence in a table.
---@param table any The table.
---@param index? any The index for the value to be removed.
function deli(table, index) end

--- `dget( index )`
---
--- Gets a value from persistent cartridge data.
---@param index any The index of the value, 0 to 63.
function dget(index) end

--- `dset( index, value )`
---
--- Sets a value in persistent cartridge data.
---@param index any The index of the value.
---@param value any The new value to set.
function dset(index, value) end

--- `extcmd( cmd )`
---
--- Executes an administrative command from within a program.
---@param cmd any
function extcmd(cmd) end

--- `fget( n, [f] )`
---
--- Gets the value of a flag of a sprite.
---@param n any The sprite number.
---@param f? any The flag index (0-7). If omitted, a bit field of all flags is returned.
function fget(n, f) end

--- `fillp( [pat] )`
---
--- Sets the fill pattern.
---@param pat? any A bitfield representing the fill pattern to use.
function fillp(pat) end

--- `flip( )`
---
--- Copies the graphics buffer to the screen, then synchronizes to the next frame at 30 frames per second.
function flip() end

--- `flr( num )`
---
--- Returns the nearest integer at or below a number (its "floor").
---@param num any The number.
---@return any # The nearest integer at or below num.
function flr(num) end

--- `foreach( tbl, func )`
---
--- Calls a function for each element in a sequence in a table.
---@param tbl any The table.
---@param func any The function to call. The function should accept an element as its sole argument.
function foreach(tbl, func) end

--- `fset( n, [f,] v )`
---
--- Sets the value of a flag of a sprite.
---@param n any The sprite number.
---@param f? any The flag index (0-7). If omitted, a bit field of all flags is returned.
---@param v any The value, either true or false if the flag index is specified, or the bit field of all flags if it is not.
function fset(n, f, v) end

--- `getmetatable( tbl )`
---
--- Gets the metatable for a table.
---@param tbl any The table.
function getmetatable(tbl) end

--- `inext( tbl, [i] )`
---
--- Iterator used by ipairs().
---@param tbl any
---@param i? any
function inext(tbl, i) end

--- `info( )`
---
--- Print out some information about the cartridge, including code size, tokens, and compressed size.
function info() end

--- `ipairs( tbl )`
---@param tbl any
function ipairs(tbl) end

--- `line( [x0,] [y0,] [x1,] [y1,] [color] )`
---
--- Draws a line between two points.
---@param x0? any The x coordinate of the start of the line. If omitted, the x coordinate of the end of the previous line is used, or 0 if no previous line has been drawn.
---@param y0? any The y coordinate of the start of the line. If omitted, the y coordinate of the end of the previous line is used, or 0 if no previous line has been drawn.
---@param x1? any The x coordinate of the end of the line.
---@param y1? any The y coordinate of the end of the line.
---@param color? any The color of the line. If omitted, the color from the draw state is used. This also sets the color in the draw state.
function line(x0, y0, x1, y1, color) end

--- `load( filename, [breadcrumb], [param] )`
---
--- Loads a cartridge, completely replacing the current cart in memory and beginning to execute immediately.
---@param filename any Either the name of the cartridge file, a BBS cart ID in the form "#mycartid123", or "@clip" to load a cartridge from the system clipboard copied from the BBS.
---@param breadcrumb? any Adds an item to the pause menu to return to the original cart.
---@param param? any An arbitrary string value that can be accessed by the loaded cart using stat(6).
function load(filename, breadcrumb, param) end

--- `lshr( num, bits )`
---
--- Shifts the bits of a number to the right, using logical shift.
---@deprecated
---@param num any The number.
---@param bits any The number of bits to shift.
function lshr(num, bits) end

--- `map( celx, cely, sx, sy, celw, celh, [layer] )`
---
--- Draws a portion of the map to the graphics buffer.
---@param celx any The column location of the map cell in the upper left corner of the region to draw, where 0 is the leftmost column.
---@param cely any The row location of the map cell in the upper left corner of the region to draw, where 0 is the topmost row.
---@param sx any The x coordinate of the screen to place the upper left corner.
---@param sy any The y coordinate of the screen to place the upper left corner.
---@param celw any The number of map cells wide in the region to draw.
---@param celh any The number of map cells tall in the region to draw.
---@param layer? any If specified, only draw sprites that have flags set for every bit in this value (a bitfield). The default is 0 (draw all sprites).
function map(celx, cely, sx, sy, celw, celh, layer) end

--- `max( first, [second] )`
---
--- Returns the maximum of two numbers.
---@param first any The first number.
---@param second? any The second number. (default 0)
function max(first, second) end

--- `memcpy( destaddr, sourceaddr, len )`
---
--- Copies a region of memory to another location in memory.
---@param destaddr any The address of the first byte of the destination.
---@param sourceaddr any The address of the first byte of the memory to copy.
---@param len any The length of the memory region to copy, as a number of bytes.
function memcpy(destaddr, sourceaddr, len) end

--- `memset( destaddr, val, len )`
---
--- Writes a byte value to every address in a region of memory.
---@param destaddr any The address of the first memory location to write.
---@param val any The byte value to write.
---@param len any The length of the region of memory to write, as a number of bytes.
function memset(destaddr, val, len) end

--- `menuitem( index, [label,] [callback] )`
---
--- Adds a custom item to the PICO-8 menu.
---@param index any The item index, a number between 1 and 5.
---@param label? any The label text of the menu item to add or change.
---@param callback? any A Lua function to call when the user selects this menu item.
function menuitem(index, label, callback) end

--- `mget( celx, cely )`
---
--- Gets the sprite number assigned to a cell on the map.
---@param celx any The column (x) coordinate of the cell.
---@param cely any The row (y) coordinate of the cell.
function mget(celx, cely) end

--- `mid( first, second, third )`
---
--- Returns the middle of three numbers. Also useful for clamping.
---@param first any The first number.
---@param second any The second number.
---@param third any The third number.
function mid(first, second, third) end

--- `min( first, [second] )`
---
--- Returns the minimum of two numbers.
---@param first any The first number.
---@param second? any The second number. (default 0)
function min(first, second) end

--- `mset( celx, cely, snum )`
---
--- Sets a cell on the map to a new sprite number.
---@param celx any The column (x) coordinate of the cell.
---@param cely any The row (y) coordinate of the cell.
---@param snum any The new sprite number to store.
function mset(celx, cely, snum) end

--- `music( [n,] [fade_len,] [channel_mask] )`
---
--- Plays a music pattern, or stops playing.
---@param n? any The pattern number to start playing (0-63), or -1 to stop playing music.
---@param fade_len? any
---@param channel_mask? any
function music(n, fade_len, channel_mask) end

--- `next( tbl, [key] )`
---
--- A stateless iterator of key-value pairs for all elements in a table.
---@param tbl any The table.
---@param key? any The current key.
function next(tbl, key) end

--- `ord( str, [index] )`
---
--- Gets the ordinal (numeric) version of a character in a string.
---@param str any The string whose character is to be converted to an ordinal.
---@param index? any The index of the character in the string. Default is 1, the first character.
---@return any # The ordinal value of the character at index in str
function ord(str, index) end

--- `oval( x0, y0, x1, y1, [col] )`
---
--- Draws an empty oval shape.
---@param x0 any The x coordinate of the upper left corner.
---@param y0 any The y coordinate of the upper left corner.
---@param x1 any The x coordinate of the lower right corner.
---@param y1 any The y coordinate of the lower right corner.
---@param col? any The color of the oval's border. If omitted, the color from the draw state is used.
function oval(x0, y0, x1, y1, col) end

--- `ovalfill( x0, y0, x1, y1, [col] )`
---
--- Draws a filled oval shape.
---@param x0 any The x coordinate of the upper left corner.
---@param y0 any The y coordinate of the upper left corner.
---@param x1 any The x coordinate of the lower right corner.
---@param y1 any The y coordinate of the lower right corner.
---@param col? any The color of the oval. If omitted, the color from the draw state is used.
function ovalfill(x0, y0, x1, y1, col) end

--- `pack( ... )`
---
--- Creates a table from the given parameters.
---@param ... any parameters
function pack(...) end

--- `pairs( tbl )`
---
--- Returns an iterator of key-value pairs for all elements in a table, for use with for...in.
---@param tbl any The table.
function pairs(tbl) end

--- `pal( c0, c1, [p] )`
---
--- Changes the draw state so all instances of a given color are replaced with a new color.
---@param c0 any The number of the original color to replace.
---@param c1 any The number of the new color to use instead.
---@param p? any 0 to modify the palette used by draw operations, 1 to modify the palette for the screen already drawn, or 2 to modify the secondary screen palette. The default is 0.
function pal(c0, c1, p) end

--- `palt( [col,] [t] )`
---
--- Change the transparency of a color in the draw state for subsequent draw calls.
---@param col? any The number of the color to modify.
---@param t? any If true, treat this color as transparent. If false, treat this color as opaque.
function palt(col, t) end

--- `peek( addr, [n] )`
---
--- Reads one or more bytes from contiguous memory locations starting at addr.
---@param addr any The address of the first memory location.
---@param n? any The number of bytes to return. (1 by default, 8192 max.)
function peek(addr, n) end

--- `peek2( addr, [n] )`
---
--- Reads one or more 16-bit values from contiguous groups of two consecutive memory locations.
---@param addr any The address of the first memory location.
---@param n? any The number of values to return. (1 by default, 8192 max.)
function peek2(addr, n) end

--- `peek4( addr, [n] )`
---
--- Reads one or more 32-bit fixed-point number values from contiguous groups of four consecutive memory locations.
---@param addr any The address of the first memory location.
---@param n? any The number of values to return. (1 by default, 8192 max.)
function peek4(addr, n) end

--- `pget( x, y )`
---
--- Gets the color value of a pixel at the given coordinates.
---@param x any The x coordinate.
---@param y any The y coordinate.
function pget(x, y) end

--- `poke( addr, [value,] [...] )`
---
--- Writes one or more bytes to contiguous memory locations.
---@param addr any The address of the first memory location.
---@param value? any The byte value to write to memory. Defaults to 0.
---@param ... any Additional byte values to be written consecutively to memory.
function poke(addr, value, ...) end

--- `poke2( addr, [...] )`
---
--- Writes one or more 16-bit values to contiguous groups of two consecutive memory locations.
---@param addr any The address of the first memory location.
---@param ... any The 16-bit values to write to memory. If these are omitted, a zero is written to the first 2 bytes.
function poke2(addr, ...) end

--- `poke4( addr, [...] )`
---
--- Writes one or more 32-bit fixed-point PICO-8 number values to contiguous groups of four consecutive memory locations.
---@param addr any The address of the first memory location.
---@param ... any The 32-bit values to write to memory. If these are omitted, a zero is written to the first 4 bytes.
function poke4(addr, ...) end

--- `print( text, [x,] [y,] [color] )`
---
--- Prints a string of characters to the screen.
---@param text any The Lua string of characters to print.
---@param x? any The x coordinate of the upper left corner to start printing.
---@param y? any The y coordinate of the upper left corner to start printing.
---@param color? any The color to use for the text.
---@return any # The x coordinate of the next character to be printed (can be used to calculate printed width)
function print(text, x, y, color) end

--- `printh( str, [filename,] [overwrite] )`
---
--- Prints a string to a console window that is running PICO-8, or to a file or the clipboard.
---@param str any The string to print.
---@param filename? any The name of a file to append the output, instead of printing to the console. If this is the string "@clip", the message replaces the contents of the system clipboard instead of writing to a file.
---@param overwrite? any If filename is provided and is the name of a file and overwrite is true, this overwrites the file. The default is false, which appends the message to the end of the file.
function printh(str, filename, overwrite) end

--- `pset( x, y, [c] )`
---
--- Sets a pixel in the graphics buffer.
---@param x any The x coordinate.
---@param y any The y coordinate.
---@param c? any The color value. If not specified, uses the current color of the draw state.
function pset(x, y, c) end

--- `rawequal( a, b )`
---
--- Compares a and b without calling metamethods.
---@param a any
---@param b any
function rawequal(a, b) end

--- `rawget( tbl, member )`
---
--- Read a table member, bypassing metamethods
---@param tbl any The table whose member to read.
---@param member any The member to read.
function rawget(tbl, member) end

--- `rawlen( tbl )`
---
--- Get the length of a table, bypassing metamethods
---@param tbl any The table whose length to retrieve.
function rawlen(tbl) end

--- `rawset( tbl, member, value )`
---
--- Write to a table member, bypassing metamethods
---@param tbl any The table whose member to modify.
---@param member any The member to modify.
---@param value any The member's new value.
function rawset(tbl, member, value) end

--- `rect( x0, y0, x1, y1, [col] )`
---
--- Draws an empty rectangle shape.
---@param x0 any The x coordinate of the upper left corner.
---@param y0 any The y coordinate of the upper left corner.
---@param x1 any The x coordinate of the lower right corner.
---@param y1 any The y coordinate of the lower right corner.
---@param col? any The color of the rectangle border. If omitted, the color from the draw state is used.
function rect(x0, y0, x1, y1, col) end

--- `rectfill( x0, y0, x1, y1, [col] )`
---
--- Draws a filled-in rectangle shape.
---@param x0 any The x coordinate of the upper left corner.
---@param y0 any The y coordinate of the upper left corner.
---@param x1 any The x coordinate of the lower right corner.
---@param y1 any The y coordinate of the lower right corner.
---@param col? any The color of the rectangle and fill. If omitted, the color from the draw state is used.
function rectfill(x0, y0, x1, y1, col) end

--- `reload( destaddr, sourceaddr, len, [filename] )`
---
--- Loads a region of data from the cartridge, or from another cartridge, into memory.
---@param destaddr any The address of the first byte of the destination in memory.
---@param sourceaddr any The address of the first byte in the cartridge data.
---@param len any The length of the memory region to copy, as a number of bytes.
---@param filename? any If specified, the filename of a cartridge from which to read data. The default is to read from the currently loaded cartridge.
function reload(destaddr, sourceaddr, len, filename) end

--- `reset( )`
---
--- Reset the values in RAM from 0x5f00..0x5f7f to their default values. This includes the palette, camera position, clipping, and fill pattern.
function reset() end

--- `rnd( [max] )`
---
--- Generates a random number between 0 and the given maximum exclusive, or returns a random element from a 1-based table sequence.
---@param max? any The range, non-inclusive. Defaults to 1.
function rnd(max) end

--- `rotl( num, bits )`
---
--- Rotates the bits of a number to the left.
---@deprecated
---@param num any The number.
---@param bits any The number of bits to rotate.
function rotl(num, bits) end

--- `rotr( num, bits )`
---
--- Rotates the bits of a number to the right.
---@deprecated
---@param num any The number.
---@param bits any The number of bits to rotate.
function rotr(num, bits) end

--- `rrect( x, y, w, h, r, [col] )`
---
--- Draws an empty rectangle shape with rounded corners.
---@param x any The x coordinate of the upper left corner.
---@param y any The y coordinate of the upper left corner.
---@param w any The width of the rounded rectangle, in pixels.
---@param h any The height of the rounded rectangle, in pixels.
---@param r any The size of the quarter-circle to be drawn at each corner. The maximum radius is min(width, height)/2. Default is 0.
---@param col? any The color of the rounded rectangle border. If omitted, the color from the draw state is used.
function rrect(x, y, w, h, r, col) end

--- `rrectfill( x, y, w, h, r, [col] )`
---
--- Draws a filled-in rectangle shape with rounded corners.
---@param x any The x coordinate of the upper left corner.
---@param y any The y coordinate of the upper left corner.
---@param w any The width of the rounded rectangle, in pixels.
---@param h any The height of the rounded rectangle, in pixels.
---@param r any The size of the quarter-circle to be drawn at each corner. The maximum radius is min(width, height)/2. Default is 0.
---@param col? any The color of the rounded rectangle and fill. If omitted, the color from the draw state is used.
function rrectfill(x, y, w, h, r, col) end

--- `run( [str] )`
---
--- Runs the current cartridge from the start of the program.
---@param str? any A "breadcrumb" string, as if passed by a calling cartridge.
function run(str) end

--- `select( index, ... )`
---
--- Selects from the given parameters.
---@param index any Index to return parameters from, or '#' to return number of parameters
---@param ... any parameters
function select(index, ...) end

--- `serial( channel, address, length)`
---
--- Buffers and dispatches GPIO writes at the end of each frame, allowing clock cycling at higher and/or more regular speeds than is possible by manually bit-banging using poke() calls.
---@param channel any the channel to fread from/write to
---@param address any the PICO-8 memory location to read from/write to.
---@param length any number of bytes to send. 1/8ths are allowed to send partial bit strings.
function serial(channel, address, length) end

--- `setmetatable( tbl, metatbl )`
---
--- Updates the metatable for a table.
---@param tbl any The table whose metatable to modify.
---@param metatbl any The new metatable.
---@return any # The same tbl that was passed in.
function setmetatable(tbl, metatbl) end

--- `sfx( n, [channel,] [offset,] [length] )`
---
--- Plays a sound effect.
---@param n any The number of the sound effect to play (0-63), -1 to stop playing sound on the given channel, or -2 to release the sound of the given channel from looping.
---@param channel? any The channel to use for the sound effect (0-3). The default is -1, which chooses an available channel automatically. Can be -2 to stop playing the given sound effect on any channels it plays on.
---@param offset? any The note position in the sound effect to start playing (0-31). The default is 0 (the beginning).
---@param length? any The number of notes in the sound effect to play (0-31). The default is to play the entire sound effect.
function sfx(n, channel, offset, length) end

--- `sget( x, y )`
---
--- Gets the color value of a pixel on the sprite sheet.
---@param x any The x coordinate on the sprite sheet.
---@param y any The y coordinate on the sprite sheet.
function sget(x, y) end

--- `sgn( [number] )`
---
--- Returns the sign of a number, 1 for positive, -1 for negative
---@param number? any The number to determine the sign of.
function sgn(number) end

--- `shl( num, bits )`
---
--- Shifts the bits of a number to the left.
---@deprecated
---@param num any The number.
---@param bits any The number of bits to shift.
function shl(num, bits) end

--- `shr( num, bits )`
---
--- Shifts the bits of a number to the right.
---@deprecated
---@param num any The number.
---@param bits any The number of bits to shift.
function shr(num, bits) end

--- `sin( angle )`
---
--- Calculates the sine of an angle.
---@param angle any The angle, using a full circle range of 0.0-1.0 measured clockwise (0.0 to the right).
function sin(angle) end

--- `split( str, [separator,] [convert_numbers] )`
---
--- Split a string into a table of elements delimited by the given separator (defaults to ",").
---@param str any The string.
---@param separator? any The separator (defaults to ",").
---@param convert_numbers? any When convert_numbers is true, numerical tokens are stored as numbers (defaults to true).
function split(str, separator, convert_numbers) end

--- `spr( n, x, y, [w,] [h,] [flip_x,] [flip_y] )`
---
--- Draws a sprite, or a range of sprites, on the screen.
---@param n any The sprite number. When drawing a range of sprites, this is the upper-left corner.
---@param x any The x coordinate.
---@param y any The y coordinate.
---@param w? any The width of the range, as a number of sprites. Non-integer values may be used to draw partial sprites. The default is 1.0.
---@param h? any The height of the range, as a number of sprites. Non-integer values may be used to draw partial sprites. The default is 1.0.
---@param flip_x? any If true, the sprite is drawn inverted left to right. The default is false.
---@param flip_y? any If true, the sprite is drawn inverted top to bottom. The default is false.
function spr(n, x, y, w, h, flip_x, flip_y) end

--- `sqrt( num )`
---
--- Calculates the square root of a number.
---@param num any The number. Must be positive.
function sqrt(num) end

--- `srand( val )`
---
--- Initializes the random number generator with an explicit seed value.
---@param val any The seed value.
function srand(val) end

--- `sset( x, y, [c] )`
---
--- Sets the color value of a pixel on the sprite sheet.
---@param x any The x coordinate on the sprite sheet.
---@param y any The y coordinate on the sprite sheet.
---@param c? any The color value to set. If unspecified, the color of the current draw state will be used.
function sset(x, y, c) end

--- `sspr( sx, sy, sw, sh, dx, dy, [dw,] [dh,] [flip_x,] [flip_y] )`
---
--- Draws a rectangle of pixels from the sprite sheet, optionally stretching the image to fit a rectangle on the screen.
---@param sx any The x coordinate of the upper left corner of the rectangle in the sprite sheet.
---@param sy any The y coordinate of the upper left corner of the rectangle in the sprite sheet.
---@param sw any The width of the rectangle in the sprite sheet, as a number of pixels.
---@param sh any The height of the rectangle in the sprite sheet, as a number of pixels.
---@param dx any The x coordinate of the upper left corner of the rectangle area of the screen.
---@param dy any The y coordinate of the upper left corner of the rectangle area of the screen.
---@param dw? any The width of the rectangle area of the screen. The default is to match the image width (sw).
---@param dh? any The height of the rectangle area of the screen. The default is to match the image height (sh).
---@param flip_x? any If true, the image is drawn inverted left to right. The default is false.
---@param flip_y? any If true, the image is drawn inverted top to bottom. The default is false.
function sspr(sx, sy, sw, sh, dx, dy, dw, dh, flip_x, flip_y) end

--- `stat( n )`
---
--- Returns information about the current runtime environment.
---@param n any The ID of the information to return.
function stat(n) end

--- `stop( [message,] [x,] [y,] [col] )`
---
--- Stops the program's execution and returns to the command prompt.
---@param message? any An optional message to print before stopping.
---@param x? any The x coordinate of the upper left corner to start printing.
---@param y? any The y coordinate of the upper left corner to start printing.
---@param col? any The color to use for the text.
function stop(message, x, y, col) end

--- `sub( str, start, [end] )`
---
--- Gets the substring of a string.
---@param str any The string.
---@param start any The starting index, counting from 1 at the left, or -1 at the right.
---@param end_? any The ending index, counting from 1 at the left, or -1 at the right. (default -1)
function sub(str, start, end_) end

--- `t( )`
---
--- Returns the amount of time since PICO-8 was last started, as a (fractional) number of seconds.
function t() end

--- `time( )`
---
--- Returns the amount of time since PICO-8 was last started, as a (fractional) number of seconds.
function time() end

--- `tline( x0, y0, x1, y1, mx, my, [mdx,] [mdy,] [layers] )`
---
--- Draws a textured line between two points, sampling the map for texture data.
---@param x0 any The x coordinate of the start of the line.
---@param y0 any The y coordinate of the start of the line.
---@param x1 any The x coordinate of the end of the line.
---@param y1 any The y coordinate of the end of the line.
---@param mx any The x coordinate to begin sampling the map, expressed in (fractional) map tiles.
---@param my any The y coordinate to begin sampling the map, expressed in (fractional) map tiles.
---@param mdx? any The amount to add to mx after each pixel is drawn, expressed in (fractional) map tiles. Default is 1/8 (move right one map pixel).
---@param mdy? any The amount to add to mx after each pixel is drawn, expressed in (fractional) map tiles. Default is 0 (a horizontal line).
---@param layers? any
function tline(x0, y0, x1, y1, mx, my, mdx, mdy, layers) end

--- `tonum( str )`
---
--- Converts a string representation of a decimal, hexadecimal, or binary number to a number value.
---@param str any The string.
function tonum(str) end

--- `tostr( val, [usehex] )`
---
--- Converts a non-string value to a string representation.
---@param val any The value to convert.
---@param usehex? any If true, uses 32-bit unsigned fixed point hexadecimal notation for number values. The default is to use concise decimal notation for number values.
function tostr(val, usehex) end

--- `tostring( val )`
---
--- Converts a non-string value to a string representation.
---@param val any The value to convert.
function tostring(val) end

--- `trace( [coroutine,] [message,] [skip] )`
---
--- Returns a description of the current call stack as a string.
---@param coroutine? any Optionally get the stack trace for a coroutine. Defaults to the current one or the main thread.
---@param message? any Adds the given string to the top of the trace report. Defaults to blank.
---@param skip? any Number of levels of the stack to skip. Defaults to 1, to skip the trace() call's own level.
function trace(coroutine, message, skip) end

--- `type( value )`
---
--- Returns the basic type of a given value as a string.
---@param value any The value whose type to test.
function type(value) end

--- `unpack( tbl, [i,] [j] )`
---
--- Returns the elements from the given table.
---@param tbl any The table to unpack.
---@param i? any First index to unpack. Default is 1.
---@param j? any Last index to unpack. Default is #tbl.
function unpack(tbl, i, j) end

--- `yield( [...] )`
---
--- Yields control back to the caller from within a coroutine.
---@param ... any Arguments to be passed to the coresume() that resumed its coroutine.
function yield(...) end
