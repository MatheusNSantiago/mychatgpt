local class = require('mychatgpt.shared.class')
local M = {}

---@alias Selection.constructor fun(opts: SelectionOptions): Selection
---@class Selection
local Selection = class('Selection')

---@class SelectionOptions
---@field lines string[]
---@field start_line integer
---@field end_line integer
---@field start_col integer
---@field end_col integer
---@field bufnr integer

---@param opts SelectionOptions
function Selection:initialize(opts)
  self.lines = opts.lines
  self.start_line = opts.start_line
  self.end_line = opts.end_line
  self.start_col = opts.start_col
  self.end_col = opts.end_col
  self.bufnr = opts.bufnr
end

function Selection:mark_with_sign()
  local start_line = self.start_line
  local end_line = self.end_line

  for i = start_line, end_line do
    vim.fn.sign_place(0, 'mychatgpt_group', 'mychatgpt_action_block', self.bufnr, { lnum = i })
  end
end

function Selection:remove_signs()
  vim.fn.sign_unplace('mychatgpt_group', { buffer = self.bufnr }) --
end

function Selection:replace(lines)
  local start_line = self.start_line
  local end_line = self.end_line

  vim.api.nvim_buf_set_lines(self.bufnr, start_line - 1, end_line, false, lines)

  -- update selection to match new lines
  self.lines = lines
  self.start_line = start_line
  self.end_line = start_line + #lines - 1
end

function Selection:get_lines_with_line_number()
  local numbered_lines = {}
  -- Get the max number of digits needed to display a line number
  local maxDigits = string.len(tostring(#self.lines + self.start_line))
  -- Prepend each line with its line number zero padded to numDigits
  for i, line in ipairs(self.lines) do
    table.insert(numbered_lines, string.format('%0' .. maxDigits .. 'd', i - 1 + self.start_line) .. ' ' .. line)
  end

  return numbered_lines
end

---@return Selection | Selection.constructor | nil
function M.get_selection()
  local mode = vim.api.nvim_get_mode().mode
  local has_visual_selection = mode == 'v' or mode == 'V' or mode == ''
  if not has_visual_selection then return nil end

  local ESC_FEEDKEY = vim.api.nvim_replace_termcodes('<ESC>', true, false, true)

  vim.api.nvim_feedkeys(ESC_FEEDKEY, 'n', true)
  vim.api.nvim_feedkeys('gv', 'x', false)
  vim.api.nvim_feedkeys(ESC_FEEDKEY, 'n', true)

  local _, start_line, start_col = unpack(vim.fn.getpos("'<"))
  local _, end_line, end_col = unpack(vim.fn.getpos("'>"))

  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)

  -- Reduz a primeira/última linha de acordo com start_col/end_col.
  lines[#lines] = lines[#lines]:sub(1, end_col)
  lines[1] = lines[1]:sub(start_col)

  ---@type Selection|Selection.constructor
  local selection = Selection({
    lines = lines,
    start_line = start_line,
    end_line = end_line,
    start_col = start_col,
    end_col = end_col,
    bufnr = bufnr,
  })

  return selection
end

return M
