---@meta picotron
-- Picotron's API for lua-language-server: hover docs, completion and
-- "undefined global" warnings in Zed. Only used for completion, never run.
-- Hand-written from the Picotron manual, so it's not every function: if Zed
-- warns about one Picotron has, add a line here.

-- Graphics

--- Clears the draw target to col (default 0).
---@param col? any
function cls(col) end
--- Sets one pixel.
---@param x? any
---@param y? any
---@param col? any
function pset(x, y, col) end
--- Returns the colour of one pixel.
---@param x? any
---@param y? any
function pget(x, y) end
--- Returns a pixel from the sprite sheet.
---@param x? any
---@param y? any
function sget(x, y) end
--- Sets a pixel in the sprite sheet.
---@param x? any
---@param y? any
---@param col? any
function sset(x, y, col) end
--- Returns sprite n's flag f, or all flags as a bitfield.
---@param n? any
---@param f? any
function fget(n, f) end
--- Sets sprite n's flag f.
---@param n? any
---@param f? any
---@param val? any
function fset(n, f, val) end
--- Prints str at x,y (or the cursor). Returns the x after the text.
---@param str? any
---@param x? any
---@param y? any
---@param col? any
function print(str, x, y, col) end
--- Sets the print cursor and colour.
---@param x? any
---@param y? any
---@param col? any
function cursor(x, y, col) end
--- Sets the draw colour.
---@param col? any
function color(col) end
--- Limits drawing to a rectangle. No arguments resets it.
---@param x? any
---@param y? any
---@param w? any
---@param h? any
---@param clip_previous? any
function clip(x, y, w, h, clip_previous) end
--- Offsets everything drawn after it by -x,-y.
---@param x? any
---@param y? any
function camera(x, y) end
--- Swaps colour c0 for c1. p 0 = draw palette, 1 = display palette.
---@param c0? any
---@param c1? any
---@param p? any
function pal(c0, c1, p) end
--- Makes colour c transparent (t true) or opaque for sprites.
---@param c? any
---@param t? any
function palt(c, t) end
--- Sets the fill pattern.
---@param p? any
function fillp(p) end
--- Draws sprite s (an index or a userdata) at x,y.
---@param s? any
---@param x? any
---@param y? any
---@param flip_x? any
---@param flip_y? any
function spr(s, x, y, flip_x, flip_y) end
--- Draws (and stretches) a part of sprite s.
---@param s? any
---@param sx? any
---@param sy? any
---@param sw? any
---@param sh? any
---@param dx? any
---@param dy? any
---@param dw? any
---@param dh? any
---@param flip_x? any
---@param flip_y? any
function sspr(s, sx, sy, sw, sh, dx, dy, dw, dh, flip_x, flip_y) end
--- Returns sprite index as userdata.
---@param index? any
function get_spr(index) end
--- Replaces sprite index with userdata s.
---@param index? any
---@param s? any
---@param flags_val? any
function set_spr(index, s, flags_val) end
--- Draws a line. With fewer arguments it continues the last one.
---@param x0? any
---@param y0? any
---@param x1? any
---@param y1? any
---@param col? any
function line(x0, y0, x1, y1, col) end
--- Rectangle outline.
---@param x0? any
---@param y0? any
---@param x1? any
---@param y1? any
---@param col? any
function rect(x0, y0, x1, y1, col) end
--- Filled rectangle.
---@param x0? any
---@param y0? any
---@param x1? any
---@param y1? any
---@param col? any
function rectfill(x0, y0, x1, y1, col) end
--- Rounded rectangle outline.
---@param x? any
---@param y? any
---@param w? any
---@param h? any
---@param r? any
---@param col? any
function rrect(x, y, w, h, r, col) end
--- Filled rounded rectangle.
---@param x? any
---@param y? any
---@param w? any
---@param h? any
---@param r? any
---@param col? any
function rrectfill(x, y, w, h, r, col) end
--- Circle outline.
---@param x? any
---@param y? any
---@param r? any
---@param col? any
function circ(x, y, r, col) end
--- Filled circle.
---@param x? any
---@param y? any
---@param r? any
---@param col? any
function circfill(x, y, r, col) end
--- Oval outline inside the box.
---@param x0? any
---@param y0? any
---@param x1? any
---@param y1? any
---@param col? any
function oval(x0, y0, x1, y1, col) end
--- Filled oval inside the box.
---@param x0? any
---@param y0? any
---@param x1? any
---@param y1? any
---@param col? any
function ovalfill(x0, y0, x1, y1, col) end
--- Draws a map (the first argument may be left out for the current one).
---@param tile_map? any
---@param tx? any
---@param ty? any
---@param sx? any
---@param sy? any
---@param tiles_x? any
---@param tiles_y? any
---@param p8layers? any
---@param tile_w? any
---@param tile_h? any
function map(tile_map, tx, ty, sx, sy, tiles_x, tiles_y, p8layers, tile_w, tile_h) end
--- Returns the tile at x,y in the current map.
---@param x? any
---@param y? any
function mget(x, y) end
--- Sets the tile at x,y in the current map.
---@param x? any
---@param y? any
---@param val? any
function mset(x, y, val) end
--- Draws a textured line.
---@param src? any
---@param x0? any
---@param y0? any
---@param x1? any
---@param y1? any
---@param u0? any
---@param v0? any
---@param u1? any
---@param v1? any
---@param w0? any
---@param w1? any
---@param flags? any
function tline3d(src, x0, y0, x1, y1, u0, v0, u1, v1, w0, w1, flags) end
--- Copies a rectangle between userdata (nil = the display).
---@param src? any
---@param dest? any
---@param sx? any
---@param sy? any
---@param dx? any
---@param dy? any
---@param w? any
---@param h? any
function blit(src, dest, sx, sy, dx, dy, w, h) end
--- Draws into userdata ud from now on; no argument = the display.
---@param ud? any
function set_draw_target(ud) end
--- Returns the current draw target.
function get_draw_target() end
--- Returns the display as userdata.
function get_display() end
--- Sets the display userdata.
---@param ud? any
function set_display(ud) end
--- Sets the video mode (0 = 480x270, 3 = 240x135, 4 = 160x90).
---@param mode? any
function vid(mode) end
--- Creates or changes the program's window ({width=, height=, title=, ...}).
---@param attribs? any
function window(attribs) end

