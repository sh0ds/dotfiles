-- The local Firefox tab-count add-on supplies the [1 tab] title prefix.
-- Without that signal, leave Firefox visible rather than guessing its tabs.
local hidden_prefix = "special:firefox-pip:"
local parents, videos = {}, {}

local function firefox(w)
	if not w or not w.class then return false end
	local class = w.class:lower()
	return class:match("^firefox") ~= nil or class == "org.mozilla.firefox"
end

local function pip(w)
	return firefox(w) and (w.title == "Picture-in-Picture" or w.title == "Bild-im-Bild")
end

local function move(address, workspace)
	hl.dispatch(hl.dsp.window.move({ window = "address:" .. address, workspace = workspace, follow = false }))
end

local function restore(address, entry)
	local window = hl.get_window("address:" .. address)
	if entry.hidden and window and window.workspace and window.workspace.name == hidden_prefix .. entry.workspace then
		entry.hidden = false
		move(address, entry.workspace)
	end
	entry.hidden = false
end

local function reconcile(address, entry)
	local window = hl.get_window("address:" .. address)
	if not window or not window.workspace then return end
	if window.title and window.title:match("^%[1 tab%] ") then
		if not entry.hidden and not window.workspace.name:match("^special:") then
			entry.workspace = window.workspace.name
			entry.hidden = true
			move(address, hidden_prefix .. entry.workspace)
		end
	else
		restore(address, entry)
	end
end

-- Recover hidden browsers on config reload, when the old event state is lost.
for _, window in ipairs(hl.get_windows()) do
	local workspace = window.workspace and window.workspace.name
	if firefox(window) and workspace and workspace:sub(1, #hidden_prefix) == hidden_prefix then
		move(window.address, workspace:sub(#hidden_prefix + 1))
	end
end

hl.on("window.open", function(window)
	if not pip(window) then return end
	local parent = hl.get_active_window()
	if parent and parent.address == window.address then parent = hl.get_last_window() end
	-- Do not pick an arbitrary browser from the window list.
	if not firefox(parent) or pip(parent) or parent.pid ~= window.pid then return end
	local address = parent.address
	local entry = parents[address]
	if not entry then
		entry = { hidden = false, videos = {} }
		parents[address] = entry
	end
	entry.videos[window.address] = true
	videos[window.address] = address
	reconcile(address, entry)
end)

hl.on("window.title", function(window)
	local entry = parents[window.address]
	if entry then reconcile(window.address, entry) end
end)

hl.on("window.close", function(window)
	local address = window.address
	local parent = videos[address]
	if parent then
		videos[address] = nil
		local entry = parents[parent]
		if entry then
			entry.videos[address] = nil
			if not next(entry.videos) then
				parents[parent] = nil
				restore(parent, entry)
			end
		end
	elseif parents[address] then
		for video in pairs(parents[address].videos) do videos[video] = nil end
		parents[address] = nil
	end
end)
