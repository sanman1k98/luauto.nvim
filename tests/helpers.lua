local M = {}



M.api = setmetatable({}, {
  __index = function(_, k)
    return vim.api["nvim_" .. k]
  end,
})

function M.clear_all(group)
  api.clear_autocmds { group = group }
  api.clear_autocmds {}
end

function M.get_test_autocmds(group)
  return api.get_autocmds { event = "User", group = group }
end

function M.create_test_autocmds(group)
  local cb = function() end
  for i = 1, 10 do
    api.create_autocmd("User", {
      callback = cb,
      group = group,
      pattern = string.format("testpattern%d", i),
      desc = string.format("test autocmd %d", i),
      once = true,
    })
  end
end

return M
