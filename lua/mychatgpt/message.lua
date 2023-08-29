local classes = require('mychatgpt.shared.classes')
local utils = require('mychatgpt.utils')

local Message = classes.class()

---@class MessageOptions
---@field hl_group? string
---@field filetype? string

--- @param role string 'user' | 'system' | 'assistant'
--- @param lines string[]
--- @param start_line integer O linha onde começa a mensagem em relação a source
--- @param opts MessageOptions
function Message:init(role, lines, start_line, opts)
  self.role = role
  self.opts = opts or {}

  local is_code_snippet = self.opts.filetype ~= nil
  if is_code_snippet then
    -- ```filetype
    utils.add_code_block_for_filetype(lines, self.opts.filetype)
  end

  table.insert(lines, '') -- add empty line no final (margin)

  self.lines = lines
  self.start_line = start_line
  self.end_line = start_line + #lines - 1
end

function Message:get_text() return table.concat(self.lines, '\n') end

return Message
