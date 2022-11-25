local augroup = require("luauto").group

local helpers = require "tests.helpers"
local api = helpers.api

local truthy = assert.is_truthy
local falsy = assert.is_falsy
local ok = assert.has_no.errors
local not_ok = assert.has_errors
local same = assert.are_same              -- deep comparison
local eq = assert.is_equal                -- compare by value or by reference
local pp = vim.pretty_print



describe("a table to manage an augroup", function()

  local testgroup = augroup.testgroup

  describe("has a method", function()
    pending("'create'", function()
      truthy(testgroup.create)
      assert.is_function(testgroup.create)
    end)

    pending("'clear'", function()
      truthy(testgroup.clear)
      assert.is_function(testgroup.clear)
    end)

    pending("'get'", function()
      truthy(testgroup.get)
      assert.is_function(testgroup.get)
    end)

    pending("'del'", function()
      truthy(testgroup.del)
      assert.is_function(testgroup.del)
    end)

    pending("'exec'", function()
      truthy(testgroup.exec)
      assert.is_function(testgroup.exec)
    end)

    pending("'define'", function()
      truthy(testgroup.define)
      assert.is_function(testgroup.define)
    end)
  end)

  describe("has a read-only property", function()
    pending("'id'", function()
      truthy(testgroup.id)
      assert.number(testgroup.id)
      not_ok(function()
        testgroup.id = 0
      end)
    end)

    pending("'name'", function()
      truthy(testgroup.name)
      assert.string(testgroup.name)
      not_ok(function()
        testgroup.name = "testgroup2"
      end)
    end)

    pending("'scope'", function()
      truthy(testgroup.scope)
      assert.table(testgroup.scope)
      not_ok(function()
        testgroup.scope = {}
      end)
    end)

    pending("'autocmd'", function()
      truthy(testgroup.autocmd)
      assert.table(testgroup.autocmd)
      not_ok(function()
        testgroup.autocmd = {}
      end)
    end)
  end)

  describe("can", function()
    pending("create it", function()
    end)

    pending("clear its autocmds", function()
    end)

    pending("get its autocmds", function()
    end)

    pending("define its autocmds", function()
    end)

    pending("delete it", function()
    end)
  end)

  describe("has a table to manage its autocmds", function()
    pending("which has the same scope", function()
    end)

    pending("which is the same one used when defining the augroup's autocmds", function()
    end)
  end)
end)
