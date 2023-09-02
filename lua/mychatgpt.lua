local Chat = require('mychatgpt.chat')

local M = {
  chat = nil,
  selection = nil,
}

function M.setup()
  vim.api.nvim_set_hl(0, 'MyChatGPT_Question', { fg = '#b4befe', italic = true, bold = false, default = true })
  vim.cmd('sign define mychatgpt_question_sign text=' .. '' .. ' texthl=MyCHATGPT_Question')

  vim.cmd([[sign define mychatgpt_action_block text=│ texthl=ErrorMsg]])
  -- vim.cmd([[sign define mychatgpt_action_block text=│ texthl=ErrorMsg linehl=BufferLineBackground]])
end

---@param params? { on_exit: function }
function M.open_new_chat(params)
  params = params or {}
  M.chat = Chat.new({ on_exit = params.on_exit })
  M.chat:open()
end

function M.send_hidden_prompt(prompt)
  M.chat:add_message({ lines = prompt, is_hidden = true })
  M.chat:send_message()
end

function M.replace_selection_with_last_code_block()
  local code_block = M.chat:get_last_code_block()

  if code_block and M.selection then
    M.selection:replace(code_block)
  end
end

return M
