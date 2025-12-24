return {
  {
    "xTacobaco/cursor-agent.nvim",
    config = function()
      require("cursor-agent").setup({
        cmd = "cursor-agent",
        args = {},
      })

      -- Cursor Agent keymaps: <leader>C prefix (capital C for Cursor)
      vim.keymap.set("n", "<leader>C", ":CursorAgent<CR>", {
        desc = "Cursor Agent: Toggle terminal",
      })

      -- Double ESC handler: single ESC sends to cursor-agent, double ESC exits terminal mode
      local esc_state = {}

      local function get_state(buf)
        if not esc_state[buf] then
          esc_state[buf] = { waiting = false, timer_handle = nil }
        end
        return esc_state[buf]
      end

      local function handle_esc()
        local buf = vim.api.nvim_get_current_buf()
        local state = get_state(buf)
        local esc_timeout = 200

        if state.waiting then
          -- Second ESC: exit terminal mode
          state.timer_handle = nil
          state.waiting = false
          vim.cmd("stopinsert")
          return
        end

        -- First ESC: start timer, send ESC to cursor-agent after timeout
        state.waiting = true
        local timer_ref = {}
        state.timer_handle = timer_ref

        vim.defer_fn(function()
          if state.timer_handle ~= timer_ref then
            return
          end
          state.waiting = false
          state.timer_handle = nil

          if vim.api.nvim_buf_is_valid(buf) then
            local chan = vim.api.nvim_buf_get_var(buf, "terminal_job_id")
            if chan then
              vim.api.nvim_chan_send(chan, vim.api.nvim_replace_termcodes("<Esc>", true, false, true))
            end
          end
        end, esc_timeout)
      end

      -- Global yank: strips borders from cursor-agent, normal yank elsewhere
      vim.keymap.set("v", "y", function()
        local buf = vim.api.nvim_get_current_buf()
        local buf_name = vim.api.nvim_buf_get_name(buf)

        if buf_name:match("cursor%-agent") and vim.bo[buf].buftype == "terminal" then
          local start_pos = vim.fn.getpos("v")
          local end_pos = vim.fn.getpos(".")
          local start_line = math.min(start_pos[2], end_pos[2])
          local end_line = math.max(start_pos[2], end_pos[2])
          local lines = vim.api.nvim_buf_get_lines(buf, start_line - 1, end_line, false)

          local cleaned_lines = {}
          for _, line in ipairs(lines) do
            local cleaned = line:gsub("[│─┌┐└┘├┤┬┴┼╭╮╯╰]", ""):match("^%s*(.-)%s*$")
            table.insert(cleaned_lines, cleaned or "")
          end

          if #cleaned_lines > 0 then
            local text = table.concat(cleaned_lines, "\n")
            vim.fn.setreg("+", text)
            vim.fn.setreg('"', text)
            vim.notify("Yanked (cleaned): " .. #cleaned_lines .. " lines", vim.log.levels.INFO)
          end

          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
        else
          vim.cmd("normal! y")
        end
      end, { desc = "Yank (with cursor-agent border cleanup)" })

      -- Store original dimensions and last position for each buffer
      local original_dimensions = {}
      local last_position = {}

      -- Function to resize cursor-agent floating window
      local function resize_cursor_agent(buf)
        vim.schedule(function()
          local win = vim.fn.bufwinid(buf)
          if win ~= -1 then
            local config = vim.api.nvim_win_get_config(win)
            if config.relative ~= "" then
              local ui = vim.api.nvim_list_uis()[1]
              local target_height = math.floor(ui.height * 0.8)
              local target_width = math.floor(ui.width * 0.6)
              local target_row = math.floor((ui.height - target_height) / 2)
              local target_col = math.floor((ui.width - target_width) / 2)

              -- Only resize if dimensions or position actually changed
              local current_row = type(config.row) == "table" and config.row[1] or config.row
              local current_col = type(config.col) == "table" and config.col[1] or config.col

              if
                config.height ~= target_height
                or config.width ~= target_width
                or current_row ~= target_row
                or current_col ~= target_col
              then
                config.height = target_height
                config.width = target_width
                config.row = target_row
                config.col = target_col
                vim.api.nvim_win_set_config(win, config)

                -- Store original dimensions by buffer ID
                original_dimensions[buf] = {
                  width = config.width,
                  height = config.height,
                }
                
                -- Store initial centered position by buffer ID
                last_position[buf] = {
                  row = target_row,
                  col = target_col,
                  width = target_width,
                  height = target_height,
                }
              end
            end
          end
        end)
      end

      -- Function to move cursor-agent floating window
      local function move_cursor_agent(direction)
        local buf = vim.api.nvim_get_current_buf()
        local win = vim.fn.bufwinid(buf)
        if win == -1 then
          return
        end

        local config = vim.api.nvim_win_get_config(win)
        if config.relative == "" then
          return
        end

        local move_amount = 2
        local ui = vim.api.nvim_list_uis()[1]

        -- Get current position and dimensions
        local current_row = type(config.row) == "table" and config.row[1] or config.row
        local current_col = type(config.col) == "table" and config.col[1] or config.col
        local current_width = config.width
        local current_height = config.height

        -- Get original dimensions by buffer ID
        local orig = original_dimensions[buf] or { width = current_width, height = current_height }

        local new_row = current_row
        local new_col = current_col
        local new_width = current_width
        local new_height = current_height

        -- Check if we're at borders (with small threshold for right/bottom to account for previous moves)
        local at_left_border = current_col <= 0
        local at_right_border = current_col + current_width >= ui.width - move_amount
        local at_top_border = current_row <= 0
        local at_bottom_border = current_row + current_height >= ui.height - move_amount

        -- Check if next movement would hit border
        if direction == "h" then
          -- Moving left: restore width only if NOT at left border and width is shrunk
          if not at_left_border and current_width < orig.width then
            -- Restore width progressively (was shrunk by moving right)
            new_width = math.min(orig.width, current_width + move_amount)
            new_col = current_col - move_amount
          elseif at_left_border then
            -- Already at left border: shrink from left side, stay at border
            new_width = math.max(10, current_width - move_amount)
            new_col = 0
          elseif current_col - move_amount <= 0 then
            -- Would hit left border: just move to border without shrinking yet
            new_col = 0
          else
            -- Normal movement
            new_col = current_col - move_amount
          end
        elseif direction == "l" then
          -- Moving right: restore width only if NOT at right border and width is shrunk
          if not at_right_border and current_width < orig.width then
            -- Restore width progressively (was shrunk by moving left)
            new_width = math.min(orig.width, current_width + move_amount)
            new_col = current_col
          elseif current_col + current_width + move_amount >= ui.width then
            -- Would hit right border: shrink from right side, move right to stay at border
            new_width = math.max(10, current_width - move_amount)
            new_col = current_col + move_amount
          else
            -- Normal movement
            new_col = current_col + move_amount
          end
        elseif direction == "k" then
          -- Moving up: restore height only if NOT at top border and height is shrunk
          if not at_top_border and current_height < orig.height then
            -- Restore height progressively (was shrunk by moving down)
            new_height = math.min(orig.height, current_height + move_amount)
            new_row = current_row - move_amount
          elseif at_top_border then
            -- Already at top border: shrink from top, stay at border
            new_height = math.max(5, current_height - move_amount)
            new_row = 0
          elseif current_row - move_amount <= 0 then
            -- Would hit top border: just move to border without shrinking yet
            new_row = 0
          else
            -- Normal movement
            new_row = current_row - move_amount
          end
        elseif direction == "j" then
          -- Moving down: restore height only if NOT at bottom border and height is shrunk
          if not at_bottom_border and current_height < orig.height then
            -- Restore height progressively (was shrunk by moving up)
            new_height = math.min(orig.height, current_height + move_amount)
            new_row = current_row
          elseif current_row + current_height + move_amount >= ui.height then
            -- Would hit bottom border: shrink from bottom, move down to stay at border
            new_height = math.max(5, current_height - move_amount)
            new_row = current_row + move_amount
          else
            -- Normal movement
            new_row = current_row + move_amount
          end
        end

        -- Build new config
        local new_config = {
          relative = "editor",
          row = new_row,
          col = new_col,
          width = new_width,
          height = new_height,
          anchor = config.anchor or "NW",
          style = config.style,
          border = config.border,
          zindex = config.zindex,
          focusable = config.focusable,
        }

        pcall(vim.api.nvim_win_set_config, win, new_config)
        
        -- Save the current position after moving by buffer ID
        last_position[buf] = {
          row = new_row,
          col = new_col,
          width = new_width,
          height = new_height,
        }
      end

      -- Set up ESC handler when cursor-agent terminal opens
      vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "*cursor-agent*",
        callback = function()
          local buf = vim.api.nvim_get_current_buf()
          local state = get_state(buf)
          state.waiting = false
          state.timer_handle = nil

          vim.keymap.set("t", "<Esc>", handle_esc, {
            buffer = buf,
            desc = "Double ESC to exit terminal, single ESC to cursor-agent",
          })

          -- Keymaps to move the floating window
          -- Keymaps to move the floating window (terminal mode)
          vim.keymap.set("t", "<M-h>", function()
            move_cursor_agent("h")
          end, { buffer = buf, desc = "Move cursor-agent window left" })

          vim.keymap.set("t", "<M-j>", function()
            move_cursor_agent("j")
          end, { buffer = buf, desc = "Move cursor-agent window down" })

          vim.keymap.set("t", "<M-k>", function()
            move_cursor_agent("k")
          end, { buffer = buf, desc = "Move cursor-agent window up" })

          vim.keymap.set("t", "<M-l>", function()
            move_cursor_agent("l")
          end, { buffer = buf, desc = "Move cursor-agent window right" })

          -- Same keymaps for normal mode
          vim.keymap.set("n", "<M-h>", function()
            move_cursor_agent("h")
          end, { buffer = buf, desc = "Move cursor-agent window left" })

          vim.keymap.set("n", "<M-j>", function()
            move_cursor_agent("j")
          end, { buffer = buf, desc = "Move cursor-agent window down" })

          vim.keymap.set("n", "<M-k>", function()
            move_cursor_agent("k")
          end, { buffer = buf, desc = "Move cursor-agent window up" })

          vim.keymap.set("n", "<M-l>", function()
            move_cursor_agent("l")
          end, { buffer = buf, desc = "Move cursor-agent window right" })

          resize_cursor_agent(buf)
        end,
      })

      -- Restore position when cursor-agent window is shown (after hiding and re-showing)
      vim.api.nvim_create_autocmd("BufWinEnter", {
        pattern = "*cursor-agent*",
        callback = function()
          local buf = vim.api.nvim_get_current_buf()
          local win = vim.fn.bufwinid(buf)
          
          -- If we have a saved position, restore it
          if win ~= -1 and last_position[buf] then
            vim.schedule(function()
              if vim.api.nvim_win_is_valid(win) then
                local config = vim.api.nvim_win_get_config(win)
                if config.relative ~= "" then
                  local saved = last_position[buf]
                  config.row = saved.row
                  config.col = saved.col
                  config.width = saved.width
                  config.height = saved.height
                  pcall(vim.api.nvim_win_set_config, win, config)
                end
              end
            end)
          else
            -- No saved position, center it (first time opening)
            resize_cursor_agent(buf)
          end
        end,
      })

      -- Clean up state on buffer delete
      vim.api.nvim_create_autocmd("BufDelete", {
        pattern = "*cursor-agent*",
        callback = function(args)
          esc_state[args.buf] = nil
          -- Clean up original dimensions and last position by buffer ID
          original_dimensions[args.buf] = nil
          last_position[args.buf] = nil
        end,
      })
    end,
  },
}
