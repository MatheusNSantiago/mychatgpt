local class = require('mychatgpt.shared.class')
local utils = require('mychatgpt.utils')

---@class Message
local Message = class('Message')

---@class MessageOptions
---@field role string 'user' | 'system' | 'assistant'
---@field lines string[]
---@field start_line? integer (default 0) O linha onde começa a mensagem em relação a source
---@field is_hidden? boolean (default false) Se a mensagem deve ser renderizada ou não

--- @param args MessageOptions
function Message:initialize(args)
  local lines = args.lines
  self.is_hidden = args.is_hidden == nil and false or args.is_hidden

  self.role = args.role

  table.insert(lines, '') -- adiciona uma linha no final (margin)

  self.lines = lines
  self.start_line = args.start_line or 0
  self.end_line = self.start_line + #lines - 1

  if self.is_hidden then
    self.start_line = 0
    self.end_line = 0
  end
end

function Message:get_text() return table.concat(self.lines, '\n') end

---@return string[] | nil
function Message:extract_code_block()
  local text = self:get_text()

  local lastCodeBlock
  for codeBlock in text:gmatch('```.-```%s*') do
    lastCodeBlock = codeBlock
  end
  if lastCodeBlock == nil then return nil end

  lastCodeBlock = lastCodeBlock:gsub('```%w*\n', ''):gsub('```', ''):match('^%s*(.-)%s*$')

  return utils.split_into_lines(lastCodeBlock)
end

---@alias Message.constructor fun(options: MessageOptions): Message
---@type Message|Message.constructor
local _Message = Message

return _Message
