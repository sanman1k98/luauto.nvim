local M = {}  -- "auto"
local Group, Event = {}, {}
-- stores names of objects
local info = setmetatable({}, { __mode = "k" })
local api, validate = vim.api, vim.validate



--- Wrapper around autocommand API functions.
--- - cmd.del = nvim_del_autocmd
--- - cmd.clear = nvim_clear_autocmds
--- - cmd.exec = nvim_exec_autocmds
--- - cmd.get = nvim_get_autocmds
--- - cmd = nvim_create_autocmds
--
--- `cmd` can be called with the exact same arguments as `nvim_create_autocmd`
--- or if you are specifying a Vim command to be executed when this autocommand
--- triggers, you can pass it in as a string between the event and opts table
--- arguments.
M.cmd = setmetatable({
  del = api.nvim_del_autocmd,
  clear = api.nvim_clear_autocmds,
  exec = api.nvim_exec_autocmds,
  get = api.nvim_get_autocmds,
}, {
  __call = function(_, ...)
    local args = {...}
    if type(args[2]) == "table" then
      return api.nvim_create_autocmd(args[1], args[2])
    end
    local event, command, opts = ...
    validate {
      event = { event, {"s", "t"} },
      command = { command, "s" },
      opts = { opts, "t", true },
    }
    opts = opts or {}
    opts.command = command
    return api.nvim_create_autocmd(event, opts)
  end,
})



M.cb = function(event, cb, opts)
  validate {
    event = { event, {"s", "t"} },
    callback = { cb, {"s", "f"} },
    opts = { opts, "t", true },
  }
  local opts = opts or {}
  opts.callback = cb
  return api.nvim_create_autocmd(event, opts)
end



function Group:_proxy(name)
  local p = {}
  info[p] = name
  return setmetatable(p, self)
end

function Group:create()
  local id = api.nvim_create_augroup(info[self], { clear = false })
  return id
end

function Group:clear(opts)
  validate { opts = { opts, "t", true }, }
  if not opts then
    return api.nvim_create_augroup(info[self], { clear = true })
  else
    opts.group = info[self]
    M.cmd.clear(opts)
  end
end

function Group:del()
  api.nvim_del_augroup_by_name(info[self])
  self = nil
end

function Group:get_name()
  return info[self]
end

function Group:get_id()
  return api.nvim_create_augroup(info[self], { clear = false })
end

function Group:get_cmds(opts)
  validate { opts = { opts, "t", true }, }
  opts.group = info[self]
  return M.cmd.get(opts)
end

function Group:cmd(event, ...)
  local arg2, arg3 = ...
  validate {
    event = { event, {"s", "t"} },
    arg2 = { arg2, {"t", "s" } },
    arg3 = { arg3, "t", true },
  }
  if type(arg2) == "table" then
    arg2.group = info[self]
    return M.cmd(event, arg2)
  else
    local opts = arg3 or {}
    opts.command = arg2
    opts.group = info[self]
    return M.cmd(event, opts)
  end
end

function Group:cb(event, cb, opts)
  validate {
    event = { event, {"s", "t"} },
    callback = { cb, {"s", "f"} },
    opts = { opts, "t", true },
  }
  local opts = opts or {}
  opts.callback = cb
  return M.cmd(event, opts)
end

function Group:define(cmds)
  validate { autocmds = { cmds, function (x)
    return x == nil or vim.tbl_islist(x)
  end, "list" } }
  local autocmd_ids = {}
  for i, cmd in ipairs(cmds) do
    local event, opts = cmd[1], cmd[2]
    autocmd_ids[i] = Group.cmd(self, event, opts)
  end
  return autocmd_ids
end

function Group:__index(k)
  if k == "id" then return Group.get_id(self)
  elseif k == "name" then return Group.get_name(self)
  else
    local v = rawget(Group, k)
    rawset(self, k, v)
    return v
  end
end

function Group:__newindex(k, v)
  if k == "id" or k == "name" then
    error("attempting to modify a read-only field", 2)
  else
    rawset(self, k, v)
  end
end

function Group:__call(...)
  return Group.define(self, ...)
end

M.group = setmetatable({}, {
  __index = function(self, k)
    local v = Group:_proxy(k)
    rawset(self, k, v)
    return v
  end,
  __mode = "v"
})



function Event:_proxy(name)
  local p = {}
  info[p] = name
  return setmetatable(p, self)
end

function Event:cmd(...)
  return M.cmd(info[self], ...)
end

function Event.cb(...)
  return M.cb(info[self], ...)
end

function Event:exec(opts)
  validate { opts = { opts, "t", true } }
  opts = opts or {}
  return M.cmd.exec(info[self], opts)
end

function Event:get_cmds(opts)
  validate { opts = { opts, "t", true } }
  opts = opts or {}
  opts.event = info[self]
  return M.cmd.get(opts)
end

function Event:clear(opts)
  validate { opts = { opts, "t", true } }
  opts = opts or {}
  opts.event = info[self]
  return M.cmd.clear(opts)
end

function Event:is_ignored()
  for _, event in ipairs(vim.opt.eventignore:get()) do
    event = string.lower(event)
    if event == info[self] then
      return true
    end
  end
  return false
end

function Event:set_ignore(flag)
  if flag then vim.opt.eventignore:append(info[self])
  else vim.opt.eventignore:remove(info[self]) end
end

function Event:get_name()
  return info[self]
end

function Event:__index(k)
  if k == "name" then
    return info[self]
  elseif k == "ignore" then
    return Event.is_ignored(self)
  else
    local v = Event[k]
    rawset(self, k, v)
    return v
  end
end

function Event:__newindex(k, v)
  if k == "name" then
    error("attempting to modify a read-only field", 2)
  elseif k == "ignore" then
    Event.set_ignore(self, v)
  else
    rawset(self, k, v)
  end
end

--- Shorthand for creating an autocommand for the event.
function Event:__call(...)
  return Event.cmd(self, ...)
end


--- Indexable by event names, which are case-insensitive.
M.event = setmetatable({}, {
  __index = function(self, key)
    local proxy = rawget(self, key:lower())
    if not proxy then
      proxy = Event:_proxy(key:lower())
      rawset(self, key:lower(), proxy)
    end
    rawset(self, key, proxy)
    return proxy
  end,
  __mode = "v",
})



return setmetatable(M, {
  __index = function(self, k)
    if k == "user" then
      local v = require "luauto.user"
      rawset(self, k, v)
      return v
    else
      return nil
    end
  end,
})
