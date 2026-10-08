-- ~/.config/nvim/init.lua  (Neovim 0.12, no plugins)
-- Language servers for the four languages that have one in the plan.
-- Everything here is built in, so there is nothing to update or break.

vim.g.mapleader = " "

local o = vim.opt
o.number = true
o.relativenumber = true
o.signcolumn = "yes"
o.cursorline = true
o.scrolloff = 8
o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.smartindent = true
o.ignorecase = true
o.smartcase = true
o.undofile = true
o.splitright = true
o.splitbelow = true
o.termguicolors = true
o.clipboard = "unnamedplus"       -- uses wl-copy / wl-paste
o.completeopt = { "menuone", "noselect", "popup" }
o.list = true
o.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Haskell and Erlang code is conventionally indented by 2 or 4; C by 4. Asm uses tabs.
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "haskell", "cabal" },
    callback = function() vim.opt_local.shiftwidth = 2 end,
})
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "asm" },
    callback = function() vim.opt_local.expandtab = false; vim.opt_local.commentstring = "// %s" end,
})

-- Keys
local map = vim.keymap.set
map("n", "<Esc>", "<cmd>nohlsearch<CR>")
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic" })
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostics list" })
map("n", "<leader>f", function() vim.lsp.buf.format() end, { desc = "Format buffer" })
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Save" })
-- Built-in LSP defaults already give: K hover, grn rename, gra code action,
-- grr references, gri implementation, gO symbols, [d ]d diagnostics, CTRL-S signature.

vim.diagnostic.config({ virtual_text = true, severity_sort = true })

-- Language servers (installed by the guide, steps D2, D4, D5, D6)
vim.lsp.config("clangd", {
    cmd = { "clangd", "--background-index", "--clang-tidy" },
    filetypes = { "c", "cpp" },
    root_markers = { "compile_commands.json", "Makefile", ".git" },
})
vim.lsp.config("hls", {
    cmd = { "haskell-language-server-wrapper", "--lsp" },
    filetypes = { "haskell", "lhaskell", "cabal" },
    root_markers = { "hie.yaml", "stack.yaml", "cabal.project", "package.yaml", ".git" },
})
vim.lsp.config("elp", {
    cmd = { "elp", "server" },
    filetypes = { "erlang" },
    root_markers = { "rebar.config", "erlang.mk", ".git" },
})
vim.lsp.config("bashls", {
    cmd = { "bash-language-server", "start" },
    filetypes = { "sh", "bash" },
    root_markers = { ".git" },
})
vim.lsp.enable({ "clangd", "hls", "elp", "bashls" })

-- Completion pops up as you type when a server is attached
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client:supports_method("textDocument/completion") then
            vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
        end
    end,
})

-- Flash yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function() vim.hl.on_yank() end,
})
