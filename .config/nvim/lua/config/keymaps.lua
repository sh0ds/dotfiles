-- Your own keymaps, on top of LazyVim's (see them all with <space>sk).
local map = vim.keymap.set
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })
map("n", "<leader>ma", "<cmd>!make<cr>", { desc = "Run make in cwd" })

-- Shift held too long on :w / :q
vim.api.nvim_create_user_command("W", "w", {})
vim.api.nvim_create_user_command("Q", "q", {})
vim.api.nvim_create_user_command("Wq", "wq", {})
vim.api.nvim_create_user_command("Coffee", function()
  vim.notify("brewing... just kidding, go make one yourself", vim.log.levels.INFO, { title = "☕" })
end, {})
