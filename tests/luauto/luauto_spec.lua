local au = require "luauto"
local api = vim.api
local print = vim.pretty_print


describe("The `luauto` module", function()
  it("has the following fields", function()
    assert.is_truthy(au.cmd)
    assert.is_truthy(au.group)
    assert.is_truthy(au.event)
  end)

  it("can declaratively add an autocommand to an autogroup", function()
    local test
    assert.has_no.errors(function()
      au.group.testing:clear()      -- will create augroup if it doesn't exist
      test = au.group.testing:cmd("BufEnter", {
        callback = function() vim.notify "Hello! Testing!" end,
        once = true,
        desc = "Created for testing",
      })
    end)
    assert.is_true(type(test) == "number")
    local cmds = api.nvim_get_autocmds {
      group = "testing",
      event = "BufEnter",
    }
    local contains_test = false
    for _, c in ipairs(cmds) do
      if c.id == test then
        contains_test = true
        break
      end
    end
    assert.is_true(contains_test)
  end)

  describe("has a field `cmd`", function()
    local auto = require "luauto"

    pending("is a table which has has wrappers for some API functions", function()
    end)

    pending("which can be called like `vim.api.nvim_create_autocmd()`", function()
      local id = auto.cmd("BufEnter",{
        command = 'echo "Hello! Testing!"',
      })
      assert.is_true(type(id) == "number")
    end)

    pending("which can be called with a Vim command as the second arg to create an autocmd", function()
      local id = auto.cmd("BufEnter", 'echo "Hello! Testing!"')
      assert.is_true(type(id) == "number")
    end)
  end)

  describe("has a function `cb`", function()
    local auto = require "luauto"

    pending("to create an autocmd with by specifying a callback func as second arg", function()
      local id = auto.cb("VimEnter", function() vim.cmd.echo "Hello! Testing!" end)
      assert.is_true(type(id) == "number")
    end)

    pending("which parallels the calling `cmd` as a function", function()
      local id1 = auto.cmd("VimEnter", 'echo "Hello! Testing!"', {
        desc = "created for testing",
        once = true,
      })

      local id2 = auto.cb("VimEnter", function() vim.cmd.echo "Hello! Testing!" end, {
        desc = "also created for testing",
        once = true,
      })

      assert.is_true(type(id2) == "number")
      assert.is_true(type(id1) == "number")
    end)
  end)

  describe("has a field `group`", function()
  end)

  describe("has a field `event`", function()
  end)

  describe("has a field `user`", function()
  end)
end)
