local helpers = require "tests.helpers"

local api = helpers.api
local ok = helpers.ok
local not_ok = helpers.not_ok
local truthy = helpers.truthy
local falsy = helpers.falsy
local eq = helpers.eq
local same = helpers.same



describe("a table to manage an augroup", function()
  describe("has a method", function()
    pending("'create'", function()
    end)

    pending("'clear'", function()
    end)

    pending("'get'", function()
    end)

    pending("'del'", function()
    end)

    pending("'exec'", function()
    end)

    pending("'define'", function()
    end)

    pending("''", function()
    end)
  end)

  describe("has a read-only property", function()
    pending("'id'", function()
    end)

    pending("'name'", function()
    end)

    pending("'scope'", function()
    end)

    pending("'autocmd'", function()
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
