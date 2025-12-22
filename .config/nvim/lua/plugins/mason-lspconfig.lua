-- Pin mason-lspconfig to a version compatible with this LazyVim version
-- This prevents API breakage from the mason-lspconfig 2.2.0 refactor
return {
  "williamboman/mason-lspconfig.nvim",
  commit = "5c142464ea29ceca3b4d77d2c80b9e8e3fca02d9", -- Last commit before API breaking change
}

