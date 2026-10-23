-- Diag: nearly monochrome. Code is grey, keywords are bright, strings
-- and numbers are blue, comments are dim. Errors are the only red.
vim.cmd("highlight clear")
vim.g.colors_name = "diag"
vim.o.background = "dark"

local c = {
  bg = "NONE", -- kitty's black
  panel = "#0d1014",
  sel = "#0e3d5c",
  line = "#2e353d",
  dim = "#5d6670",
  mid = "#8a929c",
  fg = "#c4c9ce",
  bright = "#f4f6f8",
  arch = "#1793d1",
  soft = "#5fb8e8",
  error = "#e5484d",
  warn = "#ffb000",
  ok = "#75c94d",
}

local groups = {
  Normal = { fg = c.fg, bg = c.bg },
  NormalNC = { fg = c.fg, bg = c.bg },
  NormalFloat = { fg = c.fg, bg = c.panel },
  FloatBorder = { fg = c.line, bg = c.panel },
  FloatTitle = { fg = c.bright, bg = c.panel },
  WinSeparator = { fg = c.line },
  LineNr = { fg = c.dim },
  CursorLineNr = { fg = c.arch },
  CursorLine = { bg = c.panel },
  ColorColumn = { bg = c.panel },
  SignColumn = { bg = c.bg },
  Folded = { fg = c.mid, bg = c.panel },
  NonText = { fg = c.line },
  Whitespace = { fg = c.line },
  EndOfBuffer = { fg = c.bg },
  Visual = { bg = c.sel },
  Search = { fg = "#000000", bg = c.soft },
  IncSearch = { fg = "#000000", bg = c.arch },
  CurSearch = { link = "IncSearch" },
  MatchParen = { fg = c.arch, bold = true },
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
  Directory = { fg = c.arch },
  Question = { fg = c.arch },
  MoreMsg = { fg = c.arch },
  ModeMsg = { fg = c.bright },
  ErrorMsg = { fg = c.error },
  WarningMsg = { fg = c.warn },
  Cursor = { fg = "#000000", bg = c.arch },

  Comment = { fg = c.dim, italic = true },
  Constant = { fg = c.soft },
  String = { fg = c.arch },
  Character = { fg = c.arch },
  Number = { fg = c.arch },
  Boolean = { fg = c.arch },
  Float = { fg = c.arch },
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
  Todo = { fg = "#000000", bg = c.arch, bold = true },

  ["@variable"] = { fg = c.fg },
  ["@variable.builtin"] = { fg = c.mid },
  ["@property"] = { fg = c.fg },
  ["@punctuation"] = { fg = c.mid },
  ["@constructor"] = { fg = c.bright },
  ["@tag"] = { fg = c.bright },
  ["@tag.attribute"] = { fg = c.mid },
  ["@markup.heading"] = { fg = c.bright, bold = true },
  ["@markup.link"] = { fg = c.arch, underline = true },
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
  "#0d1014", "#e5484d", "#75c94d", "#ffb000", "#4aa3df", "#1793d1", "#7cc7d6", "#c4c9ce",
  "#5d6670", "#ee7a7d", "#9fdc7c", "#ffd166", "#8fc3e6", "#5fb8e8", "#a9e0ea", "#f4f6f8",
}
for i, col in ipairs(term) do
  vim.g["terminal_color_" .. (i - 1)] = col
end
