local utils = require('mychatgpt.utils')
local Selection = require('mychatgpt.selection')

local M = {}

function M.get_actions()
  local path = debug.getinfo(1, 'S').source:sub(2):match('(.*/)') .. 'actions.json'
  local file = io.open(path, 'rb')
  if not file then return nil end

  local content = file:read('*a')
  file:close()

  return vim.fn.json_decode(content)
end

local function render_template(title)
  local actions = M.get_actions() or {}
  local item = actions[title]
  local prompt = item.prompt
  local filetype = utils.get_buf_filetype()

  -- find all words that are surrounded by {{}}
  local variables = prompt:gmatch('{{(.-)}}')

  -- replace all {{}} with the value of the variable
  for variable in variables do
    local value = item[variable]
    value = value[filetype] or value.default

    prompt = prompt:gsub('{{' .. variable .. '}}', value)
  end

  local prompt_lines = utils.split_into_lines(prompt)
  return prompt_lines
end

---@param action string
---@param callback fun(prompt: string[])
function M.execute_action(action, callback)
  local system_message = render_template(action)
  system_message = vim.list_extend(system_message, { '', '' })

  local selection = Selection.get_selection()
  local final_prompt = vim.list_extend(system_message, selection.lines)

  callback(final_prompt)
end

return M
