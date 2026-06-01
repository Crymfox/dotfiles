-- Pin telescope.nvim to a version compatible with Neovim 0.10.1
-- Latest telescope requires 0.10.4, but this version works with 0.9.0+
return {
  "nvim-telescope/telescope.nvim",
  commit = "84b9ba066d1860f7a586ce9cd732fd6c4f77d1d9", -- Last commit before 0.10.4 requirement
  opts = {
    defaults = {
      -- Show hidden files (dotfiles like .env)
      file_ignore_patterns = {
        "node_modules",
        ".git/",
      },
    },
    pickers = {
      find_files = {
        hidden = true,           -- Show hidden/dotfiles
        no_ignore = true,        -- Don't respect .gitignore (allows finding .env files)
        follow = true,           -- Follow symlinks
      },
    },
  },
}

