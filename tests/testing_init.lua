-- manually add to runtimepath
vim.opt.runtimepath:append(".")
vim.cmd.packadd "plenary.nvim"


-- the `vim.cmd.runtime` call searches the runtimepath for a "plenary.vim"
-- plugin script and sources the first one that is found; creates the following
-- user commands:
--
--    - "PlenaryBustedFile"
--    - "PlenaryBustedDirectory"
--
vim.cmd.runtime "plugin/plenary.vim"
