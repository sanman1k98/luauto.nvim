local cmd = require "luauto.cmd"

local api = {
  create = vim.api.nvim_create_augroup,
  del_by_id = vim.api.nvim_del_augroup_by_id,
  clear = vim.api.nvim_clear_autocmds,
}


local group_mt = {
  --- Add an autocommand to this group by passing in a dictionary of opts.
  ---@param opts table: a dictionary of autocommmand options
  ---@see `luauto.cmd.add`
  add = function(self, opts)
    if type(opts) ~= "table" then error("expects a table as an argument", 2) end
    opts.group = self._name
    return cmd.add(opts)
  end,

  clear = function(self)
    api.create(self._name, { clear = true })
  end,

  del = function(self)
    api.del_by_id(self.id)
  end,

  --- Get a list of autocommands in this group.
  ---@param opts table: a dictionary containing other criteria to match against
  ---@return table: a list of autocommands matching the criteria
  ---@see `luauto.cmd.get`
  get_cmds = function(self, opts)
    opts = opts or {}
    opts.group = self.id
    return cmd.get(opts)
  end,
}


--- Returns a table that can manage and operate on the autogroup with the given name.
---@param name string: name of a new or existing autogroup
---@return table: a table to manage an autogroup
---@see $VIMEUNTIME/lua/vim/_meta.lua for inspiring this implementation
local group = function(name)
  local id = api.create(name, { clear = false })
  return setmetatable({
    id = id,
    _name = name,
  }, {
    __index = group_mt,
  })
end


return setmetatable({}, {
  __index = function(_, name)
    return group(name)
  end
})