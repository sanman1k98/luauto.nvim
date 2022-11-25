local M = {}

local autocmd_mt = {}
local event_mt, eventset_mt = {}, {}
local group_mt = {}

local get_eventset_obj, get_group_obj, get_autocmd_obj

local attr = setmetatable({}, { __mode = "k" })
local a, validate = vim.api, vim.validate



--
--
--
--
--

local function validate_opts(opts)
  validate {
    opts = { opts, "t" },
    group = { opts.group, {"s", "n"}, true },
    buffer = { opts.buffer, "n", true },
  }
  if opts.buffer and opts.pattern then
    error("cannot specify both pattern and buffer", 2)
  end
end

local function keygen(opts)
  validate_opts(opts)
  return vim.inspect(opts)
end

local function set_opts(self, opts, set_event)
  local opts = self.scope
  if not opts then
    return scope
  else -- set event field unless otherwise specified
    opts.event = (set_event == nil or set_event == true) and self.event or opts.event
    opts.group = scope.group
    opts.buffer = scope.buffer
  end
  return opts
end



--
--
--        autocmd_mt
--
--

function autocmd_mt:create(event, action, opts)
  validate {
    event = { event, {"s", "t"} },
    action = { action, {"s", "f"} },
    opts = { opts, "t", true },
  }
  opts = set_scope(self, opts, false)
  if type(action) == "string" and action[1] == ":" then
    opts.command = action:sub(2)
  else
    opts.callback = action
  end
  return a.nvim_create_autocmd(event, opts)
end

---@see nvim_clear_autocmds()
function autocmd_mt:clear(opts)
  validate { opts = { opts, "t", true } }
  opts = set_scope(self, opts)
  return a.nvim_clear_autocmds(opts)
end

---@see nvim_exec_autocmds()
function autocmd_mt:exec(event, opts)
  validate {
    event = { event, {"s", "t"} },
    opts = { opts, "t", true },
  }
  opts = set_scope(self, opts, false)
  a.nvim_exec_autocmds(event, opts)
end

--- Can specify multiple buffer numbers
---@see nvim_get_autocmds()
function autocmd_mt:get(opts)
  validate { opts = { opts, "t", true } }
  opts = set_scope(self, opts)
  return a.nvim_get_autocmds(opts)
end

function autocmd_mt:del(...)
  a.nvim_del_autocmd(...)
end

autocmd_mt.__call = autocmd_mt.create

function autocmd_mt:__index(k)
  return attr[self][k] or rawget(autocmd_mt, k) or attr[self].eventset[k]
end

function autocmd_mt:__newindex(k, v)
  if k == "group" or k == "buffer"
    then error("attemping to modify a read-only field", 2)
  else
    rawset(self, k, v)
  end
end



--
--
--        event_mt, eventset_mt
--
--

event_mt.get = autocmd_mt.get
event_mt.clear = autocmd_mt.clear
function event_mt:exec(...) autocmd_mt.exec(self, self.name, ...) end
function event_mt:__call(...) return autocmd_mt.create(self, self.name, ...) end

function event_mt:__index(k)
  if k == "name" or k == "event" then
    return attr[self].event
  elseif k == "group" then
    return attr[self].group
  elseif k == "buffer" then
    return attr[self].buffer
  else
    return rawget(event_mt, k)
  end
end

function event_mt:__newindex(k, v)
  if k == "name"
    or k == "event"
    or k == "group"
    or k == "buffer"
    then error("attemping to modify a read-only field", 2)
  else
    rawset(self, k, v)
  end
end

function eventset_mt:__index(k)
  local event = rawget(self, k:lower())
  if not event then
    event = {}
    attr[event] = {
      group = attr[self].group,
      buffer = attr[self].buffer,
      event = k:lower(),
    }
    event = setmetatable(event, event_mt)
    rawset(self, k:lower(), event)
  end
  rawset(self, k, event)
  return event
end

eventset_mt.__mode = "v"



--
--
--        get_eventset_obj, get_autocmd_obj
--
--

do
  local mem = setmetatable({}, { __mode = "v" })

  get_eventset_obj = function(opts)
    validate { opts = { opts, "t" } }
    local key = keygen(opts)
    if mem[key] then return mem[key] end
    local set = {}
    mem[key] = set
    attr[set] = {
      group = opts.group,
      buffer = opts.buffer,
    }
    return setmetatable(set, eventset_mt)
  end
end

do
  local mem = setmetatable({}, { __mode = "v" })

  get_autocmd_obj = function(opts)
    validate { opts = { opts, "t" } }
    local key = keygen(opts)
    if mem[key] then return mem[key] end
    local au = {}
    mem[key] = au
    attr[au] = {
      group = opts.group,
      buffer = opts.buffer,
      eventset = get_eventset_obj(opts)
    }
    return setmetatable(au, autocmd_mt)
  end
end



--
--
--        group_mt
--
--

group_mt.get = autocmd_mt.get
group_mt.exec = autocmd_mt.exec

function group_mt:create()
  return a.nvim_create_augroup(self.name, { clear = false })
end

function group_mt:clear(opts)
  if not opts then
    return a.nvim_create_augroup(self.name, { clear = true })
  else
    autocmd_mt.clear(self, opts)
  end
end

function group_mt:del()
  a.nvim_del_augroup_by_name(self.name)
  self = nil
end

function group_mt:define(spec)
  validate { spec = { spec, "f" } }
  return spec(self.au)
end

function group_mt:__index(k)
  if k == "id" then
    return group_mt.create(self)
  elseif k == "name" or k == "group" then
    return attr[self].scope.group
  elseif k == "scope" then
    return attr[self].scope
  elseif k == "au" or k == "autocmd" then
    return attr[self].autocmd
  else
    return rawget(group_mt, k)
  end
end

function group_mt:__newindex(k, v)
  if k == "id"
    or k == "name"
    or k == "scope"
    or k == "au"
    or k == "autocmd"
    then error("attempting to modify a read-only field", 2)
  else
    rawset(self, k, v)
  end
end

group_mt.__call = group_mt.define



--
--
--        get_group_obj
--
--

do
  local mem = setmetatable({}, { __mode = "v" })

  get_group_obj = function(k)
    validate { group_name = { k, "s" } }
    if mem[k] then return mem[k] end
    local group = {}
    mem[k] = group
    attr[group] = {
      opts = {
        group = k
      }
    }
    attr[group].autocmd = get_autocmd_obj(attr[group].opts)
    return setmetatable(group, group_mt)
  end
end



M.cmd = get_autocmd_obj {}
M.group = setmetatable({}, { __index = function(_, k) return get_group_obj(k) end, })
M.events = get_eventset_obj

return M
