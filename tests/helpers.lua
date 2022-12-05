local M = {}



M.api = setmetatable({}, {
  __index = function(_, k)
    return vim.api["nvim_" .. k]
  end,
})

function M.clear_all(group)
  if group then
    M.api.create_augroup(group, { clear = true })
  end
  M.api.clear_autocmds({ group = nil })
end

function M.get_test_autocmds(group)
  return M.api.get_autocmds { event = "User", group = group }
end

function M.create_test_autocmds(group)
  if group then
    M.api.create_augroup(group, {})
  end
  local cb = function() end
  for i = 1, 10 do
    M.api.create_autocmd("User", {
      callback = cb,
      group = group,
      pattern = string.format("testpattern%d", i),
      desc = string.format("test autocmd %d", i),
      once = true,
    })
  end
end

return M
