local Event, EventProxy = {}, {}
local mem = setmetatable({}, { __mode = "k" })
local info = setmetatable({}, { __mode = "v" })

local au = require "luauto.cmd"


--- Add a new autocommand on this event.
---@param opts table: a dictionary of opts representing an autocommand
---@field cmd string?: 
---@field cb string|function|nil:
---@field NAME TYPE: DESC
---@field NAME TYPE: DESC
---@field NAME TYPE: DESC
---@field NAME TYPE: DESC
function Event:add(opts)
  local event = info[self]
  return vim.api.nvim_create_autocmd(event, opts)
end


--- Add a new callback to this event.
function Event:cb(callback, opts)
  opts = opts or {}
  opts.callback = callback
  return vim.api.nvim_create_autocmd(info[self], opts)
end


--- Add a command to this event.
function Event:cmd(command, opts)
  opts = opts or {}
  opts.command = command
  return vim.api.nvim_create_autocmd(info[self], opts)
end


--- Execute all autocommands for this event matching opts.
function Event:exec(opts)
  opts = opts or {}
  vim.api.nvim_exec_autocmds(info[self], opts)
end


--- Get all autocommands for this event matching opts.
function Event:get_cmds(opts)
  opts = opts or {}
  opts.event = info[self]
  return vim.api.nvim_get_autocmds(opts)
end


--- Clear all autocommands for this event matching opts.
function Event:clear(opts)
  opts = opts or {}
  opts.event = info[self]
  vim.api.nvim_clear_autocmds(opts)
end


--- Get or set the the ignore setting for this event.
function Event:get_ignore()
  for _, event in ipairs(vim.opt.eventignore:get()) do
    event = string.lower(event)
    if event == info[self] then
      return true
    end
  end
  return false
end


function Event:set_ignore(flag)
  if flag then vim.opt.eventignore:append(info[self])
  else vim.opt.eventignore:remove(info[self]) end
end


--- Get the event name
function Event:name()
  return info[self]
end


function EventProxy:get(event_name)
  event_name = event_name:lower()   -- event names are case-insensitive
  if mem[event_name] then return mem[event_name] end
  local proxy = {}
  mem[event_name] = proxy
  info[proxy] = event_name
  return setmetatable(proxy, self)
end


function EventProxy:__index(k)
  if k == "name" then
    return Event.name(self)
  elseif k == "cmds" then
    return Event.get_cmds(self)
  elseif k == "ignore" then
    return Event.get_ignore(self)
  else
    local v = Event[k]
    rawset(self, k, v)
    return v
  end
end


function EventProxy:__newindex(k, v)
  if k == "name" or k == "cmds" then
    error("attempting to modify a read-only field", 2)
  elseif k == "ignore" then
    Event.set_ignore(self, v)
  else
    rawset(self, k, v)
  end
end


return setmetatable({}, {
  __index = function(_, event)
    return EventProxy:get(event)
  end,
})
