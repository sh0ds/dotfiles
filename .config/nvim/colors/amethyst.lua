-- Amethyst: nearly monochrome. Code is grey, keywords are bright, strings
-- and numbers are violet, comments are dim. Errors are the only red.
vim.cmd("highlight clear")
vim.g.colors_name = "amethyst"
vim.o.background = "dark"

local c = {
  bg = "NONE", -- kitty's black
  panel = "#0b0910",
  sel = "#3a2a55",
  line = "#2b2238",
  dim = "#5e5270",
  mid = "#7f7494",
  fg = "#b0a6c4",
  bright = "#ece4fb",
  violet = "#b06cff",
  soft = "#c99bff",
  error = "#e0607a",
  warn = "#d9b77a",
  ok = "#9fbf8a",
}

local groups = {
  Normal = { fg = c.fg, bg = c.bg },
  NormalNC = { fg = c.fg, bg = c.bg },
  NormalFloat = { fg = c.fg, bg = c.panel },
  FloatBorder = { fg = c.line, bg = c.panel },
  FloatTitle = { fg = c.bright, bg = c.panel },
  WinSeparator = { fg = c.line },
  LineNr = { fg = c.dim },
  CursorLineNr = { fg = c.violet },
  CursorLine = { bg = c.panel },
  ColorColumn = { bg = c.panel },
  SignColumn = { bg = c.bg },
  Folded = { fg = c.mid, bg = c.panel },
  NonText = { fg = c.line },
  Whitespace = { fg = c.line },
  EndOfBuffer = { fg = c.bg },
  Visual = { bg = c.sel },
  Search = { fg = "#000000", bg = c.soft },
  IncSearch = { fg = "#000000", bg = c.violet },
  CurSearch = { link = "IncSearch" },
  MatchParen = { fg = c.violet, bold = true },
  StatusLine = { fg = c.fg, bg = c.panel },
  StatusLineNC = { fg = c.dim, bg = c.panel },
  TabLine = { fg = c.mid, bg = c.panel },
  TabLineSel = { fg = c.bright, bg = c.bg },
  TabLineFill = { bg = c.panel },
  Pmenu = { fg = c.fg, bg = c.panel },
  PmenuSel = { fg = c.bright, bg = c.sel },
  PmenuSbar = { bg = c.panel },
  PmenuThumb = { bg = c.line },
  Title = { fg = c.bright, bold = true },
  Directory = { fg = c.violet },
  Question = { fg = c.violet },
  MoreMsg = { fg = c.violet },
  ModeMsg = { fg = c.bright },
  ErrorMsg = { fg = c.error },
  WarningMsg = { fg = c.warn },
  Cursor = { fg = "#000000", bg = c.violet },

  Comment = { fg = c.dim, italic = true },
  Constant = { fg = c.soft },
  String = { fg = c.violet },
  Character = { fg = c.violet },
  Number = { fg = c.violet },
  Boolean = { fg = c.violet },
  Float = { fg = c.violet },
  Identifier = { fg = c.fg },
  Function = { fg = c.bright },
  Statement = { fg = c.bright, bold = true },
  Keyword = { fg = c.bright, bold = true },
  Operator = { fg = c.mid },
  PreProc = { fg = c.mid },
  Type = { fg = c.bright },
  Special = { fg = c.soft },
  Delimiter = { fg = c.mid },
  Underlined = { underline = true },
  Error = { fg = c.error },
  Todo = { fg = "#000000", bg = c.violet, bold = true },

  ["@variable"] = { fg = c.fg },
  ["@variable.builtin"] = { fg = c.mid },
  ["@property"] = { fg = c.fg },
  ["@punctuation"] = { fg = c.mid },
  ["@constructor"] = { fg = c.bright },
  ["@tag"] = { fg = c.bright },
  ["@tag.attribute"] = { fg = c.mid },
  ["@markup.heading"] = { fg = c.bright, bold = true },
  ["@markup.link"] = { fg = c.violet, underline = true },
  ["@markup.raw"] = { fg = c.soft },

  DiagnosticError = { fg = c.error },
  DiagnosticWarn = { fg = c.warn },
  DiagnosticInfo = { fg = c.mid },
  DiagnosticHint = { fg = c.dim },
  DiagnosticOk = { fg = c.ok },
  DiagnosticUnderlineError = { undercurl = true, sp = c.error },
  DiagnosticUnderlineWarn = { undercurl = true, sp = c.warn },
  DiagnosticUnderlineInfo = { undercurl = true, sp = c.mid },
  DiagnosticUnderlineHint = { undercurl = true, sp = c.dim },

  DiffAdd = { fg = c.ok },
  DiffChange = { fg = c.warn },
  DiffDelete = { fg = c.error },
  DiffText = { fg = c.bright, bg = c.sel },
  Added = { fg = c.ok },
  Changed = { fg = c.warn },
  Removed = { fg = c.error },
  GitSignsAdd = { fg = c.ok },
  GitSignsChange = { fg = c.warn },
  GitSignsDelete = { fg = c.error },
}

for name, spec in pairs(groups) do
  vim.api.nvim_set_hl(0, name, spec)
end

-- The terminal inside nvim uses the same 16 colours as kitty.
local term = {
  "#0b0910", "#e0607a", "#9fbf8a", "#d9b77a", "#9a8cff", "#b06cff", "#7fb3c4", "#b0a6c4",
  "#5e5270", "#e88a9a", "#b4d0a2", "#e6c995", "#b3a9ff", "#c99bff", "#9cc6d4", "#ece4fb",
}
for i, col in ipairs(term) do
  vim.g["terminal_color_" .. (i - 1)] = col
end
