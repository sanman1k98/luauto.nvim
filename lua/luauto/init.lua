local autocmd = {}
local augroup = require "luauto.group"

local global_events = require("luauto.events")()

local a, validate = vim.api, vim.validate



---@param event string|table: event or events to register this autocmd for
---@param action function|string: Vim command prefixed with ":", the name of a Vim function, or a Lua function
---@param opts table|nil: a dictionary of autocmd options
---@return id number: integer id of the created autocmd
---@see nvim_create_autocmd()
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

autocmd = setmetatable(autocmd, {
  __index = global_events,
  __call = function(_, ...) return create_autocmd(...) end
})


return {
  cmd = autocmd,
  group = augroup
}
