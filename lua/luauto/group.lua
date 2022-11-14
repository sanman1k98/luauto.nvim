local Group = {}
local mem = setmetatable({}, { __mode = "v" })    -- stores objects by group name
local info = setmetatable({}, { __mode = "k" })

local au = require "luauto.cmd"








--- Add a new autocommand to this group.
---@param opts table: a dictionary of options representing an autocommand
---@field NAME TYPE: DESC
---@field NAME TYPE: DESC
---@field NAME TYPE: DESC
---@field NAME TYPE: DESC
function Group:add(opts)
  if type(opts) ~= "table" then error(2, "expecting a table") end
  opts.group = info[self]
  return au.new(opts)
end


--- Clear the autogroup this abject represents and return itself.
---@return table: self
function Group:clear()
  vim.api.nvim_create_augroup(info[self], {})
  return self
end


--- Delete the autogroup and remove this object from the table "mem".
function Group:del()
  vim.api.nvim_del_augroup_by_name(info[self])
  mem[info[self]] = nil
  info[self] = nil
end


--- Get autocommands that are in this group and match any additional
--- corresponding opts.
---@param opts? table: a dictionary containing additional opts to match against
---@field NAME TYPE: DESC
---@field NAME TYPE: DESC
---@field NAME TYPE: DESC
---@field NAME TYPE: DESC
---@return table: a list of autocommands in this group and, if given, match the additional criteria.
---@field NAME TYPE: DESC
---@field NAME TYPE: DESC
---@field NAME TYPE: DESC
---@field NAME TYPE: DESC
function Group:cmds(opts)
  opts = opts or {}
  opts.group = info[self]
  return au.get(opts)
end


--- Execute all autocommands in this group for event that match the
--- corresponding opts.
---@param event string|table: event or events to execute
---@param opts? table: dictionary of autocommand options
---@field pattern string|table: pattern(s); cannot be used with buffer
---@field buffer number|table: buffer number(s); cannot be used with pattern
---@field data table: arbitrary data to send to the autocommand callback; see nvim_create_autocmd()
---@see nvim_exec_autocmds()
---@see luauto.cmd.exec()
function Group:exec(event, opts)
  opts = opts or {}
  opts.group = info[self]
  return au.exec(event, opts)
end


function Group:id()
  return vim.api.nvim_create_augroup(info[self], { clear = false })
end


function Group:name()
  return info[self]
end


--- Create a new Group object with "name" in the "mem" table if one doesn't
--- already exist.
---@param name string: name of the group
---@return table: an object representing a autogroup with methods to work with them
---@field id number: integer id of the autogroup
---@field name string: name of the autogroup
local function create_proxy(name)
  local tbl, mt = {}, {}
  mem[name] = tbl
  info[tbl] = name

  mt.__index = function(self, k)
    if k == "id" then
      return Group.id(self)
    elseif k == "name" then
      return Group.name(self)
    else
      return Group[k]
    end
  end

  mt.__newindex = function(self, k, v)
    if k == "id" or k == "name" then
      error("attempting to modify read-only field: " .. k, 2)
    else
      self[k] = v
    end
  end

  return setmetatable(tbl, mt)
end


return setmetatable({}, {
  __index = function(_, name)
    return mem[name] or create_proxy(name)
  end
})
