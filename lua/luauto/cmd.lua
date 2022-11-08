local M = {}

local api = {
  create = vim.api.nvim_create_autocmd,
  get = vim.api.nvim_get_autocmds,
  del = vim.api.nvim_del_autocmd,
  clear = vim.api.nvim_clear_autocmds,
}


function M.add(tbl)
  if type(tbl) ~= "table" then error("expects a table as an argument", 2) end
  local cmd = tbl[1] or tbl.cmd or tbl.command
  local cb = tbl.cb or tbl.callback
  vim.validate {
    on = { tbl.on, {"s", "t"} },
    command = { cmd, "s", true },
    callback = { cb, {"s", "f"}, true },
    group = { tbl.group, {"s", "n"}, true },
    description = { tbl.desc, "s", true },
    once = { tbl.once, "b", true },
    nested = { tbl.nested, "b", true },
  }
  -- true if present and false if not present
  assert((cmd and true or false) ~= (cb and true or false), "expects either a callback or command but not both")

end


function M.del(id)
end


function M.get(tbl)
end


function M.clear(tbl)
end


do
  M.create = M.add

  setmetatable(M, {
    __call = M.add,
  })
end


return M
