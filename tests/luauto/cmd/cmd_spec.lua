describe("The `luauto.cmd` module", function()
  local auto = {
    cmd = require "luauto.cmd",
  }

  describe("has a function \"add\"", function()
    pending("which accepts a table with a certain shape", function()
    end)

    pending("which can create a single autocommand given a table", function()
      auto.cmd.add {
        cb = function()
          vim.notify "Hello!"
        end,
        on = "BufEnter",
      }
    end)

    pending("which can create multiple autocommands given a list of tables", function()
    end)
  end)

  describe("has a function \"create\"", function()
    pending("which is an alias for the \"add\" function", function()
    end)
  end)

  describe("has a function \"get\"", function()
  end)

  describe("has a function \"del\"", function()
  end)
end)
