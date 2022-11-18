local api, validate = vim.api, vim.validate

local M = {
  cmd = api.nvim_create_autocmd,
  del = api.nvim_del_autocmd,
  clear = api.nvim_clear_autocmds,
  get = api.nvim_get_autocmds,
  exec = api.nvim_exec_autocmds,
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
function M.new(opts)
  if type(opts) ~= "table" then error("expects a table as an argument", 2) end
  local event = opts.on or opts.event
  local cmd = opts.cmd or opts.command
  local cb = opts.cb or opts.callback
  vim.validate {
    event = { event, {"s", "t"} },
    pattern = { opts.pattern, {"s", "t"}, true },
    buffer = { opts.buf, "n", true },
    command = { cmd, "s", true },
    callback = { cb, {"s", "f"}, true },
    group = { opts.group, {"s", "n"}, true },
    description = { opts.desc, "s", true },
    once = { opts.once, "b", true },
    nested = { opts.nested, "b", true },
  }
  -- true if present and false if not present
  assert((cmd and true or false) ~= (cb and true or false), "expects either a callback or command but not both")
  assert(not (opts.pattern and opts.buf), "cannot supply a buffer number and pattern(s)")

  return vim.api.nvim_create_autocmd(event, {
    group = opts.group,
    pattern = opts.pattern,
    buffer = opts.buf,
    desc = opts.desc,
    callback = cb,
    command = cmd,
    once = opts.once,
    nested = opts.nested,
  })
end


function M.cb(callback, opts)
  if type(opts) ~= "table" then error("expecting table as second argument", 2) end
  local event = opts.on or opts.event
  opts.on, opts.event = nil, nil
  opts.callback = callback
  return vim.api.nvim_create_autocmd(event, opts)
end


M.cmd = vim.api.nvim_create_autocmd
M.del = vim.api.nvim_del_autocmd
M.get = vim.api.nvim_get_autocmds
M.clear = vim.api.nvim_clear_autocmds
M.exec = vim.api.nvim_exec_autocmds


M.add = M.new
M.create = M.new


return setmetatable(M, {
  __call = M.new,
})
