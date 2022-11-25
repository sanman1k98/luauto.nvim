
local helpers = require "tests.helpers"

local api = helpers.api
local ok = helpers.ok
local not_ok = helpers.not_ok
local truthy = helpers.truthy
local falsy = helpers.falsy
local eq = helpers.eq
local same = helpers.same


describe("a table representing an event", function()
  describe("has a method", function()
    pending("'clear'", function()
    end)

    pending("'get'", function()
    end)

    pending("'exec'", function()
    end)
  end)

  describe("has a read-only attribute", function()
    pending("'scope'", function()
    end)

    pending("'name'", function()
    end)
  end)

  describe("can", function()
    pending("create an autocmd", function()
    end)
    
    pending("clear its autocmds", function()
    end)
    
    pending("execute all autocmds registered to it", function()
    end)
    
    pending("get all autocmds registered to it", function()
    end)
  end)

  describe("cannot", function()
    pending("manage autocmds outside its scope", function()
    end)
  end)
end)
