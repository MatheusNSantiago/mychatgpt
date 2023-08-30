local classes = require('mychatgpt.shared.classes')
local ChatRenderer = require('mychatgpt.chat.renderer')
local Message = require('mychatgpt.message')
local Api = require('mychatgpt.api')

local Chat = classes.class()

function Chat:init()
  self.messages = {}
  self.renderer = ChatRenderer.new({
    on_submit = function(lines)
      self:add_message({ lines = lines })
      self:send_message()
    end,
  })
end

---@class AddMessageArgs
---@field role? string (default 'user') 'user' | 'system' | 'assistant'
---@field lines string[]
---@field opts? MessageOptions

---@param args AddMessageArgs
function Chat:add_message(args)
  local start_line = self:_get_last_line_number() + 1
  local role = args.role or 'user'
  local lines = args.lines

  local message = Message.new(role, lines, start_line, args.opts)
  self.renderer:render_message(message)

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
    self.renderer:render_answer_delta(answer, state)
  end)
end

function Chat:set_prompt(lines)
  table.insert(lines, '')
  self.renderer.input:set_lines(lines)
  self.renderer.input:scroll_to_bottom()
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
