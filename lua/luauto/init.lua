local M = {}

local autocmd = {}

local events;
local eventobj_mt, events_mt = {}, {}

local augroup = {}
local group_mt = {}

local attr = setmetatable({}, { __mode = "k" })
local a, validate = vim.api, vim.validate

---@param event string|table: event or events to register this autocmd for
---@param action function|string: Vim command prefixed with ":", the name of a Vim function, or a Lua function
---@param opts table|nil: a dictionary of autocmd options
---@return id number: integer id of the created autocmd
---@see nvim_create_autocmd()
function autocmd:create(event, action, opts)
  validate {
    event = { event, {"s", "t"} },
    action = { action, {"s", "f"} },
    opts = { opts, "t", true },
  }
  opts = opts or {}
  if type(action) == "string" and action[1] == ":" then
    opts.command = action:sub(2)
  else
    opts.callback = action
  end
  return a.nvim_create_autocmd(event, opts)
end



local function scoped_opts(self, opts)
  if not opts then opts = attr[self].scope
  else
    opts.group = attr[self].scope.group
    opts.buffer = attr[self].scope.buffer
  end
  return opts
end
 
---@see nvim_get_autocmds()
function eventobj_mt:get(opts)
  validate { opts = { opts, "t", true } }
  opts = scoped_opts(self, opts)
  opts.event = attr[self].name
  return a.nvim_get_autocmds(opts)
end

---@see nvim_exec_autocmds()
function eventobj_mt:exec(opts)
  validate { opts = { opts, "t", true } }
  return a.nvim_exec_autocmds(attr[self].name, scoped_opts(self, opts))
end

---@see nvim_clear_autocmds()
function eventobj_mt:clear(opts)
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
function eventobj_mt:__call(action, opts)
  return autocmd:create(attr[self].name, action, scoped_opts(self, opts))
end

event_mt.__index = event_mt

function events_mt:__index(k)
  local event = rawget(self, k:lower())
  if not event then
    event = {}
    attr[event] = {
      name = k,
      scope = attr[self]
    }
    event = setmetatable(event, eventobj_mt)
    rawset(self, k:lower(), event)
  end
  rawset(self, k, event)
  return event
end

events_mt.__mode = "v"

do
  local mem = setmetatable({}, { __mode = "v" })

  ---@param scope table|nil: the scope in which to create, clear, get, and exec autocmds for each event
  ---@field group string|nil: name of an autogroup
  ---@field buffer number|nil: a buffer number
  ---@return string: a key to index memoized results in the "mem" table
  local function keygen(scope)
    if not scope or vim.tbl_isempty(scope) then return "aug END" end
    local augroup = ("aug %s"):format(scope.group or "END")
    local buffer = scope.buffer and (" <buffer=%d>"):format(scope.buffer) or ""
    return augroup .. buffer
  end

  local function get_events(scope)
    validate { scope = { scope, "t", true } }
    local key = keygen(scope)
    if mem[key] then return mem[key] end
    local t = {}
    mem[key] = t
    attr[t] = scope or {}
    return setmetatable(t, events_mt)
  end

  events = get_events
end



function autocmd:clear(...) a.nvim_clear_autocmds(...) end
function autocmd:del(...) a.nvim_del_autocmd(...) end
function autocmd:exec(...) a.nvim_exec_autocmds(...) end
function autocmd:get(...) return a.nvim_get_autocmds(...) end

M.cmd = setmetatable(autocmd, {
  __index = events(nil),
  __call = autocmd.create,
})



--- Create this autogroup without clearing it.
---@return integer: this group's id
function group_mt:create()
  return a.nvim_create_augroup(attr[self].group_name, { clear = false })
end

--- Clear the autogroup.
---@return integer: this group's id
function group_mt:clear(opts)
  validate { opts = { opts, "t", true } }
  if not opts or vim.tbl_isempty(opts) then
    return a.nvim_create_augroup(attr[self].group_name, { clear = true })
  else
    opts = opts or {}
    opts.group = attr[self].group_name
    a.nvim_clear_autocmds(opts)
  end
end

--- Delete the autogroup and remove this object from the table "mem".
function group_mt:del()
  a.nvim_del_augroup_by_name(attr[self].group_name)
  self = nil
end

function group_mt:get(opts)
  validate { opts = { opts, "t", true } }
  opts = opts or {}
  opts.group = attr[self].group_name
  return a.nvim_get_autocmds(opts)
end

function group_mt:exec(event, opts)
  validate {
    event = { event, {"s", "t"} },
    opts = { opts, "t", true },
  }
  opts = opts or {}
  opts.group = attr[self].group_name
  return a.nvim_exec_autocmds(event, opts)
end

function group_mt:__index(k)
  if k == "id" then
    return group_mt.create(self)
  elseif k == "au" or k == "autocmd" then
    return attr[self].autocmd
  else
    return rawget(group_mt, k)
  end
end

function group_mt:__newindex(k, v)
  if k == "id" or k == "au" or k == "autocmd" then
    error("attempting to modify a read-only field", 2)
  else
    rawset(self, k, v)
  end
end

function group_mt:__call(...)
  group_mt.create(self)
  local au = attr[self].autocmd
  local spec = ...
  if vim.is_callable(spec) then
    return spec(au)
  else
    for _, cmd in ipairs{...} do
      assert(type(cmd) == "table", "expecting arguments to be tables")
      au(cmd[1], cmd[2], cmd[3])
    end
  end
end

do
  local function create_autocmd_tbl(group)
    local au = {}
    attr[au] = { group_name = attr[group].group_name }

    au.clear = group_mt.clear
    au.get = group_mt.get
    au.exec = group_mt.exec
    function au:del(...) a.nvim_del_autocmd(...) end

    return setmetatable(au, {
      __index = events({ group = attr[au].group_name }),
      __call = function(self, event, action, opts)
        validate { opts = { opts, "t", true } }
        opts = opts or {}
        opts.group = attr[self].group_name
        return autocmd:create(event, action, opts)
      end
    })
  end

  M.group = setmetatable(augroup, {
    __index = function(self, k)
      local group = {}
      attr[group] = { group_name = k }
      attr[group].autocmd = create_autocmd_tbl(group)
      self[k] = group
      return setmetatable(group, group_mt)
    end,
    __mode = "v",
  })
end



return M
