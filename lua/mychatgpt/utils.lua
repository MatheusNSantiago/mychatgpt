local M = {}
local ESC_FEEDKEY = vim.api.nvim_replace_termcodes('<ESC>', true, false, true)

function M.get_selection_lines()
  vim.api.nvim_feedkeys(ESC_FEEDKEY, 'n', true)
  vim.api.nvim_feedkeys('gv', 'x', false)
  vim.api.nvim_feedkeys(ESC_FEEDKEY, 'n', true)

  local _, start_line, start_col = unpack(vim.fn.getpos("'<"))
  local _, end_line, end_col = unpack(vim.fn.getpos("'>"))

  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)

  -- shorten first/last line according to start_col/end_col
  lines[#lines] = lines[#lines]:sub(1, end_col)
  lines[1] = lines[1]:sub(start_col)

  return lines, start_line, end_line, start_col, end_col
end

function M.get_buf_filetype()
  local bufnr = vim.api.nvim_get_current_buf()
  return vim.api.nvim_buf_get_option(bufnr, 'filetype')
end

--- Quebra a mensagem em linhas
function M.split_into_lines(text)
  local lines = {}
  for line in (text .. '\n'):gmatch('(.-)\n') do
    table.insert(lines, line)
  end
  return lines
end

function M.add_code_block_for_filetype(lines, filetype)
  table.insert(lines, 1, '```' .. filetype)
  table.insert(lines, '```')
end

---@return { message: string, severity: integer }[]|nil
function M.get_line_diagnostics()
  local line = vim.fn.line('.') - 1
  local bufnr = vim.api.nvim_get_current_buf()
  local diagnostics = vim.diagnostic.get(bufnr, { lnum = line, severity = { min = vim.diagnostic.severity.HINT } })

  if #diagnostics == 0 then return nil end

  ---@type table[]
  local obj = {}
  for _, diagnostic in ipairs(diagnostics) do
    table.insert(obj, {
      ---@type string
      message = diagnostic.message,
      ---@type integer
      severity = vim.diagnostic.severity[diagnostic.severity],
    })
  end

  return obj
end

return M
