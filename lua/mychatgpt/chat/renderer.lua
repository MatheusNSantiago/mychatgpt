local classes = require('mychatgpt.shared.classes')
local Layout = require('nui.layout')
local Input = require('mychatgpt.chat.components.input')
local messages_widget = require('mychatgpt.chat.components.messages_widget')

local ChatRenderer = classes.class()

---@class ChatRendererArgs
---@field on_submit fun(lines: string[])

---@param args ChatRendererArgs
function ChatRenderer:init(args)
  self.chat_window = messages_widget
  vim.api.nvim_buf_set_option(self.chat_window.bufnr, 'filetype', 'markdown')

  self.prompt_lines = 1
  self.max_prompt_height = 12
  self.input = Input({
    on_submit = args.on_submit,
    on_change = vim.schedule_wrap(function(lines)
      local has_number_of_lines_changed = self.prompt_lines ~= #lines
      if has_number_of_lines_changed then
        self.prompt_lines = #lines -- update prompt_lines
        self:update_layout()
      end
    end),
  })
  self.layout = Layout(self:get_layout_params())
  self.layout:mount()
end

function ChatRenderer:render_message(message)
  local start_line = message.start_line
  local end_line = message.end_line
  local lines = message.lines
  local hl_group = message.opts.hl_group

  if message.role == 'assistant' then
    self:_set_lines(start_line - 1, -1, { '' }) -- apaga a mensagem parcial
  end

  -- mostra a mensagem pronta
  self:_set_lines(start_line, end_line, lines)

  -- highlight lines
  if hl_group then
    for line_num = start_line, end_line do
      self:_add_highlight(hl_group, line_num, 0, -1)
    end
  end
end

---@param delta string[]
function ChatRenderer:render_answer_delta(delta)
  local buffer = self.chat_window.bufnr
  local win = self.chat_window.winid

  for _, line in ipairs(delta) do
    local last_line = vim.api.nvim_buf_get_lines(buffer, -2, -1, false)[1]
    local line_count = vim.api.nvim_buf_line_count(buffer)
    local last_line_idx = line_count - 1

    self:_set_lines(last_line_idx, -1, { last_line .. line })

    vim.api.nvim_win_set_cursor(win, { line_count, 0 }) -- scroll pra baixo
  end
end

function ChatRenderer:get_layout_params()
  local prompt_height = math.min(2 + self.prompt_lines, self.max_prompt_height)

  local box = Layout.Box({
    Layout.Box(self.chat_window, { grow = 1 }),
    Layout.Box(self.input, { size = { height = prompt_height } }),
  }, { dir = 'col' })

  local config = {
    relative = 'editor',
    position = '50%',
    size = { width = '60%', height = '60%' },
  }

  return config, box
end

function ChatRenderer:update_layout() self.layout:update(self:get_layout_params()) end

function ChatRenderer:_set_lines(start_idx, end_idx, lines)
  -- vim.api.nvim_buf_set_option(self.chat_window.bufnr, 'modifiable', true)
  vim.api.nvim_buf_set_lines(self.chat_window.bufnr, start_idx, end_idx, false, lines)
  -- vim.api.nvim_buf_set_option(self.chat_window.bufnr, 'modifiable', false)
end

function ChatRenderer:_add_highlight(hl_group, line, col_start, col_end)
  vim.api.nvim_buf_add_highlight(self.chat_window.bufnr, -1, hl_group, line, col_start, col_end)
end

return ChatRenderer
