local UserEvent = {}
local info = setmetatable({}, { __mode = "k" })

local au = require "luauto"



function UserEvent:_proxy(name)
  local p = {}
  info[p] = name
  return setmetatable(p, self)
end


--- Same method signature as luauto.cmd
function UserEvent:cmd(arg1, arg2)
  local command, opts
  if type(arg1) == "string" then
    command, opts = arg1, arg2 or {}
  else
    assert(type(arg1) == "table", "Vim command not specified as first argument; expecting opts table")
    command, opts = arg1.command, arg1
    assert(type(command) == "string", "Vim command specified in opts table should be a string")
  end
  opts.pattern = info[self]
  opts.command = command
  return vim.api.nvim_create_autocmd("User", opts)
end


function UserEvent:exec(data)
  local event, pattern = "User", info[self]
  vim.api.nvim_exec_autocmds(event, {
    pattern = pattern,
    data = data,
  })
end


function UserEvent:get_cmds(opts)
  opts = opts or {}
  opts.event, opts.pattern = "User", info[self]
  return vim.api.nvim_get_autocmds(opts)
end


function UserEvent:get_name()
  return info[self]
end


function UserEvent:exec_wrap()
  return (function(data) UserEvent.exec(self, data) end)
end


function UserEvent:__index(k)
  if k == "name" then
    return UserEvent.get_name(self)
  else
    local v = UserEvent[k]
    rawset(self, k, v)
    return v
  end
end


function UserEvent:__newindex(k, v)
  if k == "name" then
    error("attempting to modify a read-only field", 2)
  else
    rawset(self, k, v)
  end
end


function UserEvent:__call(...)
  return UserEvent.cmd(self, ...)
end


return setmetatable(M, {
  __index = function(self, k)
    local v = UserEvent:_proxy(k)
    rawset(self, k, v)
    return v
  end,
  __mode = "v",
})
