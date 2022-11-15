local spy = require "luassert.spy"
local stub = require "luassert.stub"
local mock = require "luassert.mock"
local match = require "luassert.match"

local print = vim.pretty_print


describe("The `luauto.event` module", function()
  local au = {
    event = require "luauto.event",
  }

  it("can be indexed by event names", function()
    assert.has_no.errors(function()
      local value = au.event.BufEnter
    end)
    assert.has_no.errors(function()
      local value = au.event.bufenter
    end)
    assert.has_no.errors(function()
      local value = au.event["BufEnter"]
    end)
    assert.has_no.errors(function()
      local value = au.event["bufenter"]
    end)
  end)

  describe("when indexed, returns a table", function()
    it("that has a metatable", function()
      local event = au.event.User
      local mt = getmetatable(event)
      assert.is_truthy(mt)
      assert.is_true(type(mt) == "table")
    end)

    describe("which can", function()
      it("add autocmds on event", function()
        local id
        assert.has_no.errors(function()
          id = au.event.VimEnter:add {
            callback = function() vim.notify "Welcome! Testing!" end,
            desc = "an autocmd created for testing purposes",
            once = true,
          }
        end)
        assert.is_truthy(id)
      end)

      it("get autocmds matching the event", function()
        local cmds = au.event.VimEnter.cmds
        assert.is_true(#cmds > 0)
      end)

      it("execute autocommands on event", function()
        stub(vim, "notify")
        au.event.VimEnter:exec()
        assert.stub(vim.notify).was_called()
        vim.notify:revert()
      end)

      it("clear autocmds on event", function()
        local fn = function() return "something" end
        local id = vim.api.nvim_create_autocmd("VimEnter", {
          callback = fn,
        })
        assert.is_true(#vim.api.nvim_get_autocmds { event = "VimEnter" } > 0)
        au.event.VimEnter:clear()
        assert.is_true(#vim.api.nvim_get_autocmds { event = "VimEnter" } == 0)
      end)

      pending("set the option to ignore events", function()
        au.event.VimEnter.ignore = true
      end)
    end)
  end)
end)
