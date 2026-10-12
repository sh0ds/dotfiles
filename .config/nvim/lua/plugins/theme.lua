-- Catppuccin with no background of its own, so Neovim sits on kitty's frosted
-- glass like every other terminal app instead of a solid block.
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = { transparent_background = true },
  },
}
