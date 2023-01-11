
local Autocmd = {}
local Event = {}
local Augroup = {}

local a, validate = vim.api, vim.validate

---@class AutocmdOptions @Dictionary of autocommand options.
---@field group? string|number group name or id
---@field buffer? number|boolean specifies a buffer; use 0 or true for the current buffer
---@field pattern? string|string[] pattern or list of patterns
---@field desc? string description of the autocommand
---@field once? boolean run the autocommand only once (defaults to false)
---@field nested? boolean run nested autocommands (defaults to false)

---@class AutocmdContext @Autocommand options passed from parent objects.
---@field group? string|number group name or id
---@field buffer? number|boolean specifies a buffer; use 0 or true for the current buffer
---@field pattern? string|string[] pattern or list of patterns

---@private
local function merge_opts(...)
  local opts = vim.tbl_extend("force", ...)
  if opts.buffer and opts.pattern then
    error("cannot specify a pattern for a buf-local autocmd", 2)
  end
  return opts
end



--      constructors

---@param ctx AutocmdContext
---@private
local function create_autocmd_object(ctx)
  local self = {
    _ctx = ctx
  }
  return setmetatable(self, Autocmd)
end

local function create_event_object(event, ctx)
  local self = {
    _event = event,
    _ctx = ctx,
  }
  return setmetatable(self, Event)
end

local function create_augroup_object(name)
  local ctx = { group = name }
  local self = {
    _au = create_autocmd_object(ctx),
    _ctx = ctx,
  }
  return setmetatable(self, Augroup)
end



--      autocmd methods

function Autocmd:__index(k)
  local method = rawget(Autocmd, k)

  if method then
    return method
  elseif k == "buf" then 
    -- create table indexable by bufnr
    return setmetatable({ _ctx = self._ctx }, {
      __index = function(t, bufnr)
        local ctx = merge_opts(t._ctx, { buffer = bufnr })  -- use key to specify buffer
        return create_autocmd_object(ctx)                   -- return Autocmd obj with buffer
      end,
    })
  end

  -- use key to get an Event object
  return create_event_object(k, self._ctx)
end

---@param opts AutocmdOptions: optional dictionary of autocommand options
function Autocmd:get(opts)
  validate { opts = { opts, "t", true } }
  return a.nvim_get_autocmds(merge_opts(opts or {}, self._ctx))
end

---@param opts AutocmdOptions: optional dictionary of autocommand options
function Autocmd:clear(opts)
  validate { opts = { opts, "t", true } }
  a.nvim_clear_autocmds(merge_opts(opts or {}, self._ctx))
end

--      event and pattern proxy methods

function Event:__index(k)
  local method = rawget(Event, k)

  if method then
    return method
  elseif self._ctx.pattern or self._ctx.buffer then
    return nil  -- no nested objects
  end

  local ctx = merge_opts(self._ctx, { pattern = k })    -- use key to specify pattern
  return create_event_object(self._event, ctx)          -- return Event obj with pattern
end

--- Create an autocmd for the event or events.
---@param action string|function: a callback or command to be executed when the autocommand triggers
---@param opts table}nil:
function Event:__call(action, opts)
  validate {
    action = { action, {"s", "f"} },
    opts = { opts, "t", true },
  }

  opts = merge_opts(opts or {}, self._ctx)

  if type(action) == "string" and action[1] == ":" then
    opts.command = action:sub(2)
  else
    opts.callback = action
  end

  return a.nvim_create_autocmd(self._event, opts)
end

--- Execute autocmds matching this event or events
---@param opts table|nil:
function Event:exec(opts)
  validate { opts = { opts, "t", true } }
  opts = merge_opts(opts or {}, self._ctx)
  return a.nvim_exec_autocmds(self._event, opts)
end

--- Get autocmds for the event
---@param opts table|nil:
function Event:get(opts)
  validate { opts = { opts, "t", true } }
  opts = merge_opts(opts or {}, self._ctx)
  opts.event = self._event
  return a.nvim_get_autocmds(opts)
end

function Event:clear(opts)
  validate { opts = { opts, "t", true } }
  opts = merge_opts(opts or {}, self._ctx)
  opts.event = self._event
  return a.nvim_clear_autocmds(opts)
end

--      augroup methods

Augroup.__index = Augroup

--- Define autocommands in the augroup by calling it with a spec function as
--- the argument. It will call |nvim_create_augroup()|, then call your spec
--- function with a single argument which is an Autocmd object that will pass
--- in the group name when you call its methods.
--
---@param spec function: a function that defines one parameter which is used in the body to create autocmds
function Augroup:__call(spec)
  validate { spec = { spec, "f" } }
  a.nvim_create_augroup(self._ctx.group, { clear = false })
  return spec(self._au)
end

--- Check if a group with this name exists.
---@return boolean: false if deleted or not created
function Augroup:exists()
  local res = pcall(a.nvim_get_autocmds, { group = self._ctx.group })
  return (res)  -- adjusted to one result
end

--- Create the group.
---@param clear boolean|nil: defaults to false; clear the group if it already exists
---@return number: the id of the group
function Augroup:create(clear)
  return a.nvim_create_augroup(self._ctx.group, { clear = (clear == true) })
end

--- Delete the group
function Augroup:del()
  a.nvim_del_augroup_by_name(self._ctx.group)
end

Augroup.get = Autocmd.get
Augroup.clear = Autocmd.clear



local M = {}

M.cmd = create_autocmd_object({})

M.group = setmetatable({}, {
  __index = function(_, name)
    return create_augroup_object(name)
  end,
})

function M.setup(opts)
  opts = opts or {}
  _G.vim.autocmd = opts.set_vim_autocmd ~= false and M.cmd or nil
  _G.vim.augroup = opts.set_vim_augroup ~= false and M.group or nil
end

return M
