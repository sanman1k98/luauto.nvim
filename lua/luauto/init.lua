local M = {}

local a, validate = vim.api, vim.validate

local AutocmdManager = {}
local EventProxy = {}
local GroupManager = {}

local private = setmetatable({}, { __mode = "k" })  -- private attributes for objects
local context = setmetatable({}, { __mode = "k" }) -- opt tables passed down from group manager -> au manager -> event proxy

local function merge_opts(left, right, merge_event)
  local opts = vim.tbl_extend("force", left, right)
  if not merge_event then
    opts.event = nil
  end
  return opts
end

local function err_unsupported()
  error("operation '%s' is not supported by this object", 2)
end



local AutoManager = {}

---@param ctx table|nil: API opts for this object to use when performing operations
---@field group string|number: group name or id
---@field buffer number: buffer number
---@field event string|table: an event or list of events
---@field 
function AutoManager:_new(ctx)
  self.__index = self
  local au = setmetatable({}, self)
  context[au] = ctx
  return au
end

function AutoManager:get(opts)
  validate { opts = { opts, "t", true } }
  opts = merge_opts(opts or {}, context[self], true)
  return a.nvim_get_autocmds(opts)
end

function AutoManager:clear(opts)
  validate { opts = { opts, "t", true } }
  opts = merge_opts(opts or {}, context[self], true)
  return a.nvim_clear_autocmds(opts)
end

function AutoManager:exec(event, opts)
  event = event or context[self].event
  validate {
    event = { event, {"s", "t"} },
    opts = { opts, "t", true },
  }
  opts = merge_opts(opts or {}, context[self])
  a.nvim_exec_autocmds(event, opts)
end

function AutoManager:__call(event, action, opts)
  event = event or context[self].event
  validate {
    event = { event, {"s", "t"} },
    action = { action, {"s", "f"} },
    opts = { opts, "t", true },
  }
  opts = merge_opts(opts or {}, context[self])
  if type(action) == "string" and action[1] == ":" then
    opts.command = action:sub(2)
  else
    opts.callback = action
  end
  return a.nvim_create_autocmd(event, opts)
end

function AutoManager:del(id)
  a.nvim_del_autocmd(id)
end



local EventProxy = {}

function EventProxy:_new(au, name)
  self.__index = self
  local e = setmetatable({}, self)
  private[e] = {
    au = au, 
    name = name
  }
  return e
end

function EventProxy:__call(action, opts)
  return private[self].au(private[self].name, action, opts)
end

function EventProxy:exec(opts)
  private[self].au:exec(private[self].name, opts)
end

function EventProxy:clear(opts)
  opts = opts or {}
  opts.event = private[self].name
  private[self].au:clear(opts)
end

function EventProxy:get(opts)
  opts = opts or {}
  opts.event = private[self].name
  private[self].au:get(opts)
end



local EventIndex = {}

function EventIndex:_new(au)

end






































--
--
--        autocmd manager
--
--

setmetatable(AutocmdManager, AutocmdManager)

---@private
local function create_events_tbl(ctx)
  return setmetatable({}, {
    __mode = "v",
    __index = function(t, k)
      local name = k:lower()
      local e = rawget(t, name)
      if not e then
        e = EventProxy:_new(name, ctx)
        t[name] = e
      end
      return e
    end,
  })
end

---@private
function AutocmdManager._new(ctx)
  local au = setmetatable({}, { __index = AutocmdManager })
  private[au] = { events = create_events_tbl(ctx) }
  context[au] = ctx or {}
  return au
end

function AutocmdManager:__call(event, action, opts)
  event = event or context[self].event
  validate {
    event = { event, {"s", "t"} },
    action = { action, {"s", "f"} },
    opts = { opts, "t", true },
  }
  opts = merge_opts(opts or {}, context[self])
  if type(action) == "string" and action[1] == ":" then
    opts.command = action:sub(2)
  else
    opts.callback = action
  end
  return a.nvim_create_autocmd(event, opts)