-- Input

--- Is button b held? No arguments returns a bitfield.
---@param b? any
---@param pl? any
function btn(b, pl) end
--- Was button b just pressed (with repeat)?
---@param b? any
---@param pl? any
function btnp(b, pl) end
--- Is key k (a name like "space" or "a") held?
---@param k? any
---@param raw? any
function key(k, raw) end
--- Was key k just pressed?
---@param k? any
---@param raw? any
---@param allow_repeat? any
function keyp(k, raw, allow_repeat) end
--- Is there typed text waiting?
function peektext() end
--- Returns the next typed character, or nil.
---@param clear? any
function readtext(clear) end
--- Returns x, y, buttons, wheel_x, wheel_y.
function mouse() end

-- Audio

--- Plays sound effect n (-1 stops).
---@param n? any
---@param channel? any
---@param offset? any
---@param length? any
---@param mix_volume? any
function sfx(n, channel, offset, length, mix_volume) end
--- Plays music pattern n (-1 stops).
---@param n? any
---@param fade_len? any
---@param channel_mask? any
---@param base_addr? any
function music(n, fade_len, channel_mask, base_addr) end
--- Plays a single note.
---@param ... any
function note(...) end

-- Memory

--- Reads n bytes.
---@param addr? any
---@param n? any
function peek(addr, n) end
--- Reads 16-bit values.
---@param addr? any
---@param n? any
function peek2(addr, n) end
--- Reads 32-bit values.
---@param addr? any
---@param n? any
function peek4(addr, n) end
--- Reads 64-bit values.
---@param addr? any
---@param n? any
function peek8(addr, n) end
--- Writes bytes.
---@param addr? any
---@param ... any
function poke(addr, ...) end
--- Writes 16-bit values.
---@param addr? any
---@param ... any
function poke2(addr, ...) end
--- Writes 32-bit values.
---@param addr? any
---@param ... any
function poke4(addr, ...) end
--- Writes 64-bit values.
---@param addr? any
---@param ... any
function poke8(addr, ...) end
--- Copies memory.
---@param dest? any
---@param src? any
---@param len? any
function memcpy(dest, src, len) end
--- Fills memory.
---@param dest? any
---@param val? any
---@param len? any
function memset(dest, val, len) end
--- Maps userdata ud to memory at addr.
---@param ud? any
---@param addr? any
function memmap(ud, addr) end
--- Undoes memmap.
---@param ud? any
---@param addr? any
function unmap(ud, addr) end

-- Files

--- Loads a Lua value from a file (pod, png, lua text...).
---@param filename? any
function fetch(filename) end
--- Saves a Lua value to a file.
---@param filename? any
---@param obj? any
---@param metadata? any
function store(filename, obj, metadata) end
--- Returns a file's metadata table.
---@param filename? any
function fetch_metadata(filename) end
--- Sets a file's metadata.
---@param filename? any
---@param metadata? any
function store_metadata(filename, metadata) end
--- Lists a folder.
---@param path? any
function ls(path) end
--- Changes the present working directory.
---@param path? any
function cd(path) end
--- Returns the present working directory.
function pwd() end
--- Makes a folder.
---@param path? any
function mkdir(path) end
--- Deletes a file or folder.
---@param path? any
function rm(path) end
--- Copies a file or folder (also into and out of carts).
---@param src? any
---@param dest? any
function cp(src, dest) end
--- Moves a file or folder.
---@param src? any
---@param dest? any
function mv(src, dest) end
--- Returns "file", "folder" or nil, plus size.
---@param path? any
function fstat(path) end
--- Resolves a relative path.
---@param path? any
function fullpath(path) end
--- Runs a .lua file, relative to the present working directory.
---@param filename? any
function include(filename) end
--- Mounts target at location.
---@param location? any
---@param target? any
function mount(location, target) end

