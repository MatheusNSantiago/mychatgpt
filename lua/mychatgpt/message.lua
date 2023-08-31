local classes = require('mychatgpt.shared.classes')

local Message = classes.class()

---@class MessageOptions
---@field role string 'user' | 'system' | 'assistant'
---@field lines string[]
---@field start_line integer O linha onde começa a mensagem em relação a source
---@field is_hidden? boolean (default false) Se a mensagem deve ser renderizada ou não

--- @param args MessageOptions
function Message:init(args)
  local lines = args.lines
  local is_hidden = args.is_hidden == nil and false or args.is_hidden

  self.role = args.role

  table.insert(lines, '') -- adiciona uma linha no final (margin)

  self.lines = lines
  self.start_line = args.start_line
  self.end_line = self.start_line + #lines - 1

  if is_hidden then
    self.start_line = 0
    self.end_line = 0
  end
end

function Message:get_text() return table.concat(self.lines, '\n') end

return Message
