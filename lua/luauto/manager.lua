

---@class context @The parameters in which a Manager can perform its functions.
---@field group string|number|nil: group name or id
---@field pattern string|table|nil: pattern or patterns
---@field buffer number|nil: buffer number

---@class Manager @Manages autocmds for a given context
---@field _ctx context: context
---@field _proxies table: a table containing EventProxies

---@class EventProxy @Manages a single event for a given context
---@field _event string: name of the event
---@field _proxies table: a table containing PatternProxies
---@field _ctx context: the Manager's context

---@class PatternProxy @Manages a single pattern for a given event and context
---@field _event string: name of the event
---@field _ctx context: contains a 'pattern' field and others


local Manager = {}
local EventProxy = {}
local PatternProxy = {}
local new = {}        -- constructors

local a = vim.api
local validate = vim.validate

local function merge(...) return vim.tbl_extend("force", ...) end



local methods = {
  create = function(self, event, action, opts)
    validate {
      event = { event, {"s", "t"} },
      action = { action, {"s", "f"} },
      opts = { opts, "t" },
    }
    opts = merge(opts or {}, self._ctx)
    if type(action) == "string" and action[1] == ":" then
      opts.command = action:sub(2)
    else
      opts.callback = action
    end
    return a.nvim_create_autocmd(event, opts)
  end,

  exec = function(self, event, opts)
    validate {
      event = { event, {"s", "t"} },
      opts = { opts, "t" },
    }
    opts = merge(opts or {}, self._ctx)
    a.nvim_exec_autocmds(event, opts)
  end,

  clear = function(self, opts, event)
    validate {
      opts = { opts, "t" },
      event = { event, {"s", "t"}, true },
    }
    opts = merge(opts or {}, self._ctx)
    if event then opts.event = event end
    a.nvim_clear_autocmds(opts)
  end,

  get = function(self, opts, event)
    validate {
      opts = { opts, "t" },
      event = { event, {"s", "t"}, true },
    }
    opts = merge(opts or {}, self._ctx)
    if event then opts.event = event end
    a.nvim_get_autocmds(opts)
  end,
}

new[PatternProxy] = function(event, ctx, pattern)
  local self = setmetatable({}, PatternProxy)
  self._event = event
  self._ctx = merge(ctx, { pattern = pattern })
  return self
end

--- Pass a function to manage autocmds for this pattern
function PatternProxy:define(spec, opts)
  validate {
    spec = { spec, "f" },
    opts = { opts, "t", true },
  }
  if not opts or vim.tbl_isempty(opts) then
    return spec(self)
  else
    local pat = self._ctx.pattern
    local ctx = merge(self._ctx, opts)
    local pattern = new[PatternProxy](self._event, ctx, pat)
    return spec(pattern)
  end
end

PatternProxy.__index = EventProxy   -- use EventProxy methods

new[EventProxy] = function(name, ctx)
  local valid, cmds = pcall(a.nvim_get_autocmds, { event = name })

  if not valid then
    error(string.format("'%s' is not a valid event name", name), 2)
  end

  local patterns = not ctx.buffer and setmetatable({}, {
    __mode = "v",
    __index = function(t, k)
      local pat = new[PatternProxy](name, ctx, k)
      rawset(t, k, pat)
      return pat
    end,
  })

  local self = setmetatable({}, EventProxy)
  self._event = name
  self._proxies = patterns or nil
  self._ctx = ctx
  return self
end

--- Create multiple autocmds for this event
function EventProxy:define(spec, opts)
  validate {
    spec = { spec, "f" },
    opts = { opts, "t", true },
  }
  if not opts or vim.tbl_isempty(opts) then
    return spec(self)
  else
    local event = new[EventProxy](self._event, merge(self._ctx, opts))
    return spec(event)
  end
end

function EventProxy:__call(action, opts)
  return funcs.create(self, self._event, action, opts)
end

function EventProxy:get(opts)
  return funcs.get(self, opts, self._event)
end

function EventProxy:exec(opts)
  return funcs.get(self, self._event, opts)
end

function EventProxy:clear(opts)
  return funcs.clear(self, opts, self._event)
end

function EventProxy:__index(k)
  return rawget(EventProxy, k) or (self._patterns and self._patterns[k] or nil)
end


---@param ctx context: the context for this manager
---@return Manager
function new[Manager](ctx)
  validate { ctx = { ctx, "t", true } }

  local ctx = ctx or {}
  local g = ctx.group
  ctx.group = not (g == "default" or g == "end" or g == "END") and g or nil

  local events = setmetatable({}, {
    __mode = "v",
    __index = function(t, k)
      k = k:lower()
      local e = rawget(t, k)
      if not e then rawset(t, k, new_event(k, ctx)) end
      return e
    end,
  })

  local self = setmetatable({}, Manager)
  self._ctx = ctx
  self._proxies = events

  return self
end

--- Create multiple autocmds for this Manager's context and optionally pass in
--- additional opts you want to be applied.
function Manager:define(spec, opts)
  validate {
    spec = { spec, "f" },
    opts = { opts, "t", true },
  }
  if not opts or vim.tbl_isempty(opts) then
    return spec(self)
  else
    local manager = new[Manager](merge(self._ctx, opts))
    return spec(manager)
  end
end

function Manager:del(id)
  a.nvim_del_autocmd(id)
end

function Manager:__index(k)
  return rawget(mathods, k) or self._events[k]
end

Manager.__call = methods.create



return {
  new = function(ctx)
    validate { ctx = { ctx, "t", true } }
    local ctx = ctx or {}
    local g = ctx.group
    ctx.group = not (g == "default" or g == "end" or g == "END") and g or nil

    return new[Manager](ctx)
  end,
}
