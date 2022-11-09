local api = {
  exec = vim.api.nvim_exec_autocmds,
}


local operations = {
  exec = function(self, data, opts)
    opts = opts or {}
    opts.data = data
    opts.pattern = self._pattern
    api.exec(self._event, opts)
  end,
}


local pattern = function(tbl, key)
  assert(getmetatable(tbl), "it should already have a metatable")
  return rawset(tbl, "_pattern", key)
end


--- Creates and returns a table which can access functions as methods.
---@return table: 
local event = function(key)
  return setmetatable({ _event = key }, {
    __index = function(self, k)
      if operations[k] then return operations[k]
      else return pattern(self, k) end
    end,
  })
end


-- When this module is indexed with an event name, it returns a table which can
-- access methods to perform various operations:
-- - execute all autocommands for that event
-- - get a list of autocommands for that event
-- - clear autocommands for that event
return setmetatable({}, {
  __index = function(_, key)
    return event(key)
  end,
})
