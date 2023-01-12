local luauto = require "luauto"
local autocmd, augroup = luauto.cmd, luauto.group

local helpers = require "tests.helpers"
local pp = vim.pretty_print

local truthy = assert.is_truthy
local falsy = assert.is_falsy

local ok = assert.has_no.errors
local not_ok = assert.has_errors

local same = assert.are_same              -- deep comparison
local eq = assert.is_equal                -- compare by value or by reference




describe("has a field", function()
  it("'group'", function()
    truthy(luauto.group)
    assert.table(luauto.group)
  end)

  it("'cmd'", function()
    truthy(luauto.cmd)
    assert.table(luauto.cmd)
  end)

  it("'setup'", function()
    truthy(luauto.setup)
    assert.is_function(luauto.setup)
  end)
end)



describe("example usage:", function()
  it("highlight on yank", function()
    -- begin snippet
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
    -- begin snippet
    local set_cul = function(val)
      local cb = function() vim.opt.cul = val end
      return cb
    end

    augroup.cursorline(function(au)
      au:clear()                    -- calls 'nvim_clear_autocmds({ group = "cursorline" })
      au.WinEnter(set_cul(true))
      au.WinLeave(set_cul(false))
    end)
    -- end snippet

    local cmds = augroup.cursorline:get()
    eq(#cmds, 2)
  end)

  it("source and recompile packer when you save your 'init.lua'", function()
    -- adapted from 'nvim-lua/kickstart.nvim'
    augroup.Packer(function(au)
      au:clear()
      local pattern = vim.fn.expand("$MYVIMRC")
      au.BufWritePost[pattern](":source <afile> | PackerCompile")
    end)
    -- end snippet

    local cmds = augroup.Packer:get()
    eq(1, #cmds)
    truthy(cmds[1].command)
  end)

  it("check whether to reload the file", function()
    autocmd[{ "FocusGained", "TermClose", "TermLeave" }](":checktime", {
      desc = "check whether to reload the file",
    })

    local cmds = autocmd.FocusGained:get()
    eq(1, #cmds)
    eq("checktime", cmds[1].command)
    eq("check whether to reload the file", cmds[1].desc)
  end)
end)
