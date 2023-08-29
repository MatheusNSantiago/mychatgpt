---@diagnostic disable: need-check-nil
local Config = require('mychatgpt.config')
local curl = require('plenary.curl')
local utils = require('mychatgpt.utils')

-- local logger = require("mychatgpt.common.logger")

local Api = {}

-- API URL
-- Api.COMPLETIONS_URL = "https://api.openai.com/v1/completions"
Api.CHAT_COMPLETIONS_URL = 'https://api.openai.com/v1/chat/completions'
-- Api.EDITS_URL = "https://api.openai.com/v1/edits"

--[[ function Api.completions(custom_params, cb)
  local params = vim.tbl_extend("keep", custom_params, Config.openai_params)
  Api.make_call(Api.COMPLETIONS_URL, params, cb)
end ]]

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
    local answer_in_lines = utils.split_into_lines(raw_chunks)

    callback(answer_in_lines, 'END')
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
    body = vim.fn.json_encode(payload),
    stream = vim.schedule_wrap(function(_, data, _)
      local raw_message = string.gsub(data, '^data: ', '')
      local is_usefull_data = string.len(raw_message) > 6

      if raw_message == '[DONE]' then
        on_done()
      elseif is_usefull_data then
        on_delta(vim.fn.json_decode(raw_message))
      end
    end),
  })
end

--[[ function Api.edits(custom_params, cb)
  local params = vim.tbl_extend("keep", custom_params, Config.options.openai_edit_params)
  Api.make_call(Api.EDITS_URL, params, cb)
end ]]

--[[ function Api.make_call(url, params, cb)
  local TMP_MSG_FILENAME = Api._create_temporary_json_file(params)
  Api.job = job
      :new({
        command = 'curl',
        args = {
          url,
          '-H',
          'Content-Type: application/json',
          '-H',
          'Authorization: Bearer ' .. Api.OPENAI_API_KEY,
          '-d',
          '@' .. TMP_MSG_FILENAME,
        },
        on_exit = vim.schedule_wrap(function(response, exit_code)
          Api.handle_response(response, exit_code, cb)

          if TMP_MSG_FILENAME ~= nil then os.remove(TMP_MSG_FILENAME) end
        end),
      })
      :start()
end ]]

--[[ Api.handle_response = vim.schedule_wrap(function(response, exit_code, cb)
  if exit_code ~= 0 then
    vim.notify('An Error Occurred ...', vim.log.levels.ERROR)
    cb('ERROR: API Error')
  end

  local result = table.concat(response:result(), '\n')
  local json = vim.fn.json_decode(result)

if json == nil then
  cb('No Response.')
elseif json.error then
  cb('// API ERROR: ' .. json.error.message)
else
local message = json.choices[1].message
if message ~= nil then
  local response_text = json.choices[1].message.content
if type(response_text) == 'string' and response_text ~= '' then
cb(response_text, json.usage)
else
cb('...')
end
else
  local response_text = json.choices[1].text
  if type(response_text) == 'string' and response_text ~= '' then
    cb(response_text, json.usage)
  else
    cb('...')
  end
end
  end
end) ]]

--[[ function Api.close()
  if Api.job then job:shutdown() end
end ]]

--[[ local splitCommandIntoTable = function(command)
  local cmd = {}
  for word in command:gmatch("%S+") do
    table.insert(cmd, word)
  end
  return cmd
end ]]

--[[ function Api.exec(args, on_stdout_chunk, on_complete)
  local stdout = vim.loop.new_pipe()
  local stderr = vim.loop.new_pipe()
  local stderr_chunks = {}

  local handle, err
  handle, err = vim.loop.spawn('curl', {
    args = args,
    stdio = { nil, stdout, stderr },
  }, function(code)
    stdout:close()
    stderr:close()
    if handle ~= nil then handle:close() end

    vim.schedule(function()
      if code ~= 0 then on_complete(vim.trim(table.concat(stderr_chunks, ''))) end
    end)
  end)

  if not handle then
    on_complete('curl' .. ' could not be started: ' .. err)
  else
    stdout:read_start(function(_, chunk)
      if chunk then vim.schedule(function() on_stdout_chunk(chunk) end) end
    end)
    stderr:read_start(function(_, chunk)
      if chunk then table.insert(stderr_chunks, chunk) end
    end)
  end
end ]]

--[[ Api._create_temporary_json_file = function(content)
  local temporary_filename = os.tmpname() .. '.json'
  local f = io.open(temporary_filename, 'w+')
  if f == nil then
    vim.notify('Cannot open temporary message file: ' .. temporary_filename, vim.log.levels.ERROR)
    return
  end
  f:write(vim.fn.json_encode(content))
  f:close()

  return temporary_filename
end ]]

function Api._convert_messages_to_openai_format(messages)
  local chat_history = {}
  for _, message in ipairs(messages) do
    table.insert(chat_history, { role = message.role, content = message:get_text() })
  end

  local payload = vim.tbl_extend('keep', { messages = chat_history, stream = true }, Config.openai_params)
  return payload
end

return Api
