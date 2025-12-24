-- Nero colorscheme - hardcoded to match terminal colors

-- Clear existing highlights
vim.cmd("hi clear")
if vim.fn.exists("syntax_on") then
  vim.cmd("syntax reset")
end

vim.o.background = "dark"
vim.g.colors_name = "nero"

-- Define Nero color palette (from your Alacritty theme)
local colors = {
  -- Base colors
  bg = "#0d1c2e",
  fg = "#a9c7d6",
  
  -- Normal colors
  black = "#0A1522",
  red = "#f5596b",
  green = "#92cc33",
  yellow = "#e0a352",
  blue = "#0da8f2",
  magenta = "#b291f3",
  cyan = "#3df5de",
  white = "#a9c7d6",
  
  -- Bright colors
  bright_black = "#132842",
  bright_red = "#f5596b",
  bright_green = "#92cc33",
  bright_yellow = "#e0a352",
  bright_blue = "#0da8f2",
  bright_magenta = "#b291f3",
  bright_cyan = "#3df5de",
  bright_white = "#a9c7d6",
  
  -- UI colors
  bg_dark = "#0A1522",
  bg_highlight = "#132842",
  bg_visual = "#1a3a52",
  border = "#132842",
  comment = "#4a6b8a",
  
  -- Additional indexed colors
  orange = "#ff9e64",
  dark_red = "#db4b4b",
}

