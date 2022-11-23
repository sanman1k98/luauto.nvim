local event_mt = {}
local scoped_events_mt = {}

local attr = setmetatable({}, { __mode = "k" })
local mem = setmetatable({}, { __mode = "v" })

local a, validate = vim.api, vim.validate

---@class event @An object to manage autocmds for this event.
---@field clear method:
---@field exec method:
---@field get method:

local function scoped_opts(self, opts)
  if not opts then opts = attr[self].opts
  else
    opts.group = attr[self].opts.group
    opts.buffer = attr[self].opts.buffer
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
    attr[event] = { name = k, opts = attr[self] }
    event = setmetatable(event, event_mt)
    rawset(self, k:lower(), event)
  end
  rawset(self, k, event)
  return event
end

scoped_events_mt.__mode = "v"

---@param group string|nil: name of an autogroup
---@param buffer number|nil: a buffer number
---@return string: a key to index memoized results in the "mem" table
local function keygen(group, buffer)
  if not (group or buffer) then return "aug END" end
  local augroup = ("aug %s"):format(group or "END")
  local buffer = buffer and (" <buffer=%d>"):format(buffer) or ""
  return augroup .. buffer
end

--- Get a table that is used to manage autocmds using event names within the
--- default autogroup, or if specified, a different autogroup and/or a
--- specific buffer number. Can also create autocmds.
---@param group string|nil: name of an autogroup
---@param buffer number|nil: a buffer number
---@return table: used to manage and create autocmds
local function get_scoped_events(group, buffer)
  validate {
    group = { group, "s", true },
    buffer = { buffer, "n", true },
  }
  local key = keygen(group, buffer)
  if mem[key] then return mem[key] end
  local scoped = {}
  mem[key] = scoped
  attr[scoped] = { group = group, buffer = buffer }
  return setmetatable(scoped, scoped_events_mt)
end

return get_scoped_events
