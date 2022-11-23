local attr = setmetatable({}, { __mode = "k" })
local events = setmetatable({}, { __mode = "v" })
local groups = setmetatable({}, { __mode = "v" })
local a, validate = vim.api, vim.validate

local event_mt, group_mt = {}, {}

local events



local function create_autocmd(event, action, opts)
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

local function tbl_opts(self, opts)
  if not opts then opts = attr[self].opts
  else
    opts.group = attr[self].opts.group
    opts.buffer = attr[self].opts.buffer
  end
  return opts
end
 
function event_mt:get(opts)
  validate { opts = { opts, "t", true } }
  opts = tbl_opts(self, opts)
  opts.event = attr[self].name
  return a.nvim_get_autocmds(opts)
end

function event_mt:exec(opts)
  validate { opts = { opts, "t", true } }
  return a.nvim_exec_autocmds(attr[self].name, tbl_opts(self, opts))
end

function event_mt:clear(opts)
  validate { opts = { opts, "t", true } }
  opts = tbl_opts(self, opts)
  opts.event = attr[self].name
  return a.nvim_clear_autocmds(opts)
end

--- create an autocmd on event
function event_mt:__call(action, opts)
  return create_autocmd(attr[self].name, action, tbl_opts(self, opts))
end

event_mt.__index = event_mt

local function get_events(opts)
  validate { opts = { opts, "t", true } }
  opts = opts or {}
  local key = string.format("%s-%s", opts.group or "nil", opts.buffer or "nil")
  if events[key] then return events[key] end
  local tbl, mt = {}, {}
  attr[tbl] = { group = opts.group, buffer = opts.buffer }

  function mt:__index(eventname)
    k = eventname:lower()
    if tbl[k] then return tbl[k] end
    local event = {}
    tbl[k] = event
    attr[event] = { name = k, opts = attr[tbl] }
    return setmetatable(event, event_mt)
  end

  mt.__mode = "v"

  return setmetatable(t, mt)
end



local autocmd = setmetatable({}, {
  __index = get_events(),
  __call = function(_, ...)
    return create_autocmd(...)
  end,
})



function group_mt:create()
    return a.nvim_create_autogroup(attr[self].name, { clear = false })
end

function group_mt:clear(opts)
  validate { opts = { opts, "t", true } }
  if not opts then
    return a.nvim_create_autogroup(attr[self].name, { clear = true })
  else
    opts.group = attr[self].name
    a.nvim_clear_autocmds(opts)
  end
end

function group_mt:del()
  a.nvim_del_augroup_by_name(attr[self].name)
  self = nil
end

function group_mt:__index(k)
  if k == "id" then
    return group_mt.create(self)
  else
    return rawget(group_mt, k)
  end
end

function group_mt:__newindex(k, v)
  if k == "id" then
    error("attempting to modify a read-only field", 2)
  else
    rawset(self, k, v)
  end
end

function group_mt:__call(...)
  group_mt.create(self)
  local args = {...}
  if vim.is_callable(args[1]) then
    local spec, au = args[1], attr[self].autocmd
    return spec(au)
  else
    for _, cmd in ipairs(args) do
      assert(type(cmd) == "table", "expecting tables as arguments")
      attr[self].autocmd(cmd[1], cmd[2], cmd[3])
    end
  end
end

local function get_group(name)
  if groups[name] then return groups[name] end
  local group = {}
  groups[name] = group
  attr[group] = { name = name }

  do
    local self = group
    local t, mt = {}, {}
    function t:clear(opts) return group_mt(self, opts) end
    function mt:__call(event, action, opts)
      validate { opts = { opts, "t", true } }
      opts = opts or {}
      opts.group = attr[self].name
      return create_autocmd(event, action, opts)
    end
    mt.__index = get_events { group = attr[self].name }
    attr[self].autocmd setmetatable(t, mt)
  end

  return setmetatable(group, group_mt)
end

local augroup = setmetatable({}, {
  __index = function(_, k)
    return get_group(k)
  end,
})
