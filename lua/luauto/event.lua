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


local event_pattern = function(event, pat)
  return setmetatable({ _event = event, _pattern = pat }, {
    __index = function(_, key)
      if key == "patterns" then error("cannot call method `patterns` on this table", 2)
      else return methods[key] end
    end,
    __call = methods.exec,
  })
end


--- Creates and returns a table which can access functions as methods.
---@return table: 
local event = function(event)
  return setmetatable({ _event = event }, {
    __index = function(_, key)
      return methods[key] or event_pattern(event, key)
    end,
    __call = methods.exec,
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
