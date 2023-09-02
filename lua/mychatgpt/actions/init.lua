local utils = require('mychatgpt.utils')
local Selection = require('mychatgpt.selection')

local M = {}

M.prompts = {
  ['Documentar'] = {
    prompt =
    "Write a {{standard}} docstring for the code below following the following rules:\n- Don't add documentation in the inner scope of the function.\n- Give a concise explanation of the code does.\n- Wrap your code in a markdown code block.\n- Your response must contain only the code.\n{{extra}}",
    standard = {
      default = '',
      lua = 'EmmyLua',
    },
    extra = {
      default = '',
      lua = '- Use 3 dashes for all the EmmyLua annotations (like ---@param param 1 string).',
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
---@param callback fun(prompt: string[])
function M.execute_action(action, callback)
  local system_message = render_template(action)
  system_message = vim.list_extend(system_message, { '', '' })

  local selection = Selection.get_selection()
  local final_prompt = vim.list_extend(system_message, selection.lines)

  callback(final_prompt)
end

return M
