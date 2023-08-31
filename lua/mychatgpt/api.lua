---@diagnostic disable: need-check-nil
local Config = require('mychatgpt.config')
local curl = require('plenary.curl')
local utils = require('mychatgpt.utils')

local Api = {}

-- API URL
-- Api.COMPLETIONS_URL = "https://api.openai.com/v1/completions"
Api.CHAT_COMPLETIONS_URL = 'https://api.openai.com/v1/chat/completions'
-- Api.EDITS_URL = 'https://api.openai.com/v1/edits'

function Api.get_api_key()
  local key = os.getenv('OPENAI_API_KEY')

  if key ~= nil and key ~= '' then key = key:gsub('%s+$', '') end

  return key
end

function Api.chat_completions(messages, callback)
  local payload = Api.make_payload({ messages = messages, is_stream = true })

  local raw_chunks = ''
  local state = 'NOP'

  Api.post({
    url = Api.CHAT_COMPLETIONS_URL,
    payload = payload,
    stream = {
      on_done = function()
        local final_answer = utils.split_into_lines(raw_chunks)
        callback(final_answer, 'END')
      end,
      on_chunk = function(chunk)
        local response_ok = chunk
            and chunk.choices
            and chunk.choices[1]
            and chunk.choices[1].delta
            and chunk.choices[1].delta.content

        if response_ok then
          local delta = chunk.choices[1].delta.content

          raw_chunks = raw_chunks .. delta
          delta = utils.split_into_lines(delta)

          if state == 'NOP' then
            state = 'START'
            return callback(delta, state)
          end

          state = 'CONTINUE'
          callback(delta, state)
        end
      end,
    },
  })
end

---@class PostOptions
---@field url string
---@field payload table
---@field stream? {on_chunk: function, on_done: function}

---@param opts PostOptions
function Api.post(opts)
  local key = Api.get_api_key()

  local res = curl.post(opts.url, {
    headers = {
      Authorization = 'Bearer ' .. key,
      Content_Type = 'application/json',
    },
    raw = { '--silent', '--show-error', '--no-buffer' },
    body = vim.fn.json_encode(opts.payload),
    stream = function(_, data, _)
      vim.schedule(function()
        local raw_message = string.gsub(data, '^data: ', '')
        local is_usefull_data = string.len(raw_message) > 0

        if raw_message == '[DONE]' then
          return opts.stream.on_done()
        elseif is_usefull_data then
          local json_response = vim.fn.json_decode(raw_message)
          opts.stream.on_chunk(json_response)
        end
      end)
    end,
  })

  if opts.stream == nil then
    local json_response = vim.fn.json_decode(res.body)
    return json_response
  end
end

function Api.make_payload(opts)
  local chat_history = {}
  for _, message in ipairs(opts.messages) do
    table.insert(chat_history, { role = message.role, content = message:get_text() })
  end

  local payload = vim.tbl_extend('keep', { messages = chat_history, stream = opts.is_stream }, Config.openai_params)
  return payload
end

return Api
