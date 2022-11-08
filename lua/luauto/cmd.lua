local M = {}

local api = {
  create = vim.api.nvim_create_autocmd,
  get = vim.api.nvim_get_autocmds,
  del = vim.api.nvim_del_autocmd,
  clear = vim.api.nvim_clear_autocmds,
}


--- Add a callback/command to the list of commands and callbacks that Neovim
--- will execute automatically on one or more events. Returns the id of the
--- newly created autocommand.
---@param tbl table: dictionary of autocommand options
---@field cmd string: vim command to execute; cannot be used with cb
---@field command string: alias for cmd
---@field cb string|function: Lua function to call or name of a Vimscript function to call
---@field callback string|function: alias for cb
---@field on string|table: event or events to register this autocommand
---@field group string|number: autocommand group name or id to match against
---@field desc string: description of the autocommand
---@field once boolean: run the autocommand only once; defaults to false
---@field nested boolean: run nested autocommands; defaults to false
---@return number: integer id of the created autocommand
function M.add(tbl)
  if type(tbl) ~= "table" then error("expects a table as an argument", 2) end
  local cmd = tbl[1] or tbl.cmd or tbl.command
  local cb = tbl.cb or tbl.callback
  vim.validate {
    on = { tbl.on, {"s", "t"} },
    command = { cmd, "s", true },
    callback = { cb, {"s", "f"}, true },
    group = { tbl.group, {"s", "n"}, true },
    description = { tbl.desc, "s", true },
    once = { tbl.once, "b", true },
    nested = { tbl.nested, "b", true },
  }
  -- true if present and false if not present
  assert((cmd and true or false) ~= (cb and true or false), "expects either a callback or command but not both")

end


--- Delete an autocommand given its id.
---@param id number: id of the autocommand to delete
function M.del(id)
end


--- Get all autocommands that match the corresponding opts.
---@param opts table: dictionary containing at least one option to match against
---@field group string|number: autocommand group name or id
---@field event string|table: event(s)
---@field pattern string|table: pattern(s); cannot be used with buffer
---@field buffer number|table: buffer number(s); cannot be used with pattern
---@return table: a list of autocommands matching the criteria
function M.get(opts)
end


--- Clear all autocommands that match the corresponding opts.
---@param opts table: dictionary containing at least one option to match against
---@field group string|number: autocommand group name or id
---@field event string|table: event(s)
---@field pattern string|table: pattern(s); cannot be used with buffer
---@field buffer number|table: buffer number(s); cannot be used with pattern
---@return table: a list of autocommands matching the criteria
function M.clear(opts)
end


do
  M.create = M.add

  setmetatable(M, {
    __call = M.add,
  })
end


return M
