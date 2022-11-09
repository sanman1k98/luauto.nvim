local api = {
  exec = vim.api.nvim_exec_autocmds,
}


local methods = {
  exec = function(self, data, opts)
    opts = opts or {}
    opts.data = data
    opts.pattern = self._pattern
    api.exec(self._event, opts)
  end,
}


local pattern = function(event_tbl, key)
  return rawset(event_tbl, "_pattern", key)
end


--- Creates and returns a table which can access functions as methods.
---@return table: 
local event = function(name)
  return setmetatable({ _event = name }, {
    __index = function(self, key)
      local method = methods[key]
      if method then
        return method
      else return pattern(self, key) end
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
