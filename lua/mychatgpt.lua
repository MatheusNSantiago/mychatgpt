local Chat = require('mychatgpt.chat')

local M = {
  chat = nil,
  selection = nil,
}

function M.setup()
  vim.api.nvim_set_hl(0, 'MyChatGPT_Question', { fg = '#b4befe', italic = true, bold = false, default = true })
  vim.cmd('sign define mychatgpt_question_sign text=' .. '' .. ' texthl=MyCHATGPT_Question')

  vim.cmd([[sign define mychatgpt_action_block text=│ texthl=ErrorMsg]])
end

---@param params? { on_exit: function }
function M.open_new_chat(params)
  params = params or {}
  M.chat = Chat({ on_exit = params.on_exit })
  M.chat:open()
end

---@param messages Message[]
function M.send_messages(messages)
  for _, message in ipairs(messages) do
    M.chat:add_message(message)
  end
  M.chat:send()
end

function M.teste()
  -- 1) pegar seleção
  -- local selection = require('mychatgpt.selection').get_selection()
  local Input = require('mychatgpt.shared.input')
  local input = Input({
    label = 'ola',
    layout = {
      relative = 'cursor',
      position = { row = 2, col = 0 },
      size = { width = 20, height = 2 },
    },
    on_submit = function(value)
      vim.print(value)
      -- 2) mandar texto + input value
      -- local final_text = {}
      --
      -- vim.list_extend(final_text, selection.lines)
      -- vim.list_extend(final_text, { '---' })
      -- vim.list_extend(final_text, value)
      --
      -- M.open_new_chat()
      -- M.chat:add_message({ lines = final_text, is_hidden = true })
      -- M.chat:send()
    end,
    close_after_submit = true,
  })
  input:mount()
end

function M.replace_selection_with_last_code_block()
  local code_block = M.chat:get_last_code_block()

  if code_block and M.selection then M.selection:replace(code_block) end
end

function M.set_current_selection(selection) M.selection = selection end

return M
