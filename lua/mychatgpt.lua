local Chat = require('mychatgpt.chat')

local M = {}

M.setup = function()
  vim.api.nvim_set_hl(0, 'MyChatGPT_Question', { fg = '#b4befe', italic = true, bold = false, default = true })
  vim.cmd('sign define mychatgpt_question_sign text=' .. '' .. ' texthl=MyCHATGPT_Question')

  vim.cmd([[sign define mychatgpt_action_block text=│ texthl=ErrorMsg linehl=BufferLineBackground]])
end

M.open_chat = function() M.chat = Chat:new() end

function M.send_hidden_prompt(prompt)
  local chat = Chat:new()
  chat:add_message({ lines = prompt, is_hidden = true })
  chat:send_message()
end

M.teste = function()
  -- local bufnr = vim.api.nvim_get_current_buf()
  --
  -- local lines, start_line, end_line = utils.get_selection_lines()
  -- for i = start_line, end_line do
  --   vim.fn.sign_place(0, 'mychatgpt_group', 'mychatgpt_action_block', bufnr, { lnum = i })
  -- end
  -- vim.fn.sign_unplace('mychatgpt_group', { buffer = bufnr })

  M.open_chat()
  M.chat:add_message({ lines = { 'Olá' } })
  M.chat:add_message({ lines = { 'Olá! Como posso ajudar você hoje?' }, role = 'assistant' })
end

M.foo = function()

end

return M
