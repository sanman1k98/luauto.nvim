
-- TODO: validate parameters
local methods = {
  exec = function(self, data, opts)
    opts = opts or {}
    opts.data = data
    opts.pattern = rawget(self, "_pattern")
    opts.buffer = rawget(self, "_buffer")
    vim.api.nvim_exec_autocmds(self._event, opts)
  end,
  get = function(self, opts)
    opts = opts or {}
    opts.event = self._event
    opts.pattern = rawget(self, "_pattern")
    opts.buffer = rawget(self, "_buffer")
    return vim.api.nvim_get_autocmds(opts)
  end,
}


local pattern_tbl = function(event, pat)
  return setmetatable({ _event = event, _pattern = pat }, {
    __index = methods,
    __call = methods.exec,
  })
end


local buffer_tbl = function(event, buf)
  return setmetatable({ _event = event, _buffer = buf }, {
    __index = methods,
    __call = methods.exec
  })
end


local accessor_tbl = function(event, key)
  if key == "buffer" or key == "buf" then
    return setmetatable({}, {
      __index = function(_, buf) return buffer_tbl(event, buf) end,
      __call = function(_, buflist) return buffer_tbl(event, buflist) end,
    })
  elseif key == "pattern" or key == "pat" then
    return setmetatable({}, {
      __index = function(_, pat) return pattern_tbl(event, pat) end,
      __call = function(_, patterns) return pattern_tbl(event, patterns) end,
    })
  else
    return pattern_tbl(event, key)
  end
end


--- Creates and returns a table which can access functions as methods.
---@return table: 
local event = function(event)
  return setmetatable({ _event = event }, {
    __index = function(_, key)
      return methods[key] or accessor_tbl(event, key)
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
