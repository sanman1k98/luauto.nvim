describe("The `luauto.cmd` module", function()
  local auto = {
    cmd = require "luauto.cmd",
  }

  describe("has a function \"add\"", function()
    pending("which accepts a table with a certain shape", function()
    end)

    it("which can create a single autocommand given a table", function()
      local id = auto.cmd.add {
        cb = function()
          vim.notify "Hello!"
        end,
        on = "BufEnter",
      }
      assert.is_truthy(id)
      assert.is_true(type(id) == "number")
    end)
  end)

  describe("has a function \"create\"", function()
    pending("which is an alias for the \"add\" function", function()
      assert.are.equal(auto.cmd.create, auto.cmd.add)
    end)
  end)

  describe("has a function \"get\"", function()
    pending("that returns a list of autocommands matching some criteria", function()
    end)
  end)

  describe("has a function \"del\"", function()
    pending("that deletes an autocommand given its id", function()
      
    end)
  end)
end)
