local api = require('mychatgpt.api')
local Chat = require('mychatgpt.chat')

local M = {}

M.setup = function()
  vim.api.nvim_set_hl(0, 'MyChatGPT_Question', { fg = '#b4befe', italic = true, bold = false, default = true })
  vim.cmd('sign define mychatgpt_question_sign text=' .. '' .. ' texthl=MyCHATGPT_Question')

  api.setup()
end

M.open_chat = function() M.chat = Chat:new() end

function M.send_hidden_prompt(prompt)
  local chat = Chat:new()
  chat:add_message({
    lines = prompt,
    is_hidden = true,
  })
  chat:send_message()
end

return M
