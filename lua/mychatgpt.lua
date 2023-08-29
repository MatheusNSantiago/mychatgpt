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
end

function M.send_selection_to_chat()
  local selection_lines = utils.get_selection_lines()
  local buf_filetype = utils.get_buf_filetype()

  local chat = Chat:new()

  utils.add_code_block_for_filetype(selection_lines, buf_filetype)
  chat:set_prompt(selection_lines)
end

return M
