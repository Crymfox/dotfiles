return {
    {
      "xTacobaco/cursor-agent.nvim",
      config = function()
        require("cursor-agent").setup({
          -- Optional: Customize if needed, e.g., path to the CLI if not on PATH
          cmd = "cursor-agent",
          args = {},  -- Add any default args here if you want
        })
  
        -- Suggested keymaps (adjust <leader>ca to your preference)
        vim.keymap.set("n", "<leader>ca", ":CursorAgent<CR>", {
          desc = "Cursor Agent: Toggle terminal",
        })
        vim.keymap.set("v", "<leader>ca", ":CursorAgentSelection<CR>", {
          desc = "Cursor Agent: Send selection",
        })
        vim.keymap.set("n", "<leader>cA", ":CursorAgentBuffer<CR>", {
          desc = "Cursor Agent: Send buffer",
        })
      end,
    },
  }