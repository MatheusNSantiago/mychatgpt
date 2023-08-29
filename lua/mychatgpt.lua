local api = require('mychatgpt.api')
local utils = require('mychatgpt.utils')
local Chat = require('mychatgpt.chat')

local M = {}

M.setup = function()
  --
  api.setup()
end

M.open_chat = function()
  M.chat = Chat:new()

  -- if M.chat ~= nil and M.chat.active then
  --   M.chat:toggle()
  -- else
  -- M.chat = Chat:new()
  -- M.chat:open()
  -- end
end

function M.send_selection_to_chat()
  local selection_lines = utils.get_selection_lines()
  local buf_filetype = utils.get_buf_filetype()

  local chat = Chat:new()

  utils.add_code_block_for_filetype(selection_lines, buf_filetype)
  chat:send_lines_to_text_input(selection_lines)
  -- chat:add_message({
  --   lines = selection_lines,
  --   opts = { filetype = buf_filetype },
  -- })
end

return M
