# `luauto.nvim`

A Lua module to manage autocommands and groups!

## Installing

```lua
-- using packer

use {
	"sanman1k98/luauto.nvim"
}
```

## Usage

### Examples

```lua
local au = require "luauto"

-- clearing all autocmds in the default group
au:clear()

-- getting all autocmds in the default group
au:get()

-- creating an autocmd for an event
au.TextYankPost(function()
	vim.on_yank { timeout = 200 }
end)

-- getting autocmds for an event
local cmds = au:get({ event = "TextYankPost" })
local also_cmds = au.TextYankPost:get()
assert(#cmds == #also_cmds, "function calls are equivalent")

-- clearing autocmds for an event
au:clear({ event = "TextYankPost" })
au.TextYankPost:clear() -- equivalent to above

-- executing a User event
au.User:exec({ pattern = "SomePluginEvent" })
au.User.SomePluginEvent:exec() -- equivalent to above

-- creating an autocmd for an event and pattern
local pattern = vim.fn.expand("$MYVIMRC")
au.BufWritePost[pattern] ":source <afile> | PackerCompile"

-- creating multiple autocmds in a new group
local set_cul = function(val)
	return (function() vim.opt.cul = val end)
end

au.group.cursorline(function(au)
	au:clear()                      -- clears the group
	au.WinEnter(set_cul(true))      -- 
	au.WinLeave(set_cul(false))
end)

-- getting the autocmds in a group
local group_cmds = au.group.cursorline:get()
assert(#group_cmds == 2)

-- getting the id of a group
local id = au.group.cursorline.id
local also_id = au.group.cursorline:create()
assert(id == also_id)



```

The luauto module is an object which

### The `Autocmd` object

An `Autocmd` object is used to create, get, execute, and clear autocommands. The `luauto` module itself is an instance of this object, and has the following properties:
- indexable by event name and returns `Event` objects
- has a method `Autocmd:get()`
- has a method `Autocmd:clear()`
- has a field "buf" which can be indexed with buffer numbers

`Autocmd:get()` and `Autocmd:clear()` accepts the same arguments as the API functions `nvim_get_autocmds()` and `nvim_clear_autocmds()` respectively.

For creating and executing autocommands, we index the object using event names as keys.

```lua
-- using string-notation
‌Autocmd["VimEnter"]

-- using dot-notation
Autocmd.VimEnter
```

Since Lua allows any type of value to be used as a key, we can pass in an array of keys.

```lua
Autocmd[{ "VimEnter", "VimLeave" }]

```