---@diagnostic disable: undefined-field
local Popup = require('nui.popup')

---@class MessagesWidget
local MessagesWidget = Popup:extend('MessageWidget')

---@class MessagesWidgetOptions
---@field title string
---@field maps? {mode: string, lhs: string, rhs: string, opts: table}[]

---@param opts MessagesWidgetOptions
function MessagesWidget:init(opts)
  self.maps = opts.maps or {}

  MessagesWidget.super.init(self, {
    zindex = 50,
    border = {
      highlight = 'FloatBorder',
      style = 'rounded',
      text = { top = opts.title },
    },
    win_options = {
      wrap = true,
      linebreak = true,
      foldcolumn = '1',
      winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
    },
    buf_options = { filetype = 'markdown' },
  })
  self:_setup_keymaps()
end

function MessagesWidget:scroll_to_end()
  local line_count = vim.api.nvim_buf_line_count(self.bufnr)
  vim.api.nvim_win_set_cursor(self.winid, { line_count, 0 })
end

--- Obtém as linhas do chat da janela.
--- @param start_idx number: O número da linha inicial.
--- @param end_idx number: O número da linha final.
--- @return table: Uma tabela contendo as linhas do chat.
function MessagesWidget:get_lines(start_idx, end_idx)
  local lines = vim.api.nvim_buf_get_lines(self.bufnr, start_idx, end_idx, false)
  return lines
end

function MessagesWidget:set_sign(sign_name, start_line)
  vim.fn.sign_place(0, 'mychatgpt_group', sign_name, self.bufnr, { lnum = start_line + 1 })
end

function MessagesWidget:set_lines(start_idx, end_idx, lines)
  vim.bo[self.bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(self.bufnr, start_idx, end_idx, false, lines)
  vim.bo[self.bufnr].modifiable = false
end

function MessagesWidget:highlight_line(hl_group, line_idx, col_start, col_end)
  vim.api.nvim_buf_add_highlight(self.bufnr, -1, hl_group, line_idx, col_start, col_end)
end

function MessagesWidget:line_count()
  local line_count = vim.api.nvim_buf_line_count(self.bufnr)
  return line_count
end

function MessagesWidget:focus() vim.api.nvim_set_current_win(self.winid) end

function MessagesWidget:_setup_keymaps()
  for _, map in ipairs(self.maps) do
    self:map(map[1], map[2], map[3], map[4])
  end
end

---@alias MessagesWidget.constructor fun(options: MessagesWidgetOptions): MessagesWidget
---@type MessagesWidget|MessagesWidget.constructor
local _MessagesWidget = MessagesWidget
return _MessagesWidget
