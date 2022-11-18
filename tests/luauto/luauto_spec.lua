local luauto = require "luauto"

local truthy = assert.is_truthy
local falsy = assert.is_falsy
local works = assert.has_no.errors
local stops_working = assert.has_errors
local same = assert.are_same              -- deep comparison
local eq = assert.is_equal                -- compare by value or by reference

local api = vim.api
local pp = vim.pretty_print



describe("has submodules", function()
  it("`cmd`", function()
    truthy(luauto.cmd)
  end)

  it("`group`", function()
    truthy(luauto.group)
  end)

  pending("`user`", function()
    truthy(luauto.user)
  end)
end)



local autocmd, augroup = luauto.cmd, luauto.group

describe("a table to manage autocmds", function()
  describe("has a field", function()
    pending('\"del\"', function()
    end)

    pending('\"get\"', function()
    end)

    pending('\"exec\"', function()
    end)

    pending('\"clear\"', function()
    end)
  end)

  describe("can", function()
    pending("delete by id", function()
    end)

    pending("clear those matching given some criteria", function()
    end)

    pending("execute those matching given some criteria for event(s)", function()
    end)

    pending("get a list of those that match given some criteria", function()
    end)
  end)

  pending("is callable and can create them", function()
  end)
end)


describe("create autocmds", function()
  describe("given args `event` and `action`", function()
    pending("which can be a callback as a Lua function", function()
    end)

    pending("which can be a Vim command as a string prefixed with \":\"", function()
    end)
  end)

  pending("and return their id", function()
  end)
end)


describe("a table indexable by event names", function()
  pending("returns a table that representing that event", function()
  end)

  pending("is case-insensitive", function()
  end)
end)


describe("a table representing an event", function()
  describe("has a field", function()
    pending("`get`", function()
    end)

    pending("`clear`", function()
    end)

    pending("`info`", function()
    end)

    pending("`exec`", function()
    end)

    pending("`ignore`", function()
    end)
  end)

  describe("can", function()
    pending("clear autocmds for the event", function()
    end)

    pending("get autocmds for the event", function()
    end)

    pending("execute autocmds for the event", function()
    end)

    pending("see if the event is ignored by checking the `eventignore` option", function()
    end)

    pending("set the event to be ignored", function()
    end)
  end)
end)


describe("a table indexable by autogroup names", function()
  pending("returns a table that representing that autogroup", function()
  end)

  pending("is case-sensitive", function()
  end)
end)


describe("a table representing an autogroup", function()
  describe("has a field", function()
    pending("`define`", function()
    end)

    pending("`create`", function()
    end)

    pending("`get`", function()
    end)

    pending("`clear`", function()
    end)

    pending("`info`", function()
    end)

    pending("`del`", function()
    end)

    pending("`id`", function()
    end)
  end)

  describe("can", function()
    pending("delete the autogroup", function()
    end)

    pending("clear the autogroup", function()
    end)

    pending("create it if it doesn't exist", function()
    end)

    pending("get its id", function()
    end)
  end)
end)


describe("define autogroups", function()
  pending("given a variable number of lists of arguments for creating autocmds", function()
  end)

  pending("given a spec function that creates autocmds", function()
  end)

  pending("returns the ids of the created autocmds", function()
  end)
end)


describe("an autogroup's spec function", function()
  describe("uses one table parameter", function()
    pending("indexable by event names and returns functions", function()
    end)

    pending("to create autocmds in the body of the function", function()
    end)
  end)

  describe("is used as an argument to a function that defines autogroups", function()
    pending("which provides the value for ", function()
    end)
  end)
end)


describe("an autogroup's \"events\" table", function()
  pending("is private to the table representing the autogroup", function()
  end)

  pending("is indexable by event names", function()
  end)

  pending("returns functions that create an autocmd for the specified event and autogroup", function()
  end)

  pending("is used as the arg when calling an autogroup spec func", function()
  end)
end)


describe("create and add autocmds to an existing autogroup", function()
  pending("the same way you defined it", function()
  end)

  pending("using another spec function", function()
  end)
end)