end

function AutocmdManager:define(spec_fn, ctx)
  validate {
    spec_fn = { spec_fn, "f" },
    ctx = { ctx, "t", true },
  }
  if not ctx then
    assert(context[self], "this object should have a context")
    return spec_func(self)
  else
    local au = AutocmdManager.init(ctx)
    return spec_fn(au)
  end
end

---@see nvim_clear_autocmds()
function AutocmdManager:clear(opts)
  validate { opts = { opts, "t", true } }
  opts = merge_opts(opts, context[self], true)
  return a.nvim_clear_autocmds(opts)
end

---@see nvim_exec_autocmds()
function AutocmdManager:exec(event, opts)
  validate {
    event = { event, {"s", "t"} },
    opts = { opts, "t", true },
  }
  opts = merge_opts(opts or {}, context[self])
  a.nvim_exec_autocmds(event, opts)
end

---@see nvim_get_autocmds()
function AutocmdManager:get(opts)
  validate { opts = { opts, "t", true } }
  opts = merge_opts(opts, context[self], true)
  return a.nvim_get_autocmds(opts)
end

function AutocmdManager:del(id)
  a.nvim_del_autocmd(id)
end

function AutocmdManager:__index(k)
  return rawget(AutocmdManager, k) or private[self].events[k]
end



--
--
--        event
--
--

---@private
local function assert_valid_event(name)
  local valid, cmds = pcall(a.nvim_get_autocmds, { event = name })
  if not valid then
    error(string.format("'%s' is not a valid event name", name), 2)
  end
end

---@private
function EventProxy._new(au, name)
  assert_valid_event(name)
  local e = setmetatable({}, { __index = EventProxy })
  private[e] = { au = au }
  return e
end

function EventProxy:get(opts)
  validate { opts = { opts, "t", true } }
  opts = opts or {}
  opts.event = private[self].name
  return private[self].au:get(opts)
end

function EventProxy:clear(opts)
  validate { opts = { opts, "t", true } }
  opts = opts or {}
  opts.event = private[self].name
  return private[self].au:clear(opts)
end

function EventProxy:exec(opts)
  private[self].au:exec(nil, opts)
end

function EventProxy:__call(action, opts)
  return private[self].au(nil, action, opts)
end



--
--
--        event index
--
--



--
--
--        group_manager
--
--

setmetatable(GroupManager, GroupManager)

---@private
function GroupManager:_new(name)
  local aug = setmetatable({}, { __index = GroupManager })
  private[aug] = { name = name }
  return aug
end

function GroupManager:create()
  return a.nvim_create_augroup(private[self].name, { clear = false })
end

function GroupManager:del()
  a.nvim_del_augroup_by_name(private[self].name)
  self = nil
end

function GroupManager:clear(opts)
  opts = opts or {}
  if not opts or vim.tbl_isempty(opts) then
    return a.nvim_create_augroup(private[self].name, { clear = true })
  else
    opts.group = private[self].name
    a.nvim_clear_autocmds(opts)
  end
end

function GroupManager:get(opts)
  validate { opts = { opts, "t", true } }
  opts = opts or {}
  opts.group = private[self].name
  return a.nvim_get_autocmds(opts)
end

function GroupManager:exec(event, opts)
  validate {
    event = { event, {"s", "t"} },
    opts = { opts, "t", true },
  }
  opts = opts or {}
  opts.group = private[self].name
  a.nvim_exec_autocmds(event, opts)
end

function GroupManager:define(spec_fn)
  validate { spec_fn = { spec_fn, "f" } }
  return AutocmdManager:define(spec_fn, { group = private[self].name })
end

function GroupManager:__index(k)
  if k == "id" then
    return GroupManager.create(self)
  end
end



M.group = setmetatable({}, {
  __index = function(_, k)
    return nil
  end,
})

M.cmd

return M
