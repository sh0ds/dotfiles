-- PICO-8 for lua-language-server: turns what PICO-8 accepts into what the
-- language server can read, before it reads it. Your files stay untouched;
-- errors and hovers still point at the right place in them.
--
-- .p8 carts: everything outside __lua__ (the header, __gfx__, __map__,
-- __sfx__, ...) becomes a comment, so a whole cart opens without errors.
-- Everywhere (.p8 and .lua):
--   #include x.lua  ->  -- #include x.lua
--   if (a) b()      ->  if (a) then b() end     (same for while ... do)
--   ?"hi",8,8       ->  print("hi",8,8)
--   a\b  a\=b       ->  a//b  a//=b
--   // comment      ->  -- comment
--   a^^b  a^^=b     ->  a~ b  a|= b
--   >>>  <<>  >><   ->  >>   <<   >>
--   @addr  $addr    ->   addr  addr  (peek, peek4)
-- +=, != and friends are switched on in .luarc.json (runtime.nonstandardSymbol).

local function edit(diffs, start, finish, text)
  diffs[#diffs + 1] = { start = start, finish = finish, text = text }
end

-- Inserts text before position at. If something already changes the text
-- there, joins the two, since two edits at one spot could land in either order.
local function insert(diffs, at, text)
  for _, d in ipairs(diffs) do
    if d.start == at then
      d.text = text .. d.text
      return
    end
  end
  edit(diffs, at, at - 1, text)
end

-- Marks every byte of src that is code (not a string or comment) and
-- applies the operator swaps on the way. Returns the code mask.
local function scan(src, from, to, diffs)
  local code = {}
  local i = from
  local function long_bracket(at)
    local eq = src:match('^%[(=*)%[', at)
    if eq then return ']' .. eq .. ']', #eq + 2 end
  end
  while i <= to do
    local c = src:sub(i, i)
    local two = src:sub(i, i + 1)
    if two == '--' or two == '//' then
      if two == '//' then edit(diffs, i, i + 1, '--') end
      local close, len = long_bracket(i + 2)
      local stop
      if two == '--' and close then
        local _, e = src:find(close, i + 2 + len, true)
        stop = e or to
      else
        stop = (src:find('\n', i, true) or to + 1) - 1
      end
      i = stop + 1
    elseif c == '"' or c == "'" then
      local j = i + 1
      while j <= to do
        local d = src:sub(j, j)
        if d == '\\' then j = j + 1
        elseif d == c or d == '\n' then break end
        j = j + 1
      end
      code[i] = 'str' -- the opening quote: a value starts here
      i = j + 1
    elseif long_bracket(i) then
      local close, len = long_bracket(i)
      local _, e = src:find(close, i + len, true)
      code[i] = 'str'
      i = (e or to) + 1
    else
      code[i] = true
      if c == '\\' then
        edit(diffs, i, i, '//')
      elseif src:sub(i, i + 2) == '^^=' then
        edit(diffs, i, i + 2, '|= ')
        code[i + 1], code[i + 2] = true, true
        i = i + 2
      elseif two == '^^' then
        edit(diffs, i, i + 1, '~ ')
        code[i + 1] = true
        i = i + 1
      elseif src:sub(i, i + 3) == '>>>=' or src:sub(i, i + 3) == '>><=' then
        edit(diffs, i, i + 3, '>>= ')
        code[i + 1], code[i + 2], code[i + 3] = true, true, true
        i = i + 3
      elseif src:sub(i, i + 3) == '<<>=' then
        edit(diffs, i, i + 3, '<<= ')
        code[i + 1], code[i + 2], code[i + 3] = true, true, true
        i = i + 3
      elseif src:sub(i, i + 2) == '>>>' or src:sub(i, i + 2) == '>><' then
        edit(diffs, i, i + 2, '>> ')
        code[i + 1], code[i + 2] = true, true
        i = i + 2
      elseif src:sub(i, i + 2) == '<<>' then
        edit(diffs, i, i + 2, '<< ')
        code[i + 1], code[i + 2] = true, true
        i = i + 2
      elseif c == '@' or c == '$' then
        edit(diffs, i, i, ' ')
      end
      i = i + 1
    end
  end
  return code
end

-- Where a line's code ends: before a trailing comment, without spaces.
local function code_end(src, code, first, last)
  local e = first - 1
  for k = first, last do
    if code[k] and src:sub(k, k):match('%S') then e = k end
  end
  -- a string at the end counts too
  local k = e
  if code[e] == 'str' then
    local q = src:sub(e, e)
    if q == '"' or q == "'" then
      k = e + 1
      while k <= last and src:sub(k, k) ~= q do
        if src:sub(k, k) == '\\' then k = k + 1 end
        k = k + 1
      end
      e = math.min(k, last)
    else
      local close = ']' .. (src:match('^%[(=*)%[', e) or '') .. ']'
      local _, ce = src:find(close, e, true)
      e = ce or last
    end
  end
  return e
end

local function has_word(src, code, first, last, word)
  local at = first
  while true do
    local s, e = src:find('%f[%w_]' .. word .. '%f[^%w_]', at)
    if not s or s > last then return false end
    if code[s] then return true end
    at = e + 1
  end
end

-- if (cond) stmt / while (cond) stmt on one line, and ?expr.
local function shorthands(src, code, from, to, diffs)
  local line = from
  while line <= to do
    local nl = src:find('\n', line, true) or to + 1
    local last = math.min(nl - 1, to)
    local tail = {} -- text to add at the end of this line's code
    local s = src:find('%S', line)
    if s and s <= last and code[s] and src:find('^#include', s) then
      insert(diffs, s, '-- ') -- PICO-8 pastes the file in here; nothing to check
      line = nl + 1
      goto next_line
    end
    if s and s <= last and code[s] and src:sub(s, s) == '?' then
      edit(diffs, s, s, 'print(')
      tail[#tail + 1] = ')'
    end
    for _, kw in ipairs({ { 'if', 'then' }, { 'while', 'do' } }) do
      local at = line
      while true do
        local ks, ke = src:find('%f[%w_]' .. kw[1] .. '%s*%(', at)
        if not ks or ks > last then break end
        at = ke
        if code[ks] then
          local depth, k, close = 0, ke, nil
          while k <= last do
            if code[k] then
              local ch = src:sub(k, k)
              if ch == '(' then depth = depth + 1
              elseif ch == ')' then
                depth = depth - 1
                if depth == 0 then close = k break end
              end
            end
            k = k + 1
          end
          if close and not has_word(src, code, close + 1, last, kw[2]) then
            local rest = src:find('%S', close + 1)
            if rest and rest <= last and code[rest] then
              insert(diffs, close + 1, ' ' .. kw[2])
              tail[#tail + 1] = ' end'
            end
          end
          break -- one shorthand per line is all PICO-8 allows anyway
        end
      end
    end
    if #tail > 0 then
      local e = code_end(src, code, line, last)
      insert(diffs, e + 1, table.concat(tail))
    end
    line = nl + 1
    ::next_line::
  end
end

local function is_p8(uri)
  return uri:lower():sub(-3) == '.p8'
end

---@param uri string
---@param text string
function OnSetText(uri, text)
  local diffs = {}
  local from, to = 1, #text
  if is_p8(uri) then
    -- Comment out every line outside __lua__.
    local in_lua, code_from, code_to = false, nil, nil
    local pos = 1
    while pos <= #text do
      local nl = text:find('\n', pos, true) or #text + 1
      local l = text:sub(pos, nl - 1):gsub('\r$', '')
      local section = l:match('^__(%w+)__%s*$')
      if section then
        in_lua = section == 'lua'
        if in_lua then code_from = nl + 1 end
        if not in_lua and code_from and not code_to then code_to = pos - 1 end
        edit(diffs, pos, pos - 1, '-- ')
      elseif not in_lua and l ~= '' then
        edit(diffs, pos, pos - 1, '-- ')
      end
      pos = nl + 1
    end
    if not code_from then return diffs end
    from, to = code_from, code_to or #text
  end
  local code = scan(text, from, to, diffs)
  shorthands(text, code, from, to, diffs)
  return diffs
end
