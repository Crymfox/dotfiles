return {
  "3rd/image.nvim",
  -- LazyVim will automatically call require("image").setup(opts)
  opts = {
    -- Explicitly force the kitty backend
    backend = "kitty",

    -- Optional: Configure integrations (e.g., viewing images in Markdown)
    integrations = {
      markdown = {
        enabled = true,
        clear_in_insert_mode = false,
        download_remote_images = true,
        only_render_image_at_cursor = false,
        filetypes = { "markdown", "vimwiki" },
      },
      neorg = {
        enabled = true,
        filetypes = { "norg" },
      },
      html = { enabled = false },
      css = { enabled = false },
    },

    -- Maximum dimensions for rendered images
    max_width = nil,
    max_height = nil,
    max_width_window_percentage = 96,
    max_height_window_percentage = 96,

    -- Clear images when windows overlap (prevents visual glitches with LazyVim UI)
    window_overlap_clear_enabled = true,
    window_overlap_clear_ft_ignore = {
      "cmp_menu",
      "cmp_docs",
      "snacks_notif",
      "scrollview",
      "scrollview_sign",
      "noice", -- Ignore Noice.nvim popups if you use them
      "lazy", -- Ignore Lazy.nvim UI
    },
  },
}
