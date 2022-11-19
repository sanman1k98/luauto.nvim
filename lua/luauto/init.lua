local M = {
  cmd = {}, group = {}
}
local Group, Event = {}, {}

local group_mem = setmetatable({}, { __mode = "v" })
local event_mem = setmetatable({}, { __mode = "v" })
local private = setmetatable({}, { __mode = "k" })
local api, validate = vim.api, vim.validate



function M.cmd:del(id)
  api.nvim_del_autocmd(id)
end

function M.cmd:clear(opts)
  api.nvim_clear_autocmds(opts)
end

function M.cmd:get(opts)
  return api.nvim_get_autocmds(opts)
end

function M.cmd:exec(event, opts)
  api.nvim_exec_autocmds(opts)
end

do
  local function event_proxy(name)
    name = name:lower()     -- event names are case-insensitive
    if event_mem[name] then return event_mem[name] end
    local proxy = {}
    event_mem[name] = proxy
    private[proxy] = { event = name }
    return setmetatable(proxy, Event)
  end

  local mt = {
    __index = function(_, k)
      return event_proxy(k)
    end,

    __call = function(_, event, action, opts)
      validate {
        event = { event, {"s", "t"} },
        action = { action, {"s", "f"} },
        opts = { opts, "t", true },
      }
      opts = opts or {}
      if type(action) == "string" and action[1] == ":" then
        opts.command = action
      else
        opts.callback = action
      end
      return api.nvim_create_autocmd(event, opts)
    end,
  }

  M.cmd = setmetatable(M.cmd, mt)
end

function Event:clear(opts)
  validate { opts = { opts, "t", true } }
  opts = opts or {}
  M.cmd.clear(opts)
end

function Event:get(opts)
  validate { opts = { opts, "t", true } }
  opts = opts or {}
  opts.event = private[self].event
  return M.cmd:get(opts)
end

function Event:exec(opts)
  validate { opts = { opts, "t", true } }
  M.cmd:exec(private[self].event, opts)
end

function Event:info()
  return private[self]
end

function Event:__call(action, opts)
  validate {
    action = { action, {"s", "f"} },
    opts = { opts, "t", true },
  }
  return M.cmd(private[self].event, action, opts)
end

Event.__index = Event

function Group:create()
  return api.nvim_create_augroup(private[self].group, { clear = false })
end

function Group:info()
  local info = {}
  info.group = private[self].group
  info.id = Group.create(self)
  return info
end

function Group:clear(opts)
  validate { opts = { opts, "t", true } }
  if not opts then
    return api.nvim_create_augroup(private[self].group, { clear = true })
  else
    M.cmd:clear(opts)
  end
end

function Group:del()
  api.nvim_del_augroup_by_name(private[self].group)
  self = nil
end

function Group:get(opts)
  validate { opts = { opts, "t", true } }
  opts = opts or {}
  opts.group = private[self].group
  return M.cmd:get(opts)
end

function Group:exec(event, opts)
  validate {
    event = { event, {"s", "t"} },
    opts = { opts, "t", true },
  }
  opts = opts or {}
  opts.group = private[self].group
  M.cmd:exec(event, opts)
end

function Group:define(...)
  Group.create(self)
  local args = {...}
  if vim.is_callable(args[1]) then
    local spec_func = args[1]
    local au = setmetatable({
      clear = function()
        Group.clear(self)
      end,
    }, {
      __index = function(_, k)
        return (function(action, opts)
          validate {
            action = { action, {"s", "f"} },
            opts = { opts, "t", true },
          }
          opts = opts or {}
          opts.group = private[self].group
          M.cmd(k, action, opts)
        end)
      end,
    })
    return spec_func(au)
  else
    for _, autocmd in ipairs(args) do
      assert(type(autocmd) == "table")
      M.cmd(autocmd[1], autocmd[2], autocmd[3])
    end
  end
end

function Group:__index(k)
  if k == "id" then
    return Group.create(self)
  else
    return Group[k]
  end
end

function Group:__newindex(k, v)
  if k == "id" then
    error("attempting to modify a read-only field: " .. k, 2)
  else
    rawset(self, k, v)
  end
end

Group.__call = Group.define

do
  local function group_proxy(name)
    if group_mem[name] then return group_mem[name] end
    local proxy = {}
    group_mem[name] = proxy
    private[proxy] = { group = name }
    return setmetatable(proxy, Group)
  end

  local mt = {
    __index = function(_, k)
      return group_proxy(k)
    end,
  }

  M.group = setmetatable(M.group, mt)
end



return M
