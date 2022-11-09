
-- TODO: validate parameters
local methods = {
  exec = function(self, data, opts)
    opts = opts or {}
    opts.data = data
    opts.pattern = rawget(self, "_pattern")
    vim.api.nvim_exec_autocmds(self._event, opts)
  end,
  get = function(self, opts)
    opts = opts or {}
    opts.event = self._event
    opts.pattern = rawget(self, "_pattern")
    return vim.api.nvim_get_autocmds(opts)
  end,
  patterns = function(self, tbl)
    return rawset(self, "_pattern", tbl)
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
