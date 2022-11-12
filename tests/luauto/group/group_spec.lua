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

      pending("get a list of autcommands in a group", function()
      end)

      pending("delete a group", function()
      end)

      pending("clear a group", function()
      end)

      it("get the group's id", function()
        local group_id = auto.group.testing.id
        local also_group_id = vim.api.nvim_create_augroup("testing", { clear = false })
        assert.are_equal(group_id, also_group_id)
      end)
    end)
  end)
end)
