---@class Context @Autocommand options passed from parent objects.
---@field group? string group name
---@field buffer? number|boolean specifies a buffer; use 0 or true for the current buffer
---@field pattern? string|string[] pattern or list of patterns

---@class AutocmdOptions: Context @Dictionary of autocommand options.
---@field desc? string description of the autocommand
---@field once? boolean run the autocommand only once (defaults to false)
---@field nested? boolean run nested autocommands (defaults to false)

---@class AutocmdFilter @A table with key-value pairs to filter autocommands.
---@field group? string|integer group name or id
---@field buffer? integer|integer[] buffer or list of buffer numbers
---@field pattern? string|string[] pattern or list of patterns
---@field event? string|string[] event or list of events

---@class AutocmdCallbackArg
---@field id integer
---@field event string
---@field group? integer
---@field match string
---@field buf? integer
---@field file? string
---@field data any

---@alias EventName string|string[]
---@alias PatternName string|string[]
---@alias Pattern Event has a pattern specified in its context
---@alias BuflocalAutocmd Autocmd|{[integer]:BuflocalAutocmd?} has a buffer specified in its context

---@class Autocmd: {[EventName]:Event} @Indexable by event name. Can also get and clear autocommands.
---@field private _ctx Context passed to Event objects
---@field buf BuflocalAutocmd
---@field get function
---@field clear function
local Autocmd = {}

---@class Event: {[PatternName]: Pattern?} @Create, get, exec, and clear autocommands for an event. Can be indexed further to specify a pattern.
---@field private _event EventName
---@field private _ctx Context
---@field __call function create an autocommand for this event
---@field get function
---@field exec function
---@field clear function
local Event = {}

---@alias AugroupSpec fun(au: Autocmd): any

---@class Augroup
---@field private _au Autocmd used to create autocommands
---@field private _ctx Context has group specified
---@field __call function define autocommands in this group
---@field get function
---@field del function
---@field clear function
---@field create function
local Augroup = {}

local a, validate = vim.api, vim.validate

---@private
local function merge_opts(...)
  local opts = vim.tbl_extend("force", ...)
  if opts.buffer and opts.pattern then
    error("cannot specify a pattern for a buf-local autocmd", 2)
  end
  return opts
end



--      constructors

---@param ctx Context
---@return Autocmd
---@private
local function create_autocmd_object(ctx)
  local self = {
    _ctx = ctx
  }
  return setmetatable(self, Autocmd)
end

---@param event EventName
---@param ctx Context
---@return Event
---@private
local function create_event_object(event, ctx)
  local self = {
    _event = event,
    _ctx = ctx,
  }
  return setmetatable(self, Event)
end

---@param name string
---@return Augroup
local function create_augroup_object(name)
  local ctx = { group = name }
  local self = {
    _au = create_autocmd_object(ctx),
    _ctx = ctx,
  }
  return setmetatable(self, Augroup)
end



--      autocmd methods

---@return function|Event|BuflocalAutocmd
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

--- Get autocommands that match the given criteria.
---@param opts AutocmdFilter table of key-value pairs to specify which autocommands to return
---@return table #list of autocommands
---@see nvim_get_autocmds()
function Autocmd:get(opts)
  validate { opts = { opts, "t", true } }
  return a.nvim_get_autocmds(merge_opts(opts or {}, self._ctx))
end

--- Clear autocommands that match the given criteria.
---@see nvim_clear_autocmds()
---@param opts AutocmdFilter table of key-value pairs to specify what autocommands to clear.
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

--- Create an autocommand for this Event.
---@param action string|fun(e?:AutocmdCallbackArg):true? a Lua function, a Vim command prepended with ":", or a Vimscript function name
---@param opts? AutocmdOptions
---@see nvim_create_autocmd()
function Event:__call(action, opts)
  validate {
    action = { action, {"s", "f"} },
    opts = { opts, "t", true },
  }

  opts = merge_opts(opts or {}, self._ctx)

  if type(action) == "string" and action:sub(1, 1) == ":" then
    opts.command = action:sub(2)
  else
    opts.callback = action
  end

  return a.nvim_create_autocmd(self._event, opts)
end

---@class AutocmdExecOpts
---@field group? string|integer group name or id to match against
---@field patterm? string|string[]
---@field buffer? integer
---@field modeline? boolean default to true
---@field data? any arbitrary data to send to an autocommand callback handler

--- Execute autocmds matching this event or events
---@param opts? AutocmdExecOpts
---@see nvim_exec_autocmds()
function Event:exec(opts)
  validate { opts = { opts, "t", true } }
  opts = merge_opts(opts or {}, self._ctx)
  return a.nvim_exec_autocmds(self._event, opts)
end

--- Get autocmds for the event
---@param opts AutocmdFilter
---@see Autocmd.get()
---@see nvim_get_autocmds()
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
---@param spec AugroupSpec a function that defines one parameter which is used in the body to create autocmds
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
---@see nvim_del_augroup_by_name()
function Augroup:del()
  a.nvim_del_augroup_by_name(self._ctx.group)
end

Augroup.clear = Autocmd.clear
--- Get a list of autocommands in the group that match any given criteria. If
--- no argument is passed and the group has not yet been created, it will
--- return nil. Otherwise it behaves like `Autocmd:get()`.
---@param opts? AutocmdFilter
---@see nvim_get_autocmds()
function Augroup:get(opts)
  if not opts then
    local exists, list = pcall(a.nvim_get_autocmds, { group = self._ctx.group })
    return exists and list or nil
  else
    opts.group = self._ctx.group
    return a.nvim_get_autocmds(opts)
  end
end




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
