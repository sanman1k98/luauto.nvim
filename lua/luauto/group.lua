local group_mt = {}

local mem = setmetatable({}, { __mode = "v" })
local attr = setmetatable({}, { __mode = "k" })

local a, validate = vim.api, vim.validate

local events = require "luauto.events"




--- Create this autogroup without clearing it.
---@return integer: this group's id
function group_mt:create()
  return a.nvim_create_augroup(attr[self].name, { clear = false })
end


--- Clear the autogroup.
---@return integer: this group's id
function group_mt:clear(opts)
  validate { opts = { opts, "t", true } }
  if not opts or vim.tbl_isempty(opts) then
    return a.nvim_create_augroup(attr[self].name, { clear = true })
  else
    opts = opts or {}
    opts.group = attr[self].name
    a.nvim_clear_autocmds(opts)
  end
end


--- Delete the autogroup and remove this object from the table "mem".
function group_mt:del()
  a.nvim_del_augroup_by_name(attr[self].name)
  self = nil
end


function group_mt:get(opts)
  validate { opts = { opts, "t", true } }
  opts = opts or {}
  opts.group = atrr[self].name
  return a.nvim_get_autocmds(opts)
end


function group_mt:exec(event, opts)
  validate {
    event = { event, {"s", "t"} },
    opts = { opts, "t", true },
  }
  opts = opts or {}
  opts.group = attr[self].name
  return a.nvim_exec_autocmds(event, opts)
end


function group_mt:__index(k)
  if k == "id" then
    return group_mt.create(self)
  elseif k == "au" or k == "autocmd" then
    return attr[self].autocmd
  else
    local v = rawget(group_mt, k)
    rawset(self, k, v)
    return v
  end
end


function group_mt:__newindex(k, v)
  if k == "id" or k == "au" or k == "autocmd" then
    error("attempting to modify a read-only field", 2)
  else
    rawset(self, k, v)
  end
end


function group_mt:__call(...)
  group_mt.create(self)
  local au = attr[self].autocmd
  local spec = ...
  if vim.is_callable(spec) then
    return spec(au)
  else
    for _, cmd in ipairs{...} do
      assert(type(cmd) == "table")
      au(cmd[1], cmd[2], cmd[3])
    end
  end
end


local function get_group(name)
  if mem[name] then return mem[name] end
  local group = {}
  mem[name] = group
  attr[group] = { name = name }
  local au = setmetatable({}, { })
  attr[group].au = au
  return setmetatable(group, group_mt)
end

return setmetatable({}, {
  __index = function(self, k)

  end,
  __mode = "v",
})