-- Processes

--- Starts a program, returns its pid.
---@param prog_name? any
---@param env_patch? any
function create_process(prog_name, env_patch) end
--- Returns this process's id.
function pid() end
--- Sends a message table to a process.
---@param pid? any
---@param msg? any
function send_message(pid, msg) end
--- Calls func(msg) when event arrives.
---@param event? any
---@param func? any
function on_event(event, func) end
--- Returns this process's environment table.
function env() end
--- Ends this process.
---@param code? any
function exit(code) end
--- Stops the program.
function stop() end
--- Shows msg in the toolbar.
---@param msg? any
function notify(msg) end
--- Prints to the host terminal.
---@param str? any
function printh(str) end

-- Time and maths

--- Seconds since the program started.
function time() end
--- Same as time().
function t() end
--- Returns a date string.
---@param format? any
---@param t? any
---@param delta? any
function date(format, t, delta) end
--- Returns system information n.
---@param n? any
function stat(n) end
--- Random number from 0 to x, or a random element if x is a table.
---@param x? any
function rnd(x) end
--- Seeds rnd().
---@param x? any
function srand(x) end
--- Rounds down.
---@param x? any
function flr(x) end
--- Rounds up.
---@param x? any
function ceil(x) end
--- Absolute value.
---@param x? any
function abs(x) end
--- Sign: 1 or -1.
---@param x? any
function sgn(x) end
--- Smaller value.
---@param a? any
---@param b? any
function min(a, b) end
--- Larger value.
---@param a? any
---@param b? any
function max(a, b) end
--- Middle value.
---@param a? any
---@param b? any
---@param c? any
function mid(a, b, c) end
--- Square root.
---@param x? any
function sqrt(x) end
--- Sine; x is 0..1 for a full turn, y points down.
---@param x? any
function sin(x) end
--- Cosine; x is 0..1 for a full turn.
---@param x? any
function cos(x) end
--- Angle (0..1) of a vector.
---@param dx? any
---@param dy? any
function atan2(dx, dy) end

-- Tables and strings

--- Appends val (or inserts at index), returns val.
---@param tbl? any
---@param val? any
---@param index? any
function add(tbl, val, index) end
--- Removes the first val.
---@param tbl? any
---@param val? any
function del(tbl, val) end
--- Removes the value at index (default last).
---@param tbl? any
---@param index? any
function deli(tbl, index) end
--- Counts entries, or how many equal val.
---@param tbl? any
---@param val? any
function count(tbl, val) end
--- Iterator over the values of a sequence.
---@param tbl? any
function all(tbl) end
--- Calls func(v) for every value.
---@param tbl? any
---@param func? any
function foreach(tbl, func) end
--- Characters from codes.
---@param ... any
function chr(...) end
--- Codes from characters.
---@param str? any
---@param index? any
---@param num_results? any
function ord(str, index, num_results) end
--- Substring.
---@param str? any
---@param pos0? any
---@param pos1? any
function sub(str, pos0, pos1) end
--- Splits str into a table.
---@param str? any
---@param separator? any
---@param convert_numbers? any
function split(str, separator, convert_numbers) end
--- Value to string.
---@param val? any
---@param format_flags? any
function tostr(val, format_flags) end
--- String to number.
---@param val? any
---@param format_flags? any
function tonum(val, format_flags) end
--- Serialises a Lua value to a string.
---@param obj? any
---@param flags? any
---@param metadata? any
function pod(obj, flags, metadata) end
--- Reads a value back from pod().
---@param str? any
function unpod(str) end
--- Makes a typed 1D/2D array: "u8", "i16", "i32", "i64", "f64".
---@param type? any
---@param w? any
---@param h? any
---@param data? any
function userdata(type, w, h, data) end
--- Makes a f64 vector userdata.
---@param ... any
function vec(...) end

-- Coroutines

--- Makes a coroutine.
---@param func? any
function cocreate(func) end
--- Runs a coroutine until it yields.
---@param co? any
---@param ... any
function coresume(co, ...) end
--- "suspended", "running" or "dead".
---@param co? any
function costatus(co) end
--- Pauses the current coroutine.
---@param ... any
function yield(...) end

-- GUI

--- Makes a GUI root element (attach() children, call update_all and draw_all on it).
---@param attribs? any
function create_gui(attribs) end
