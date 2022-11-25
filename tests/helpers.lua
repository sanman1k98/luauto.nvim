local M = {}



M.api = setmetatable({}, {
  __index = function(_, k)
    return vim.api["nvim_" .. k]
  end,
})

function M.clear(group)
  api.clear_autocmds { group = group }
end

M.truthy = assert.truthy
M.falsy = assert.falsy
M.ok = assert.has_no.errors
M.not_ok = assert.has.errors
M.same = assert.same
M.eq = assert.equal



return M
