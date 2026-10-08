-- Your own keymaps, on top of LazyVim's (see them all with <space>sk).
local map = vim.keymap.set
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>ma", "<cmd>!make<cr>", { desc = "Run make in cwd" })
