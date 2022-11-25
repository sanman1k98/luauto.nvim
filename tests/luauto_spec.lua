local luauto = require "luauto"
local autocmd, augroup = luauto.cmd, luauto.group

local truthy = assert.is_truthy
local falsy = assert.is_falsy
local ok = assert.has_no.errors
local not_ok = assert.has_errors
local same = assert.are_same              -- deep comparison
local eq = assert.is_equal                -- compare by value or by reference

local api = vim.api
local pp = vim.pretty_print



describe("has a submodule", function()
  it("'cmd'", function()
    truthy(luauto.cmd)
  end)

  it("'group'", function()
    truthy(luauto.group)
  end)

  pending("'user'", function()
    truthy(luauto.user)
  end)
end)



describe("example snippet:", function()
  it("highlight on yank", function()
    autocmd.TextYankPost(function()
      vim.highlight.on_yank {
        timeout = 200,
        on_macro = true
      }
    end, { desc = "hl on yank example" })
    -- end snippet

    local cmds, found = autocmd.TextYankPost:get(), false
    for _, c in ipairs(cmds) do
      if c.desc == "hl on yank example" then
        found = true
        break
      end
    end
    assert.is_true(found)
  end)

  it("toggle `cursorline` when entering and leaving windows", function()
    -- "~/.config/nvim/init.lua" or somewhere like that
    local set_cul = function(val)
      local cb = function() vim.opt.cul = val end
      return cb
    end

    augroup.cursorline(function(au)
      au:clear()                        -- clears the current augroup "cursorline"
      au.WinEnter(set_cul(true))
      au.WinLeave(set_cul(false))
    end)
    -- end snippet

    local cmds = augroup.cursorline:get()
    assert.is_true(#cmds == 2)
  end)
end)



describe("a table to manage autocmds", function()
  describe("has", function()
    it("a method 'del'", function()
      truthy(autocmd.del)
    end)

    it("a method 'get'", function()
      truthy(autocmd.get)
    end)

    it("a method 'exec'", function()
      truthy(autocmd.exec)
    end)

    it("a method 'clear'", function()
      truthy(autocmd.clear)
    end)
  end)

  describe("can", function()
    pending("delete one given an id", function()
      local cb = function() vim.notify "Welcome" end
      local id = api.nvim_create_autocmd("VimEnter", {
        callback = cb, 
      })
      truthy(id)
      ok(function()
        autocmd:del(id)
      end)
      local cmds, found = api.nvim_get_autocmds { event = "VimEnter" }, false
      for _, c in ipairs(cmds) do
        if c.id == id then
          found = true
          break
        end
      end
      assert.is_false(found)
    end)

    pending("clear those matching given some criteria", function()
    end)

    pending("execute those matching given some criteria for event(s)", function()
    end)

    pending("get a list of those that match given some criteria", function()
    end)
  end)

  pending("is callable and can create them", function()
    local id
    ok(function()
      id = autocmd("ColorScheme", function()
        vim.notify "Nice rice!"
      end, { desc = "created with luauto", })
    end)
    local cmds, found = api.nvim_get_autocmds { event = "ColorScheme" }, false
    for _, c in ipairs(cmds) do
      if c.id == id then
        found = true
        break
      end
    end
    assert.is_true(found)
  end)
end)


describe("create autocmds", function()
  pending("and return their id", function()
    local id
    local cb = function() return true end
    ok(function() id = autocmd("User", cb) end)
    truthy(id)
  end)

  describe("given args `event` and `action`", function()
    pending("which can be a Lua callback function", function()
      local id
      ok(function()
        id = autocmd("CmdwinEnter", function()
          vim.notify "No one has ever exited this mode, please place your computer in the nearest bathtub"
        end, { once = true })
      end)
      truthy(id)
    end)

    pending("which can be a Vim command string prefixed with `:`", function()
      local id
      ok(function()
        id = autocmd("QuitPre", ":write", { 
          desc = "save before quiting",
          once = true
        })
      end)
      truthy(id)
    end)
  end)
end)


describe("a table indexable by event names", function()
  pending("returns a 'proxy object' for the event", function()
    local e = autocmd.VimEnter
    truthy(e)
    assert.is_true(type(e) == "table")
  end)

  pending("has case-insensitive keys", function()
    local tbl = autocmd.BufEnter
    local also_tbl = autocmd.bufenter
    eq(tbl, also_tbl)
  end)
end)


describe("an event proxy", function()
  local event = autocmd.TextYankPost

  describe("has", function()
    pending("a method `get`", function()
      local get = event.get
      assert.is_true(type(get) == "function")
    end)

    pending("a method `clear`", function()
      local clear = event.clear
      assert.is_true(type(clear) == "function")
    end)

    pending("a method `info`", function()
      local info = event.info
      assert.is_true(type(info) == "function")
    end)

    pending("a method `exec`", function()
      local exec = event.exec
      assert.is_true(type(exec) == "function")
    end)

    pending("a field `ignore` with a boolean value", function()
      assert.is_true(type(event.ignore) == "boolean")
    end)
  end)

  describe("can", function()
    pending("return some info in a table", function()
      local info = event.info
      assert.is_true(type(info) == "table")
      truthy(info.event)
      assert.is_true(type(info.event) == "string")
    end)

    pending("clear autocmds for the event", function()
    end)

    pending("get autocmds for the event", function()
    end)

    pending("execute autocmds for the event", function()
    end)

    pending("be used to check if the event is listed in the `eventignore` option", function()
    end)

    pending("set the event to be ignored", function()
    end)
  end)
end)


describe("a table indexable by autogroup names", function()
  pending("returns a 'proxy object' for the autogroup", function()
  end)

  pending("is case-sensitive", function()
  end)
end)


describe("an autogroup proxy", function()
  describe("has", function()
    pending("a method `define`", function()
    end)

    pending("a method `create`", function()
    end)

    pending("a method `get`", function()
    end)

    pending("a method `clear`", function()
    end)

    pending("a method `info`", function()
    end)

    pending("a method `del`", function()
    end)

    pending("a field `id` with an integer value", function()
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


describe("an autogroup spec function", function()
  pending("creates autocmds in an autogroup", function()
  end)

  describe("takes one argument", function()
    describe("which is a table", function()
      pending("that has a method to clear the autogroup", function()
      end)

      pending("that returns functions when indexed with event names", function()
      end)
    end)

    pending("which it uses to create the autocmds", function()
    end)
  end)

  describe("is used as an argument to an autogroup proxy's methods", function()
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
