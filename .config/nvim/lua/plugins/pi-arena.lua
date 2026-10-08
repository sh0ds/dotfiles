-- Pi Arena changes to LazyVim. Every file in lua/plugins/ is loaded automatically.
return {
  -- Language servers: use the ones the install guide put on your system,
  -- so versions match your compilers (HLS must match GHC from GHCup).
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = { mason = false },            -- from the clang package
        bashls = { mason = false },            -- from bash-language-server
        erlangls = { enabled = false },        -- replaced by ELP below
        elp = { mason = false },               -- binary in ~/.local/bin (guide D5)
      },
    },
  },

  -- Don't let Mason download its own HLS; haskell-tools uses GHCup's from PATH.
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = vim.tbl_filter(function(pkg)
        return pkg ~= "haskell-language-server"
      end, opts.ensure_installed or {})
    end,
  },

  -- Syntax highlighting for the rest of the stack
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "c", "asm", "bash", "awk", "sql", "lua" } },
  },
}
