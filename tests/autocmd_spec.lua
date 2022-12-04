local au = require "luauto"

local spy = require "luassert.spy"

local helpers = require "tests.helpers"
local pp = vim.pretty_print
local api = helpers.api

local ok = assert.has_no.errors
local not_ok = assert.has_errors

local truthy = assert.is_truthy
local falsy = assert.is_falsy

local eq = assert.is_equal
local same = assert.are_same



describe("a table to manage autocmds", function()
  describe("has a function", function()
    it("'clear'", function()
      assert.is_function(au.clear)
    end)

    it("'get'", function()
      assert.is_function(au.get)
    end)
  end)

  describe("has a property", function()
    it("'_ctx'", function()
      truthy(au._ctx)
    end)
  end)

  describe("can", function()
    after_each(helpers.clear_all)

    it("create them", function()
      local action = function() end

      local id = au.WinEnter(action)
      assert.number(id)

      eq(1, #api.get_autocmds({ event = "WinEnter" }))
    end)

    it("clear those matching some criteria", function()
      -- create 10 User autocmds with patterns and descriptions
      helpers.create_test_autocmds()

      assert.is_true(#api.get_autocmds({ event = "User" }) > 1)
      au.User:clear()
      eq(0, #api.get_autocmds({ event = "User" }))
    end)

    it("execute all those for a given event or events", function()
      local cb = function() end
      local s = spy.new(cb)
      au.User.testpat(cb)
      au.User:exec()
      vim.schedule_wrap(assert.spy(s).was_called)
    end)

    it("get all those matching some criteria", function()
      -- create 10 User autocmds with patterns and descriptions
      helpers.create_test_autocmds("testing")

      local User_autocmds = au:get({ event = "User" })
      eq(10, #User_autocmds)

      local also_User_autocmds = au.User:get()
      eq(10, #also_User_autocmds)

      local matches = au.User.testpattern9:get()
      eq(1, #matches)
    end)

    it("index itself by event name", function()
      local events
      ok(function()
        events = {
          au.VimEnter,
          au.User,
          au.BufLeave,
          au.InsertEnter,
        }
      end)
      eq("VimEnter", events[1]._event)
    end)

    it("index itself with a table containing multiple events", function()
      local obj
      assert.has_no.errors(function()
         obj = au[{
          "VimEnter",
          "User",
          "BufLeave",
          "InsertEnter",
        }]
      end)
      assert.table(obj._event)
      eq(4, #obj._event)
    end)
  end)
end)
