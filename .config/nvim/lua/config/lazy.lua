-- Bootstrap lazy.nvim (plugin manager), then load LazyVim and its language extras.
-- Based on github.com/LazyVim/starter.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins", opts = { colorscheme = "amethyst" } },

    -- One extra per language in the plan (browse more with :LazyExtras)
    { import = "lazyvim.plugins.extras.lang.clangd" },   -- C: pistat, 3sgc
    { import = "lazyvim.plugins.extras.lang.haskell" },  -- md, logstat
    { import = "lazyvim.plugins.extras.lang.erlang" },   -- live
    { import = "lazyvim.plugins.extras.lang.sql" },      -- visits, search
    { import = "lazyvim.plugins.extras.lang.json" },     -- pistats.json, API replies
    { import = "lazyvim.plugins.extras.lang.markdown" }, -- posts, LOG.md

    -- Your own changes
    { import = "plugins" },
  },
  defaults = { lazy = false, version = false },
  install = { colorscheme = { "amethyst", "habamax" } },
  checker = { enabled = true, notify = false },
  performance = {
    rtp = {
      disabled_plugins = { "gzip", "tarPlugin", "tohtml", "zipPlugin" },
    },
  },
})
