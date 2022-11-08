local M = {}

local api = {
  create = vim.api.nvim_create_autocmd,
  get = vim.api.nvim_get_autocmds,
  del = vim.api.nvim_del_autocmd,
  clear = vim.api.nvim_clear_autocmds,
}


function M.add(tbl)
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
