local au = require "luauto"
local api = vim.api
local print = vim.pretty_print


describe("The `luauto` module", function()
  it("returns a table that can access its submodules", function()
    assert.is_truthy(au.cmd)
    assert.is_truthy(au.group)
    assert.is_truthy(au.event)
  end)

  it("can declaratively add an autocommand to an autogroup", function()
    local test
    assert.has_no.errors(function()
      test = au.group.testing:add {
        on = "BufEnter",
        cb = function() vim.notify "Hello! Testing!" end,
        once = true,
        desc = "Created for testing",
      }
    end)
    assert.is_true(type(test) == "number")
    local cmds = api.nvim_get_autocmds {
      group = "testing",
      event = "BufEnter",
    }
    local contains_test = false
    for _, c in ipairs(cmds) do
      if c.id == test then
        print(c)
        contains_test = true
        break
      end
    end
    assert.is_true(contains_test)
  end)
end)