-- Helper function to set highlights
local function hl(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- Editor highlights
hl("Normal", { fg = colors.fg, bg = "NONE" })
hl("NormalFloat", { fg = colors.fg, bg = colors.bg_dark })
hl("FloatBorder", { fg = colors.border, bg = colors.bg_dark })
hl("NormalNC", { fg = colors.fg, bg = "NONE" })
hl("LineNr", { fg = colors.comment })
hl("CursorLine", { bg = colors.bg_highlight })
hl("CursorLineNr", { fg = colors.yellow, bold = true })
hl("Visual", { bg = colors.bg_visual })
hl("VisualNOS", { bg = colors.bg_visual })
hl("Search", { fg = colors.bg, bg = colors.yellow })
hl("IncSearch", { fg = colors.bg, bg = colors.orange })
hl("ColorColumn", { bg = colors.bg_highlight })
hl("SignColumn", { fg = colors.comment, bg = "NONE" })
hl("VertSplit", { fg = colors.border })
hl("StatusLine", { fg = colors.fg, bg = colors.bg_highlight })
hl("StatusLineNC", { fg = colors.comment, bg = colors.bg_dark })
hl("Pmenu", { fg = colors.fg, bg = colors.bg_dark })
hl("PmenuSel", { fg = colors.bg, bg = colors.blue })
hl("PmenuSbar", { bg = colors.bg_highlight })
hl("PmenuThumb", { bg = colors.comment })
hl("TabLine", { fg = colors.comment, bg = colors.bg_dark })
hl("TabLineFill", { bg = colors.bg_dark })
hl("TabLineSel", { fg = colors.fg, bg = "NONE" })
hl("Folded", { fg = colors.comment, bg = colors.bg_highlight })
hl("FoldColumn", { fg = colors.comment, bg = "NONE" })

-- Syntax highlighting
hl("Comment", { fg = colors.comment, italic = true })
hl("Constant", { fg = colors.orange })
hl("String", { fg = colors.green })
hl("Character", { fg = colors.green })
hl("Number", { fg = colors.orange })
hl("Boolean", { fg = colors.orange })
hl("Float", { fg = colors.orange })
hl("Identifier", { fg = colors.cyan })
hl("Function", { fg = colors.blue })
hl("Statement", { fg = colors.magenta })
hl("Conditional", { fg = colors.magenta })
hl("Repeat", { fg = colors.magenta })
hl("Label", { fg = colors.magenta })
hl("Operator", { fg = colors.cyan })
hl("Keyword", { fg = colors.magenta })
hl("Exception", { fg = colors.magenta })
hl("PreProc", { fg = colors.cyan })
hl("Include", { fg = colors.magenta })
hl("Define", { fg = colors.magenta })
hl("Macro", { fg = colors.cyan })
hl("PreCondit", { fg = colors.cyan })
hl("Type", { fg = colors.yellow })
hl("StorageClass", { fg = colors.yellow })
hl("Structure", { fg = colors.yellow })
hl("Typedef", { fg = colors.yellow })
hl("Special", { fg = colors.cyan })
hl("SpecialChar", { fg = colors.orange })
hl("Tag", { fg = colors.blue })
hl("Delimiter", { fg = colors.fg })
hl("SpecialComment", { fg = colors.comment, italic = true })
hl("Debug", { fg = colors.red })
hl("Underlined", { underline = true })
hl("Error", { fg = colors.red, bold = true })
hl("Todo", { fg = colors.bg, bg = colors.yellow, bold = true })

-- Treesitter highlights
hl("@variable", { fg = colors.fg })
hl("@variable.builtin", { fg = colors.red })
hl("@variable.parameter", { fg = colors.orange })
hl("@variable.member", { fg = colors.cyan })
hl("@constant", { fg = colors.orange })
hl("@constant.builtin", { fg = colors.orange })
hl("@module", { fg = colors.cyan })
hl("@string", { fg = colors.green })
hl("@string.escape", { fg = colors.magenta })
hl("@string.regexp", { fg = colors.blue })
hl("@character", { fg = colors.green })
hl("@number", { fg = colors.orange })
hl("@boolean", { fg = colors.orange })
hl("@float", { fg = colors.orange })
hl("@function", { fg = colors.blue })
hl("@function.builtin", { fg = colors.cyan })
hl("@function.macro", { fg = colors.cyan })
hl("@function.method", { fg = colors.blue })
hl("@constructor", { fg = colors.yellow })
hl("@keyword", { fg = colors.magenta })
hl("@keyword.function", { fg = colors.magenta })
hl("@keyword.operator", { fg = colors.magenta })
hl("@keyword.return", { fg = colors.magenta })
hl("@conditional", { fg = colors.magenta })
hl("@repeat", { fg = colors.magenta })
hl("@label", { fg = colors.blue })
hl("@operator", { fg = colors.cyan })
hl("@exception", { fg = colors.magenta })
hl("@type", { fg = colors.yellow })
hl("@type.builtin", { fg = colors.yellow })
hl("@attribute", { fg = colors.cyan })
hl("@property", { fg = colors.cyan })
hl("@tag", { fg = colors.red })
hl("@tag.attribute", { fg = colors.orange })
hl("@tag.delimiter", { fg = colors.cyan })
hl("@punctuation.delimiter", { fg = colors.fg })
hl("@punctuation.bracket", { fg = colors.fg })
hl("@punctuation.special", { fg = colors.cyan })
hl("@comment", { fg = colors.comment, italic = true })

-- LSP highlights
hl("DiagnosticError", { fg = colors.red })
hl("DiagnosticWarn", { fg = colors.yellow })
hl("DiagnosticInfo", { fg = colors.blue })
hl("DiagnosticHint", { fg = colors.cyan })
hl("DiagnosticUnderlineError", { undercurl = true, sp = colors.red })
hl("DiagnosticUnderlineWarn", { undercurl = true, sp = colors.yellow })
hl("DiagnosticUnderlineInfo", { undercurl = true, sp = colors.blue })
hl("DiagnosticUnderlineHint", { undercurl = true, sp = colors.cyan })

-- Git highlights
hl("GitSignsAdd", { fg = colors.green })
hl("GitSignsChange", { fg = colors.yellow })
hl("GitSignsDelete", { fg = colors.red })
hl("DiffAdd", { fg = colors.green, bg = colors.bg_dark })
hl("DiffChange", { fg = colors.yellow, bg = colors.bg_dark })
hl("DiffDelete", { fg = colors.red, bg = colors.bg_dark })
hl("DiffText", { fg = colors.blue, bg = colors.bg_highlight })

-- Telescope
hl("TelescopeBorder", { fg = colors.border, bg = colors.bg_dark })
hl("TelescopeNormal", { fg = colors.fg, bg = colors.bg_dark })
hl("TelescopeSelection", { fg = colors.fg, bg = colors.bg_highlight })
hl("TelescopeSelectionCaret", { fg = colors.blue, bg = colors.bg_highlight })
hl("TelescopeMatching", { fg = colors.yellow, bold = true })

-- Neo-tree
hl("NeoTreeNormal", { fg = colors.fg, bg = "NONE" })
hl("NeoTreeNormalNC", { fg = colors.fg, bg = "NONE" })
hl("NeoTreeDirectoryIcon", { fg = colors.blue })
hl("NeoTreeDirectoryName", { fg = colors.blue })
hl("NeoTreeGitModified", { fg = colors.yellow })
hl("NeoTreeGitAdded", { fg = colors.green })
hl("NeoTreeGitDeleted", { fg = colors.red })

-- WhichKey
hl("WhichKey", { fg = colors.cyan })
hl("WhichKeyGroup", { fg = colors.blue })
hl("WhichKeyDesc", { fg = colors.magenta })
hl("WhichKeySeparator", { fg = colors.comment })
hl("WhichKeyFloat", { bg = colors.bg_dark })
hl("WhichKeyBorder", { fg = colors.border, bg = colors.bg_dark })

-- Notify
hl("NotifyBackground", { bg = "NONE" })
hl("NotifyERRORBorder", { fg = colors.red })
hl("NotifyWARNBorder", { fg = colors.yellow })
hl("NotifyINFOBorder", { fg = colors.blue })
hl("NotifyDEBUGBorder", { fg = colors.comment })
hl("NotifyTRACEBorder", { fg = colors.magenta })

-- Dashboard / Alpha
hl("DashboardHeader", { fg = colors.blue })
hl("DashboardCenter", { fg = colors.cyan })
hl("DashboardShortCut", { fg = colors.magenta })
hl("DashboardFooter", { fg = colors.green, italic = true })

