local M = {}

local api = {
  create = vim.api.nvim_create_autocmd,
  get = vim.api.nvim_get_autocmds,
  del = vim.api.nvim_del_autocmd,
  clear = vim.api.nvim_clear_autocmds,
}


--- Create a new autocommand which adds a callback/command to the list of
--- commands and callbacks that Neovim will execute automatically on one or
--- more events. Returns the id of the newly created autocommand.
---@param tbl table: dictionary of autocommand options
---@field cmd string: vim command to execute; cannot be used with cb
---@field command string: alias for cmd
---@field cb string|function: Lua function to call or name of a Vimscript function to call
---@field callback string|function: alias for cb
---@field on string|table: event or events to register this autocommand
---@field pattern string|table: pattern or patterns to match against; cannot be used with buf
---@field buf integer: buffer number for buffer-local autocommands; cannot be used with match
---@field group string|number: autocommand group name or id to match against
---@field desc string: description of the autocommand
---@field once boolean: run the autocommand only once; defaults to false
---@field nested boolean: run nested autocommands; defaults to false
---@return number: integer id of the created autocommand
---@see nvim_create_autocmd()
function M.new(tbl)
  if type(tbl) ~= "table" then error("expects a table as an argument", 2) end
  local cmd = tbl[1] or tbl.cmd or tbl.command
  local cb = tbl.cb or tbl.callback
  vim.validate {
    on = { tbl.on, {"s", "t"} },
    pattern = { tbl.pattern, {"s", "t"}, true },
    buffer = { tbl.buf, "n", true },
    command = { cmd, "s", true },
    callback = { cb, {"s", "f"}, true },
    group = { tbl.group, {"s", "n"}, true },
    description = { tbl.desc, "s", true },
    once = { tbl.once, "b", true },
    nested = { tbl.nested, "b", true },
  }
  -- true if present and false if not present
  assert((cmd and true or false) ~= (cb and true or false), "expects either a callback or command but not both")
  assert(not (tbl.pattern and tbl.buf), "cannot supply a buffer number and pattern(s)")

  return vim.api.nvim_create_autocmd(tbl.on, {
    group = tbl.group,
    pattern = tbl.pattern,
    buffer = tbl.buf,
    desc = tbl.desc,
    callback = cb,
    command = cmd,
    once = tbl.once,
    nested = tbl.nested,
  })
end


--- Delete an autocommand given its id.
---@param id number: id of the autocommand to delete
---@see nvim_del_autocmd()
function M.del(id)
  vim.api.nvim_del_autocmd(id)
end


--- Get all autocommands that match the corresponding opts.
---@param opts table: dictionary containing at least one option to match against
---@field group string|number: autocommand group name or id
---@field event string|table: event(s)
---@field pattern string|table: pattern(s); cannot be used with buffer
---@field buffer number|table: buffer number(s); cannot be used with pattern
---@return table: a list of autocommands matching the criteria
---@see nvim_get_autocmds()
function M.get(opts)
  return vim.api.nvim_get_autocmds(opts)
end


--- Clear all autocommands that match the corresponding opts.
---@param opts table: dictionary containing at least one option to match against
---@field group string|number: autocommand group name or id
---@field event string|table: event(s)
---@field pattern string|table: pattern(s); cannot be used with buffer
---@field buffer number|table: buffer number(s); cannot be used with pattern
---@see nvim_clear_autocmds()
function M.clear(opts)
  return vim.api.nvim_clear_autocmds(opts)
end


--- Execute all autocommands for event that match the corresponding opts.
---@param event string|table: event or events to execute
---@param opts? table: dictionary of autocommand options
---@field group string|number: autocommand group name or id
---@field event string|table: event(s)
---@field pattern string|table: pattern(s); cannot be used with buffer
---@field buffer number|table: buffer number(s); cannot be used with pattern
---@field data table: arbitrary data to send to the autocommand callback; see nvim_create_autocmd()
---@see nvim_exec_autocmds()
function M.exec(event, opts)
  vim.api.nvim_exec_autocmds(event, opts)
end


M.add = M.new
M.create = M.new


return setmetatable(M, {
  __call = M.new,
})
