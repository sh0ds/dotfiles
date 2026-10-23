-- Diag also owns the plugin chrome; automatic themes can fall back to a
-- rainbow palette when a custom colorscheme has no integration module.
local bg, panel, rule = "#000000", "#0d1014", "#3f4650"
local fg, mid, blue = "#e6e8ea", "#8a929c", "#1793d1"
local active = { fg = bg, bg = blue, gui = "bold" }
local mode = {
  a = active,
  b = { fg = fg, bg = panel },
  c = { fg = mid, bg = bg },
}

return {
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        theme = {
          normal = mode, insert = mode, visual = mode, replace = mode,
          command = mode, terminal = mode,
          inactive = {
            a = { fg = mid, bg = bg },
            b = { fg = mid, bg = bg },
            c = { fg = mid, bg = bg },
          },
        },
        component_separators = { left = "│", right = "│" },
        section_separators = { left = "", right = "" },
      },
    },
  },
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = { separator_style = "thin" },
      highlights = {
        fill = { bg = bg },
        background = { fg = mid, bg = bg },
        buffer_visible = { fg = mid, bg = panel },
        buffer_selected = { fg = fg, bg = panel, bold = true, italic = false },
        indicator_selected = { fg = blue, bg = panel },
        separator = { fg = rule, bg = bg },
        separator_selected = { fg = rule, bg = panel },
        close_button = { fg = mid, bg = bg },
        close_button_selected = { fg = blue, bg = panel },
        modified = { fg = "#ffb000", bg = bg },
        modified_selected = { fg = "#ffb000", bg = panel },
      },
    },
  },
}
