local M = {}

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

function M.defaults(v, default_value) return type(v) == 'nil' and default_value or v end

function M.concat_lists(...)
  local result = {}
  for _, tbl in ipairs({ ... }) do
    vim.list_extend(result, tbl)
  end
  return result
end


---@class AutocmdArgs
---@field id number autocmd ID
---@field event string
---@field group string?
---@field buf number
---@field file string
---@field match string | number
---@field data any

---@class Autocommand
---@field desc string?
---@field event  string | string[] list of autocommand events
---@field pattern string | string[] | nil list of autocommand patterns
---@field command string | fun(args: AutocmdArgs): boolean?
---@field nested  boolean?
---@field once    boolean?
---@field buffer  number?

---Create an autocommand
---returns the group ID so that it can be cleared or manipulated.
---@param name string The name of the autocommand group
---@param ... Autocommand A list of autocommands to create
---@return number
function M.augroup(name, ...)
  local commands = { ... }
  assert(name ~= 'User', 'The name of an augroup CANNOT be User')
  assert(#commands > 0, string.format('You must specify at least one autocommand for %s', name))

  local id = vim.api.nvim_create_augroup(name, { clear = true })
  for _, autocmd in ipairs(commands) do
    local is_callback = type(autocmd.command) == 'function'

    vim.api.nvim_create_autocmd(autocmd.event, {
      group = name,
      pattern = autocmd.pattern,
      desc = autocmd.desc,
      callback = is_callback and autocmd.command or nil,
      command = not is_callback and autocmd.command or nil,
      once = autocmd.once,
      nested = autocmd.nested,
      buffer = autocmd.buffer,
    })
  end
  return id
end

--- Check the current window is the leftmost window
function M.is_leftmost_window()
  local winnr = vim.fn.winnr()
  local winnr_left = vim.fn.winnr('l')

  local is_leftmost = winnr == winnr_left
  return is_leftmost
end


--- Guarda a keymap anterior
function M.get_keymap(mode, keys)
  local all_keymaps = vim.api.nvim_get_keymap(mode)
  for _, map in ipairs(all_keymaps) do
    if map.lhs == keys then
      return map
    end
  end
end

function M.restore_keymap(tbl)
  vim.keymap.set(tbl.mode, tbl.lhs, tbl.callback, {
    desc= tbl.desc,
    noremap = tbl.noremap,
    silent = tbl.silent,
  })
end

---@param content  any
function M.log(content)
    local txt = ''
    local function recursive_log(obj, cnt)
        cnt = cnt or 0
        if type(obj) == 'table' then
            txt = txt .. '\n' .. string.rep('\t', cnt) .. '{\n'
            cnt = cnt + 1

            for k, v in pairs(obj) do
                if type(k) == 'string' then txt = txt .. string.rep('\t', cnt) .. '["' .. k .. '"]' .. ' = ' end
                if type(k) == 'number' then txt = txt .. string.rep('\t', cnt) .. '[' .. k .. ']' .. ' = ' end

                recursive_log(v, cnt)
                txt = txt .. ',\n'
            end

            cnt = cnt - 1
            txt = txt .. string.rep('\t', cnt) .. '}'
        elseif type(obj) == 'string' then
            txt = txt .. string.format('%q', obj)
        else
            txt = txt .. tostring(obj)
        end
    end
    recursive_log(content)

    vim.api.nvim_echo({ { txt } }, false, {})
end


return M
