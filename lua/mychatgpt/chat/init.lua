local classes = require('mychatgpt.shared.classes')
local Ui = require('mychatgpt.chat.ui')
local Message = require('mychatgpt.message')
local Api = require('mychatgpt.api')

local Chat = classes.class()

---@class ChatOpts
---@field on_exit? function
---@field maps? {mode: string, lhs: string, rhs: string, opts: table}[]

---@param opts ChatOpts
function Chat:init(opts)
  self.messages = {}
  self.on_exit = function() end
  self.Ui = Ui.new({
    on_submit_input = function(lines)
      self:add_message({ lines = lines })
      self:send_message()
    end,
    on_exit = opts.on_exit,
  })
end

---@class AddMessageArgs
---@field role? string (default 'user') 'user' | 'system' | 'assistant'
---@field lines string[]
---@field is_hidden? boolean (default false)

---@param args AddMessageArgs
function Chat:add_message(args)
  local start_line = self:_get_last_line_number() + 1
  local role = args.role or 'user'
  local lines = args.lines
  local is_hidden = args.is_hidden == nil and false or args.is_hidden

  local message = Message.new({
    lines = lines,
    role = role,
    start_line = start_line,
    is_hidden = is_hidden,
  })

  if not is_hidden then self.Ui:render_message(message) end

  table.insert(self.messages, message)
end

--- Envia as mensagens para o servidor e renderiza a resposta
--- como a API é stateless, é necessário enviar todas as mensagens
function Chat:send_message()
  Api.chat_completions(self.messages, function(answer, state)
    if state == 'END' then
      return self:add_message({
        lines = answer,
        role = 'assistant',
      })
    end

    -- Ainda não terminou de responder
    self.Ui:render_answer_delta(answer, state)
  end)
end

function Chat:set_prompt(lines)
  table.insert(lines, '')
  self.Ui.input:set_lines(lines)
  self.Ui.input:scroll_to_bottom()
end

function Chat:open() self.Ui:mount() end

---@return string | nil
function Chat:get_last_code_block()
  local code_block

  for _, message in ipairs(self.messages) do
    local code_block_or_nil = message:extract_code_block()
    if code_block_or_nil ~= nil then code_block = code_block_or_nil end
  end

  return code_block
end

function Chat:_get_last_line_number()
  local n_messages = #self.messages
  if n_messages > 0 then
    local prev = self.messages[n_messages]
    return prev.end_line
  end

  return 0
end

return Chat
