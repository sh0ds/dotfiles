-- Run from the repo root: lua tests/test_firefox_pip.lua
local function setup()
  local windows, events, active, last = {}, {}, nil, nil
  hl = {
    dsp = { window = { move = function(args) return args end } },
    dispatch = function(args)
      local window = windows[args.window:sub(9)]
      assert(args.follow == false)
      if window then window.workspace = { name = args.workspace } end
    end,
    get_windows = function()
      local result = {}; for _, w in pairs(windows) do result[#result + 1] = w end; return result
    end,
    get_window = function(selector) return windows[selector:sub(9)] end,
    get_active_window = function() return active end,
    get_last_window = function() return last end,
    on = function(event, callback) events[event] = callback end,
  }
  local parent = { address = '0x1', pid = 50, class = 'firefox', title = '[1 tab] Video', workspace = { name = '2' } }
  local video = { address = '0x2', pid = 50, class = 'firefox', title = 'Picture-in-Picture', workspace = { name = '2' } }
  windows[parent.address], windows[video.address] = parent, video
  active, last = video, parent
  dofile('.config/hypr/firefox-pip.lua')
  return windows, events, parent, video, function(current, previous) active, last = current, previous end
end
local windows, events, parent, video = setup()
events['window.open'](video)
assert(parent.workspace.name == 'special:firefox-pip:2')
parent.title = '[2 tabs] Video'; events['window.title'](parent)
assert(parent.workspace.name == '2')
parent.title = '[1 tab] Video'; events['window.title'](parent)
assert(parent.workspace.name == 'special:firefox-pip:2')
events['window.close'](video)
assert(parent.workspace.name == '2')

windows, events, parent, video = setup()
parent.title = 'Unmarked browser with unknown tab count'
events['window.open'](video)
assert(parent.workspace.name == '2')
parent.title = '[1 tab] Video'; events['window.title'](parent)
assert(parent.workspace.name == 'special:firefox-pip:2')
-- A reload must recover a hidden source even though old event state is lost.
dofile('.config/hypr/firefox-pip.lua')
assert(parent.workspace.name == '2')

windows, events, parent, video = setup()
video.pid = 99; events['window.open'](video)
assert(parent.workspace.name == '2')
video.pid = 50; events['window.open'](video)
assert(parent.workspace.name == 'special:firefox-pip:2')
-- Respect a source manually moved out of the hidden workspace.
parent.workspace = { name = '3' }; events['window.close'](video)
assert(parent.workspace.name == '3')

local set_focus
windows, events, parent, video, set_focus = setup()
events['window.open'](video)
local second = { address = '0x3', class = 'firefox', pid = 50, title = 'Picture-in-Picture' }
windows[second.address] = second
set_focus(second, parent)
events['window.open'](second)
events['window.close'](video)
assert(parent.workspace.name == 'special:firefox-pip:2')
events['window.close'](second)
assert(parent.workspace.name == '2')
print('PiP lifecycle: hide/restore, new tabs, missing signal, PID isolation, reload recovery and multiple players pass.')
