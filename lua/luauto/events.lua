local event_mt = {}
local scoped_events_mt = {}

local attr = setmetatable({}, { __mode = "k" })
local mem = setmetatable({}, { __mode = "v" })

local a, validate = vim.api, vim.validate

---@class event @An object to manage autocmds for an event.
---@field clear method: clear autocmds for this event
---@field exec method: execute autocmds for this event
---@field get method: get autocmds for this event

---@class scoped_events @A table to manage autocmds for events in a specified scope.
---@field <event> event:

local function scoped_opts(self, opts)
  if not opts then opts = attr[self].scope
  else
    opts.group = attr[self].scope.group
    opts.buffer = attr[self].scope.buffer
  end
  return opts
end
 
---@see nvim_get_autocmds()
function event_mt:get(opts)
  validate { opts = { opts, "t", true } }
  opts = scoped_opts(self, opts)
  opts.event = attr[self].name
  return a.nvim_get_autocmds(opts)
end

---@see nvim_exec_autocmds()
function event_mt:exec(opts)
  validate { opts = { opts, "t", true } }
  return a.nvim_exec_autocmds(attr[self].name, scoped_opts(self, opts))
end

---@see nvim_clear_autocmds()
function event_mt:clear(opts)
  validate { opts = { opts, "t", true } }
  opts = scoped_opts(self, opts)
  opts.event = attr[self].name
  return a.nvim_clear_autocmds(opts)
end

--- Create an autocmd for event.
---@param action function|string: a Vim command prefixed with ":", or a callback func
---@param opts table|nil: a dictionary of autocmd options
---@return id number: integer id of the created autocmd
---@see nvim_create_autocmd()
function event_mt:__call(action, opts)
  validate {
    action = { action, {"s", "f"} },
    opts = { opts, "t", true },
  }
  opts = scoped_opts(self, opts)
  if type(action) == "string" and action[1] == ":" then
    opts.command = action:sub(2)
  else
    opts.callback = action
  end
  return a.nvim_create_autocmd(attr[self].name, opts)
end

event_mt.__index = event_mt


---@param k string: name of an event (case-insensitive)
---@return event: a table for the event
function scoped_events_mt:__index(k)
  local event = rawget(self, k:lower())
  if not event then
    event = {}
    attr[event] = { name = k, scope = attr[self] }
    event = setmetatable(event, event_mt)
    rawset(self, k:lower(), event)
  end
  rawset(self, k, event)
  return event
end

scoped_events_mt.__mode = "v"

---@param scope table|nil: the scope in which to create, clear, get, and exec autocmds for each event
---@field group string|nil: name of an autogroup
---@field buffer number|nil: a buffer number
---@return string: a key to index memoized results in the "mem" table
local function events_keygen(scope)
  if not scope then return "aug END" end
  local augroup = ("aug %s"):format(scope.group or "END")
  local buffer = scope.buffer and (" <buffer=%d>"):format(scope.buffer) or ""
  return augroup .. buffer
end

--- Get a table that is used to manage autocmds using event names within the
--- default autogroup, or if specified, a different autogroup and/or a
--- specific buffer number. Can also create autocmds.
---@param scope table|nil: the scope in which to create, clear, get, and exec autocmds for each event
---@field group string|nil: name of an autogroup
---@field buffer number|nil: a buffer number
---@return table: used to manage and create autocmds
local function get_events(scope)
  validate { scope = { scope, "t", true } }
  local key = events_keygen(scope)
  if mem[key] then return mem[key] end
  local events = {}
  mem[key] = events
  attr[events] = { group = scope.group, buffer = scope.buffer }
  return setmetatable(events, scoped_events_mt)
end

return get_events
