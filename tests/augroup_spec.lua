local au = require "luauto"
local autocmd, augroup = au.cmd, au.group

local helpers = require "tests.helpers"
local api = helpers.api
local pp = vim.pretty_print

local truthy = assert.is_truthy
local falsy = assert.is_falsy

local ok = assert.has_no.errors
local not_ok = assert.has_errors

local same = assert.are_same              -- deep comparison
local eq = assert.is_equal                -- compare by value or by reference



describe("a table to manage an augroup", function()
  local testgroup = augroup.testgroup

  describe("has a method", function()
    it("'create'", function()
      truthy(testgroup.create)
      assert.is_function(testgroup.create)
    end)

    it("'clear'", function()
      truthy(testgroup.clear)
      assert.is_function(testgroup.clear)
    end)

    it("'exists'", function()
      truthy(testgroup.exists)
      assert.is_function(testgroup.exists)
    end)

    it("'get'", function()
      truthy(testgroup.get)
      assert.is_function(testgroup.get)
    end)

    it("'del'", function()
      truthy(testgroup.del)
      assert.is_function(testgroup.del)
    end)
  end)

  describe("has a property", function()
    it("'_au'", function()
      truthy(testgroup._au)
      assert.table(testgroup._au)
    end)

    it("'_ctx'", function()
      truthy(testgroup._ctx)
      assert.table(testgroup._ctx)
    end)
  end)

  describe("can", function()
    before_each(function()
      -- create 10 User autocmds in the group "testgroup"
      helpers.create_test_autocmds "testgroup"
    end)

    after_each(function()
      -- clear all autocmds in group "testgroup" and in the default group
      helpers.clear_all "testgroup"
    end)

    it("check if it exists", function()
      assert.is_true(testgroup:exists())
      api.del_augroup_by_name "testgroup"
      assert.is_false(testgroup:exists())
    end)

    it("create it", function()
      api.del_augroup_by_name("testgroup")

      not_ok(function()
        api.get_autocmds({ group = "testgroup" })
      end)

      testgroup:create()

      same({}, api.get_autocmds({ group = "testgroup" }))
    end)

    it("clear its autocmds", function()
      eq(10, #api.get_autocmds({ group = "testgroup" }))
      testgroup:clear()
      eq(0, #api.get_autocmds({ group = "testgroup" }))
    end)

    it("get its autocmds", function()
      eq(10, #testgroup:get())
    end)

    it("define its autocmds", function()
      api.del_augroup_by_name "testgroup"

      -- calling the group will create it before running the given spec
      augroup.testgroup(function(au)
        au.WinEnter(function() end)
        au.WinLeave(function() end)
        au.BufEnter(function() end)
      end)

      eq(3, #au.group.testgroup:get())
    end)

    it("delete it", function()
      augroup.testgroup:del()
      not_ok(function()
        api.get_autocmds({ group = "testgroup" })
      end)
    end)
  end)

  describe("has an object to manage its autocmds", function()
    it("which has the same '_ctx' table", function()
      local aug_obj = augroup.testgroup
      local au_obj = aug_obj._au

      same(aug_obj._ctx, au_obj._ctx)
      eq(aug_obj._ctx, au_obj._ctx)
    end)

    it("which is the same one used when defining the augroup's autocmds", function()
      local aug = augroup.testgroup
      local au_obj = aug._au

      aug(function(au)
        eq(au, au_obj)
      end)
    end)
  end)
end)
