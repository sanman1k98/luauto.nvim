# `luauto.nvim`

A Lua module to manage autocommands and groups!

## Installing

```lua
-- using lazy.nvim
{
  "sanman1k98/luauto.nvim"
  config = true,
}
```

## Usage

### Examples

```lua
-- clearing all autocmds in the default group
vim.autocmd:clear()

-- getting all autocmds in the default group
vim.autocmd:get()

-- creating an autocmd for an event
vim.autocmd.TextYankPost(function()
  vim.highlight.on_yank { timeout = 200 }
end)

-- getting autocmds for an event
local cmds = vim.autocmd:get({ event = "TextYankPost" })
local also_cmds = vim.autocmd.TextYankPost:get()
assert(#cmds == #also_cmds, "function calls are equivalent")

-- clearing autocmds for an event
vim.autocmd:clear({ event = "TextYankPost" })
vim.autocmd.TextYankPost:clear() -- equivalent to above

-- executing a User event
vim.autocmd.User:exec({ pattern = "SomePluginEvent" })
vim.autocmd.User.SomePluginEvent:exec() -- equivalent to above

-- creating an autocmd for an event and pattern
vim.autocmd.User.LazyUpdate(function() vim.notify("Plugin updates available!") end)

-- creating multiple autocmds in a new group
local set_cul = function(val)
  return (function() vim.opt.cul = val end)
end

vim.augroup.cursorline(function(au)
  au:clear()                      -- clears the group
  au.WinEnter(set_cul(true))
  au.WinLeave(set_cul(false))
end)

-- getting the autocmds in a group
local group_cmds = vim.augroup.cursorline:get()
assert(#group_cmds == 2)

local groupid = vim.augroup.cursorline:create()
local also_group_cmds = vim.autocmd:get({ group = groupid })
```

### The `Autocmd` object

An `Autocmd` object is used to create, get, execute, and clear autocommands. It has the following properties:
- indexable by event name and returns `Event` objects
- has a method `Autocmd:get()`
- has a method `Autocmd:clear()`
- has a field "buf" which can be indexed with buffer numbers

`Autocmd:get()` and `Autocmd:clear()` accepts the same arguments as the API functions `nvim_get_autocmds()` and `nvim_clear_autocmds()` respectively.

For creating and executing autocommands, we index the object using event names as keys.

```lua
-- using string-notation
Autocmd["VimEnter"]

-- using dot-notation
Autocmd.VimEnter
```

Since Lua allows any type of value to be used as a key, we can pass in an array of keys.

```lua
Autocmd[{ "VimEnter", "VimLeave" }]
```
