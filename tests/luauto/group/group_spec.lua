local auto = {
  group = require "luauto.group"
}
local print = vim.pretty_print

describe("The `luauto.group` module", function()
  local auto = {
    group = require "luauto.group",
  }

  it("has a metatable with an `__index` field", function()
    local mt = getmetatable(auto.group)
    assert.is_truthy(mt)
    assert.is_truthy(mt.__index)
  end)


  describe("when indexed by a group name returns a table", function()
    it("containing `id` and `name` fields", function()
      local group_table = auto.group.user_group
      assert.is_truthy(group_table)
      assert.is_truthy(group_table.id)
      assert.is_truthy(group_table.name)
    end)

    it("with a metavalue `__index`", function()
      local mt = getmetatable(auto.group.user_group)
      assert.is_truthy(mt)
      assert.is_truthy(mt.__index)
      assert.is_true(type(mt.__index) == "table")
    end)

    describe("which can be used to", function()
      it("add an autocommand to a group", function()
        local autocmd_id = auto.group.testing:add {
          cb = function() vim.notify "Testing!" end,
          on = "BufEnter",
        }
        assert.is_truthy(autocmd_id)
        assert.is_true(type(autocmd_id) == "number")
      end)

      pending("add multiple autocommands to a group", function()
      end)

      it("get a list of autcommands in a group", function()
        local cmds = auto.group.testing:cmds()
        assert.is_true(#cmds > 0)
      end)

      it("clear a group", function()
        assert.is_true(#auto.group.testing:cmds() > 0)
        auto.group.testing:clear()
        assert.is_equal(#auto.group.testing:cmds(), 0)
      end)

      it("delete a group", function()
        local old_id = auto.group.testing.id
        auto.group.testing:del()
        local new_id = auto.group.testing.id
        assert.is_not.equal(old_id, new_id)
      end)

      it("get the group's id", function()
        local group_id = auto.group.testing.id
        local also_group_id = vim.api.nvim_create_augroup("testing", { clear = false })
        assert.are_equal(group_id, also_group_id)
      end)

      it("assign to a local variable and add autocommands", function()
        local fn = function() vim.notify "Testing!" end
        local aug = auto.group.testing
        aug:add {
          on = "BufEnter",
          cb = fn,
          desc = "testing groups one",
        }
        aug:add {
          on = "BufEnter",
          cb = fn,
          desc = "testing groups two",
        }
        aug:add {
          on = "BufEnter",
          cb = fn,
          desc = "testing groups three",
        }
        assert.is_true(#aug:cmds() >= 3)
        assert.is_true(#auto.group.testing:cmds() >= 3)
      end)
    end)
  end)
end)
