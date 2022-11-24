local group_mt = {}

local attr = setmetatable({}, { __mode = "k" })

local a, validate = vim.api, vim.validate


---@class autocmd @A table for managing autocmds.
---@field get function:
---@field exec function:
---@field clear function:
---@field <event> table:



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
  opts.group = attr[self].name
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
    return rawget(group_mt, k)
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
  local arg = {...}
  group_mt.create(self)
  local au = attr[self].autocmd
  local spec = ...
  if vim.is_callable(spec) then
    return spec(au)
  else
    for _, cmd in ipairs{...} do
      assert(type(cmd) == "table", "expecting arguments to be tables")
      au(cmd[1], cmd[2], cmd[3])
    end
  end
end


local function scoped_autocmd(group)
  local autocmd = {}
  function autocmd:clear(...) return group_mt.clear(group, ...) end
  function autocmd:get(...) return group_mt.get(group, ...) end
  function autocmd:exec(...) group_mt.exec(group, ...) end
  return setmetatable(autocmd, {
    __index = require("luauto.events") { group = attr[group].name },
    __call = function(_, event, action, opts)
    end,
  })
end

return setmetatable({}, {
  __index = function(self, k)
    local group = {}
    rawset(self, k, group)
    attr[group] = { name = k }
    attr[group].autocmd = scoped_autocmd(group)
    return setmetatable(group, group_mt)
  end,
  __mode = "v",
})
