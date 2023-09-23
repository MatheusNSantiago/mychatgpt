---@diagnostic disable: need-check-nil
local Config = require('mychatgpt.config')
local curl = require('plenary.curl')
local utils = require('mychatgpt.utils')

local Api = {}

Api.CHAT_COMPLETIONS_URL = 'https://api.openai.com/v1/chat/completions'

---@class ChatCompletionsOptions
---@field chat_history {role: string, content: string}[]
---@field on_done fun(answer: string[])
---@field on_chunk? fun(delta: string[], state: string)

---@param opts ChatCompletionsOptions
function Api.chat_completions(opts)
  local payload = vim.tbl_extend('keep', {
    messages = opts.chat_history,
    stream = true,
  }, Config.openai_params)

  local raw_chunks = ''
  local state = 'NOP'

  Api._post({
    url = Api.CHAT_COMPLETIONS_URL,
    payload = payload,
    stream = {
      on_done = function()
        local answer = utils.split_into_lines(raw_chunks)
        opts.on_done(answer)
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

          if opts.on_chunk then
            delta = utils.split_into_lines(delta)

            if state == 'NOP' then
              state = 'START'
              return opts.on_chunk(delta, state)
            end

            state = 'CONTINUE'
            opts.on_chunk(delta, state)
          end
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
function Api._post(opts)
  local key = Api._get_api_key()

  curl.post(opts.url, {
    headers = { Authorization = 'Bearer ' .. key, Content_Type = 'application/json' },
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
end

function Api._get_api_key()
  local key = os.getenv('OPENAI_API_KEY')

  if key ~= nil and key ~= '' then key = key:gsub('%s+$', '') end

  return key
end

return Api
