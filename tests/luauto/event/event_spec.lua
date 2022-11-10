local spy = require "luassert.spy"
local mock = require "luassert.mock"
local match = require "luassert.match"

local print = vim.pretty_print


describe("The `luauto.event` module", function()
  local auto = {
    event = require "luauto.event",
  }

  it("can be indexed by event names", function()
    assert.has_no.errors(function()
      local value = auto.event.BufEnter
    end)
    assert.has_no.errors(function()
      local value = auto.event.bufenter
    end)
    assert.has_no.errors(function()
      local value = auto.event["BufEnter"]
    end)
    assert.has_no.errors(function()
      local value = auto.event["bufenter"]
    end)
  end)

  describe("when indexed, returns a table", function()
    it("with a field `_event` containing the key used to retrieve it", function()
      local key = "BufEnter"
      local tbl = auto.event[key]
      assert.is_true(type(tbl) == "table")
      assert.is_truthy(tbl._event)
      assert.is_equal(tbl._event, key)
    end)

    it("which can also be indexed", function()
      local tbl
      assert.has_no.errors(function()
        tbl = auto.event.user.custom_event
      end)
      assert.is_true(type(tbl) == "table")
    end)
  end)


  describe("can be indexed like a 2D array", function()
    it("with first and second keys being an event and pattern respectively", function()
      assert.has_no.errors(function()
        local value = auto.event.User.custom_event
      end)
      assert.has_no.errors(function()
        local value = auto.event["User"]["custom_event"]
      end)
    end)

    describe("and returns a table", function()
      it("with fields `_event` and `_pattern` containing the keys used to index it", function()
        local key1, key2 = "User", "custom_event"
        local tbl = auto.event[key1][key2]
        assert.is_equal(key1, tbl._event)
        assert.is_equal(key2, tbl._pattern)
      end)

      describe("which can be used to", function()
        local api = mock(vim.api)

        after_each(function()
          mock.clear(api)
        end)

        it("execute autocommands matching event", function()
          assert.has_no.errors(function()
            auto.event.user:exec()
          end)
          assert.spy(api.nvim_exec_autocmds).was_called()
          assert.spy(api.nvim_exec_autocmds).was_called_with("user", match.is_same {})
        end)

        it("execute autocommands matching event and pattern", function()
          assert.has_no.errors(function()
            auto.event.user.testing:exec()
          end)
          assert.spy(api.nvim_exec_autocmds).was_called_with("user", match.is_same { pattern = "testing" })
        end)

        it("get autocommands", function()
          local user_events
          assert.has_no.errors(function()
            user_events = auto.event.user:get()
          end)
          assert.spy(api.nvim_get_autocmds).was_called_with(match.is_same { event = "user" })
        end)

        pending("clear autocommands", function()
        end)

        pending("assign to a variable and execute autocommands", function()
        end)
      end)
    end)
  end)
end)
