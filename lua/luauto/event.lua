local M = {}
local Event = {}
local info = setmetatable({}, { __mode = "v" })

local au = require "luauto.cmd"


function Event:_proxy(name)
  local proxy = {}
  info[proxy] = name
  return setmetatable(proxy, self)
end


function Event:create_cmd(opts)
  return vim.api.nvim_create_autocmd(info[self], opts)
end


--- Execute all autocommands for this event matching opts.
function Event:exec(opts)
  opts = opts or {}
  vim.api.nvim_exec_autocmds(info[self], opts)
end


--- Get all autocommands for this event matching opts.
function Event:get_cmds(opts)
  opts = opts or {}
  opts.event = info[self]
  return vim.api.nvim_get_autocmds(opts)
end


--- Clear all autocommands for this event matching opts.
function Event:clear(opts)
  opts = opts or {}
  opts.event = info[self]
  vim.api.nvim_clear_autocmds(opts)
end


--- Get or set the the ignore setting for this event.
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
    return Event.get_name(self)
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
  return Event.create_cmd(...)
end


--- Index this module by event names, which are case-insensitive.
return setmetatable(M, {
  --- Contains logic for search and accessing values with case-insensitive
  --- keys.
  __index = function(self, key)
    local proxy = rawget(self, key:lower())   -- see what's at lowercased-key
    if proxy then                             -- if there's something there then,
      rawset(self, key, proxy)                -- set this key's value to what's at lowercased-key
      return proxy                            -- return the value
    else                                      -- if there's nothing there then,
      proxy = Event:_proxy(key:lower())        -- create a value
      rawset(self, key:lower(), proxy)        -- set the lowercased-key to the new value
      rawset(self, key, proxy)                -- set the original key to the new value too, since we might access it again this way
      return proxy                            -- return the value
    end
  end,
  __mode = "v",
})
