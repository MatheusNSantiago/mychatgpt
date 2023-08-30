local Popup = require('nui.popup')

local ChatWindow = Popup({
  border = {
    highlight = 'FloatBorder',
    style = 'rounded',
    text = {
      top = ' Mochila de Criança ',
    },
  },
  win_options = {
    wrap = true,
    linebreak = true,
    foldcolumn = '1',
    winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
  },
  buf_options = { filetype = 'markdown' },
})

ChatWindow:map('n', 'q', ':q<CR>', { desc = 'Quit chat' })

function ChatWindow:scroll_to_end()
  local line_count = vim.api.nvim_buf_line_count(self.bufnr)
  vim.api.nvim_win_set_cursor(self.winid, { line_count, 0 })
end

--- Obtém as linhas do chat da janela.
--- @param start_idx number: O número da linha inicial.
--- @param end_idx number: O número da linha final.
--- @return table: Uma tabela contendo as linhas do chat.
function ChatWindow:get_lines(start_idx, end_idx)
  local lines = vim.api.nvim_buf_get_lines(self.bufnr, start_idx, end_idx, false)
  return lines
end

function ChatWindow:set_sign(sign_name, start_line)
  vim.fn.sign_place(0, nil, sign_name, self.bufnr, { lnum = start_line + 1 })
end

function ChatWindow:set_lines(start_idx, end_idx, lines)
  vim.api.nvim_buf_set_option(self.bufnr, 'modifiable', true)
  vim.api.nvim_buf_set_lines(self.bufnr, start_idx, end_idx, false, lines)
  vim.api.nvim_buf_set_option(self.bufnr, 'modifiable', false)
end

function ChatWindow:highlight_line(hl_group, line_idx, col_start, col_end)
  vim.api.nvim_buf_add_highlight(self.bufnr, -1, hl_group, line_idx, col_start, col_end)
end

function ChatWindow:line_count()
  local line_count = vim.api.nvim_buf_line_count(self.bufnr)
  return line_count
end

return ChatWindow
