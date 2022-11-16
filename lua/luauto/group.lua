local M = {}
local Group, GroupProxy = {}, {}
local mem = setmetatable({}, { __mode = "v" })    -- stores objects by group name
local info = setmetatable({}, { __mode = "k" })

local au = require "luauto.cmd"



--- Returns a new proxy table.
function Group:proxy(name)
  local proxy = {}
  rawset(M, name, proxy)            -- add it to this module
  info[proxy] = name                -- save private attributes
  return setmetatable(proxy, self)  -- return created proxy
end


-- Create multiple autocommands in this group.
function Group:define(autocmds)
  if autocmds == nil then return Group.id(self)
  elseif not vim.tbl_islist(autocmds) then
    error("expecting argument to be a list", 2)
  else
    local ids = {}
    for i, cmd in ipairs(autocmds) do
      local event, opts = cmd[1], cmd[2]
      ids[i] = Group.add(self, event, opts)
    end
    return ids
  end
end


--- Create an autocommand in this group.
function Group:add(event, opts)
  if type(opts) ~= "table" then error("expecting a table as second argument", 2) end
  opts.group = info[self]
  return vim.api.nvim_create_autocmd(event, opts)
end


--- Create this autogroup without clearing it.
---@return table: self
---@return integer: this group's id
function Group:create()
  local id = vim.api.nvim_create_augroup(info[self], { clear = false })
  return self, id
end


--- Clear the autogroup this abject represents and return itself.
---@return table: self
---@return integer: this group's id
function Group:clear()
  local id = vim.api.nvim_create_augroup(info[self], { clear = true })
  return self, id
end


--- Delete the autogroup and remove this object from the table "mem".
function Group:del()
  vim.api.nvim_del_augroup_by_name(info[self])
  self = nil
end


function Group:get_cmds(opts)
  opts = opts or {}
  opts.group = info[self]
  return vim.api.nvim_get_autocmds(opts)
end


function Group:exec(event, opts)
  opts = opts or {}
  opts.group = info[self]
  return vim.api.nvim_exec_autocmds(event, opts)
end


--- Get the id of this group.
function Group:get_id()
  return vim.api.nvim_create_augroup(info[self], { clear = false })
end


--- Get the name of the group this proxy table represents.
function Group:get_name()
  return info[self]
end


function Group:__index(k)
  if k == "id" then
    return rawget(Group, "get_id")(self)
  elseif k == "name" then
    return rawget(Group, "get_name")(self)
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


--- Shorthand for creating a number of autocommands in a group.
function Group:__call(...)
  return Group.define(self, ...)
end


function GroupProxy:get(aug_name)
  if M[aug_name] then return M[aug_name] end
  local proxy = {}
  M[aug_name] = proxy
  info[proxy] = aug_name
  return setmetatable(proxy, self)
end


function GroupProxy:__index(k)
  if k == "id" then
    return Group.id(self)
  elseif k == "name" then
    return Group.name(self)
  elseif k == "cmds" then
    return Group.get_cmds(self)
  else
    local v = Group[k]
    rawset(self, k, v)
    return v
  end
end


function GroupProxy:__newindex(k, v)
  if k == "id" or k == "name" or k == "cmds" then
    error("attempting to modify a read-only field", 2)
  else
    rawset(self, k, v)
  end
end


function GroupProxy:__call(...)
  return Group.define(self, ...)
end


return setmetatable(M, {
  __index = function(_, aug_name)
    return Group:proxy(aug_name)
  end,
  __mode = "v",
})
