local M = {}

local a, validate = vim.api, vim.validate

local AutocmdManager = {}
local EventProxy = {}
local GroupManager = {}

local mem = setmetatable({}, { __mode = "v" })  -- memoizing table
local private = setmetatable({}, { __mode = "k" })  -- private attributes for objects

local context = {
  new = function(self, opts)
    validate { opts = { opts, "t", true } }
    opts = opts or {}
    local g = opts.group
    opts.group = not (g == "END" or g == "end" or g == "default") and g or nil
    return setmetatable(opts, self)
  end,

  merge = function(self, ...)
    return vim.tbl_extend("keep", self, ...)
  end,

  force_merge = function(self, ...)
    return vim.tbl_extend("force", self, ...)
  end,
}



--
--
--        autocmd manager
--
--

function AutocmdManager:__call(event, action, opts)
  validate {
    event = { event, {"s", "t"} },
    action = { action, {"s", "f"} },
    opts = { opts, "t", true },
  }
  opts = private[self].ctx:merge(opts or {})
  if type(action) == "string" and action[1] == ":" then
    opts.command = action:sub(2)
  else
    opts.callback = action
  end
  return a.nvim_create_autocmd(event, opts)
end

---@see nvim_clear_autocmds()
function AutocmdManager:clear(opts)
  validate { opts = { opts, "t", true } }
  opts = private[self].ctx:merge(opts or {})
  return a.nvim_clear_autocmds(opts)
end

---@see nvim_exec_autocmds()
function AutocmdManager:exec(event, opts)
  validate {
    event = { event, {"s", "t"} },
    opts = { opts, "t", true },
  }
  opts = private[self].ctx:merge(opts or {})
  a.nvim_exec_autocmds(event, opts)
end

---@see nvim_get_autocmds()
function AutocmdManager:get(opts)
  validate { opts = { opts, "t", true } }
  opts = private[self].ctx:force_merge(opts or {})
  return a.nvim_get_autocmds(opts)
end

function AutocmdManager:del(id)
  a.nvim_del_autocmd(id)
end

function AutocmdManager:__index(k)
  return private[self].eventindex[k]
end



--
--
--        event
--
--

function EventProxy:get(opts)
  validate { opts = { opts, "t", true } }
  opts = private[self].ctx:force_merge({ event = private[self].name }, opts or {})
  return a.nvim_get_autocmds(opts)
end

function EventProxy:clear(opts)
  validate { opts = { opts, "t", true } }
  opts = private[self].ctx:force_merge({ event = private[self].name }, opts or {})
  a.nvim_clear_autocmds(opts)
end

function EventProxy:exec(opts)
  AutocmdManager.exec(self, private[self].name, opts)
end

function EventProxy:__call(action, opts)
  return AutocmdManager(self, private[self].name, action, opts)
end


--
--
--        group_manager
--
--

GroupManager.get = AutocmdManager.get
GroupManager.exec = AutocmdManager.exec

function GroupManager:create()
  return a.nvim_create_augroup(private[self].name, { clear = false })
end

function GroupManager:clear(opts)
  if not opts then
    return a.nvim_create_augroup(private[self].name, { clear = true })
  else
    AutocmdManager.clear(self, opts)
  end
end

function GroupManager:del()
  a.nvim_del_augroup_by_name(private[self].name)
  self = nil
end

function GroupManager:define(spec)
  validate { spec = { spec, "f" } }
  return spec(self.au)
end

function GroupManager:__index(k)
  if k == "id" then
    return self:create()
  elseif k == "name" then
    return private[self].name
  elseif k == "au" then
    return private[self].au
  end
end

GroupManager.__call = GroupManager.define


local function assert_valid_event(name)
  local valid, cmds = pcall(a.nvim_get_autocmds, { event = name })
  if not valid then
    error(string.format("'%s' is not a valid event name", name), 2)
  elseif vim.tbl_isempty(cmds) then
    return name
  else
    return cmds[1].event          -- camel-cased
  end
end

local function create_event_proxy(name, ctx)
  name = assert_valid_event(name)
  local event = setmetatable({}, { __index = EventProxy })
  private[event] = {
    name = name,
    ctx = ctx,
  }
  return event
end

local function create_eventindex(ctx)
  return setmetatable({}, {
    __mode = "v",
    __index = function(self, k)
      k = k:lower()
      local event = rawget(self, k)
      if not event then
        event = create_event_proxy(k, ctx)
        self[k], self[k:lower()] = event, event
      end
      return event
    end,
  })
end

local function create_autocmd_manager(ctx)
  local au = setmetatable({}, { __index = AutocmdManager })
  private[au] = {
    eventindex = create_eventindex(ctx)
    ctx = ctx,
  }
  return au
end

local function create_group_manager(ctx)
  local aug = setmetatable({}, { __index = GroupManager })
  private[aug] = {
    name = ctx.group,
    au = create_autocmd_manager(ctx),
    ctx = ctx,
  }
  return aug
end

local function create_groupindex()
  return setmetatable({}, {
    __index = function(self, k)
      local aug = mem[k]
      if not aug then
        local ctx = context:new { group = name }
        aug = create_group_manager(ctx)
        mem[k] = aug
      end
      return aug
    end,
  })
end



M.group = create_groupindex()

M.cmd = create_autocmd_manager(context:new({ group = "default" }))

return M
