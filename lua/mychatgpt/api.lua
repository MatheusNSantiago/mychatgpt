---@diagnostic disable: need-check-nil
local Config = require('mychatgpt.config')
local curl = require('plenary.curl')
local utils = require('mychatgpt.utils')

local Api = {}

-- API URL
-- Api.COMPLETIONS_URL = "https://api.openai.com/v1/completions"
Api.CHAT_COMPLETIONS_URL = 'https://api.openai.com/v1/chat/completions'
-- Api.EDITS_URL = "https://api.openai.com/v1/edits"

function Api.setup()
  Api.OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')

  if Api.OPENAI_API_KEY ~= nil and Api.OPENAI_API_KEY ~= '' then
    Api.OPENAI_API_KEY = Api.OPENAI_API_KEY:gsub('%s+$', '')
  end
end

function Api.chat_completions(messages, callback)
  Api.setup()

  local payload = Api._convert_messages_to_openai_format(messages)

  local raw_chunks = ''
  local state = 'START'

  local on_done = function()
    local final_answer = utils.split_into_lines(raw_chunks)

    callback(final_answer, 'END')
  end

  local on_delta = function(response)
    local response_ok = response
        and response.choices
        and response.choices[1]
        and response.choices[1].delta
        and response.choices[1].delta.content

    if response_ok then
      local delta = response.choices[1].delta.content

      raw_chunks = raw_chunks .. delta
      state = 'CONTINUE'

      delta = utils.split_into_lines(delta)
      callback(delta, state)
    end
  end

  curl.post(Api.CHAT_COMPLETIONS_URL, {
    headers = {
      Authorization = 'Bearer ' .. Api.OPENAI_API_KEY,
      Content_Type = 'application/json',
    },
    raw = { '--silent', '--show-error', '--no-buffer' },
    body = vim.fn.json_encode(payload),
    stream = function(_, data, _)
      vim.schedule(function()
        local raw_message = string.gsub(data, '^data: ', '')
        local is_usefull_data = string.len(raw_message) > 0

        if raw_message == '[DONE]' then
          return on_done()
        elseif is_usefull_data then
          local json_response = vim.fn.json_decode(raw_message)
          on_delta(json_response)
        end
      end)
    end,
  })
end

function Api._convert_messages_to_openai_format(messages)
  local chat_history = {}
  for _, message in ipairs(messages) do
    table.insert(chat_history, { role = message.role, content = message:get_text() })
  end

  local payload = vim.tbl_extend('keep', { messages = chat_history, stream = true }, Config.openai_params)
  return payload
end

return Api
