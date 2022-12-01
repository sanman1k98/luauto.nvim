
local methods = {
  autocmd = {},   -- but-local and global
  proxy = {},     -- event and pattern
  augroup = {},
}

local a, validate = vim.api, vim.validate


---@class context
---@field group string|number|nil: group name or id
---@field buffer number|boolean|nil: true for the current buffer or a specific buffer number
---@field pattern string|nil: pattern or patterns

local function create_autocmd_tbl(ctx)
  local self = setmetatable({}, methods.autocmd)
  self._ctx = ctx or {}
  return self
end

local function create_proxy_tbl(event, ctx)
  local self = setmetatable({}, methods.proxy)
  self._event = event
  self._ctx = ctx
  return self
end

local function create_augroup_tbl(group)
  local self = setmetatable({}, methods.augroup)
  self._group = group
  self._autocmd = create_autocmd_tbl({ group = group })
  return self
end

local function unsupported(op, msg)
  local m = string.format("the operation '%s' is not supported.\n %s", op, msg)
  error(m, 2)
end

local function merge_opts(...)
  local opts = vim.tbl_extend("force", ...)
  if opts.buffer and opts.pattern then
    error("cannot specify a pattern for a buf-local autocmd", 2)
  elseif opts.buffer == true then
    opts.buffer = a.nvim_get_current_buf()
  elseif not opts.buffer then
    opts.buffer = nil
  end
  return opts
end

local valid_events = setmetatable({}, {
  __index = function(self, k)
    local validity = pcall(a.nvim_get_autocmds, { event = k })
    rawset(self, k, validity)
    return validity
  end,
})



function methods.autocmd:__index(k)
  if k == "buf" and not self._ctx.buffer then
    local ctx = merge_opts(self._ctx, { buffer = true })
    return new.autocmd(ctx)
  elseif self._ctx.buffer == true and type(k) == "number" then
    local ctx = merge_opts(self._ctx, { buffer = k })
    return new.autocmd(ctx)
  end

  local v = methods.autocmd[k]
  if v then return v end

  local event = k:lower()   -- event names are case-insensitive
  if not valid_events[event] then
    error(string.format("'%s' is not a valid event name", event), 2)
  end

  return create_proxy_tbl(event, self._ctx)
end

function methods.autocmd:__call(event, action, opts)
  validate {
    event = { event, {"s", "t"} },
    action = { action, {"s", "f"} },
    opts = { opts, "t", true },
  }

  opts = merge_opts(opts or {}, self._ctx)

  if type(action) == "string" and action[1] == ":" then
    opts.command = action:sub(2)
  else
    opts.callback = action
  end

  return a.nvim_create_autocmd(event, opts)
end

--- Use for defining buf-local autocmds
function methods.autocmd:define(spec)
  if not self._ctx.buffer then
    unsupported("define", "use 'define' for buf-local autocmds")
  end
  validate { spec = { spec, "f" } }
  return spec(self)
end

function methods.autocmd:exec(event, opts)
  validate {
    event = { event, {"s", "t"} },
    opts = { opts, "t", true },
  }
  a.nvim_exec_autocmds(event, merge_opts(opts or {}, self._ctx))
end

function methods.autocmd:get(opts)
  validate { opts = { opts, "t", true } }
  return a.nvim_get_autocmds(merge_opts(opts or {}, self._ctx))
end

function methods.autocmd:clear(opts)
  validate { opts = { opts, "t", true } }
  a.nvim_clear_autocmds(merge_opts(opts or {}, self._ctx))
end

--      event and pattern proxy methods

--- Create an autocmd for the event
---@param
---@param
function methods.proxy:__call(action, opts)
  return methods.autocmd.__call(self, self._event, action, opts)
end

--- Execute autocmds matching this event
---@param
function methods.proxy:exec(opts)
  return methods.autocmd.exec(self, opts)
end

function methods.proxy:get(opts)
  validate { opts = { opts, "t", true } }
  opts = merge_opts(opts or {}, self._ctx)
  opts.event = self._event
  return a.nvim_get_autocmds(opts)
end

function methods.proxy:clear(opts)
  validate { opts = { opts, "t", true } }
  opts = merge_opts(opts or {}, self._ctx)
  opts.event = self._event
  return a.nvim_clear_autocmds(opts)
end

function methods.proxy:__index(k)
  local v = methods.proxy[k]
  if v then return v end

  if self._ctx.buffer or self._ctx.pattern then return nil end

  local ctx = merge_opts(self._ctx, { pattern = k })
  return create_proxy_tbl(self._event, ctx)
end

--      augroup methods

function methods.augroup:create(opts)
  validate { opts = { opts, "t", true } }
  opts = opts or { clear = false }
  return a.nvim_create_augroup(self._group, opts)
end

methods.augroup.get = methods.autocmd.get
methods.augroup.exec = methods.autocmd.exec
methods.augroup.clear = methods.autocmd.clear

function methods.augroup:define(spec)
  validate { spec = { spec, "f" } }
  self:create({ clear = false })
  return spec(self._autocmd)
end

function methods.augroup:__index(k)
  if k == "id" then
    return self:create({ clear = false })
  else
    return methods.augroup[k] or self._autocmd[k]
  end
end



return {
  cmd = create_autocmd_tbl({
    group = nil,      -- default group
    buffer = nil,     -- global
  }),

  -- indexable by group names
  group = setmetatable({}, {
    __index = function(_, k)
      return create_augroup_tbl(k)
    end,
  }),
}
