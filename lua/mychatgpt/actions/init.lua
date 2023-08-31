local utils = require('mychatgpt.utils')

local M = {}

M.prompts = {
  ['Documentar'] = {
    prompt =
    'Write a {{standard}} docstring for the code below. Wrap your code in a markdown code block. Dont give me any explanation, just the code. {{extra}}',
    standard = {
      default = '',
      lua = 'EmmyLua',
    },
    extra = {
      default = '',
      lua = 'Use 3 dashes for all the EmmyLua annotations (like ---@param param 1 string).',
    },
  },
}

local function render_template(title)
  local item = M.prompts[title]
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
function M.execute_action(action, callback)
  local system_message = render_template(action)
  system_message = vim.list_extend(system_message, { '', '' })

  local selected_lines = utils.get_selection_lines()
  local final_prompt = vim.list_extend(system_message, selected_lines)

  callback(final_prompt)
end

return M
