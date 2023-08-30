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
  self.prompt_lines = 1
  self.max_prompt_height = 12
  self.min_prompt_height = 5
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
    self.chat_window:set_lines(start_line - 1, -1, { '' }) -- apaga a mensagem parcial
  end

  -- mostra a mensagem pronta
  self.chat_window:set_lines(start_line, end_line, lines)

  -- highlight lines
  if hl_group then
    for line_num = start_line, end_line do
      self:_add_highlight(hl_group, line_num, 0, -1)
    end
  end
end

---@param delta string[]
function ChatRenderer:render_answer_delta(delta, state)
  if state == "START" then
  -- Começa uma nova linha.
  self.chat_window:set_lines(-1, -1, { '' })
  end


  for i, line in ipairs(delta) do
    local last_line = self.chat_window:get_lines(-2, -1)[1]
    local line_count = self.chat_window:line_count()
    local last_line_idx = line_count - 1

    self.chat_window:set_lines(last_line_idx, -1, { last_line .. line })

    local should_add_blank_line = i > 1
    if should_add_blank_line then self.chat_window:set_lines(-1, -1, { '' }) end

    self.chat_window:scroll_to_end()
  end
end

function ChatRenderer:get_layout_params()
  local base_height = 2 + self.min_prompt_height -- esse 2 é o mínimo para o input (menos que 2 da erro)
  local lines_over_min_height = math.max(0, self.prompt_lines - self.min_prompt_height)

  local prompt_height = math.min(base_height + lines_over_min_height, self.max_prompt_height)

  local box = Layout.Box({
    Layout.Box(self.chat_window, { grow = 1 }),
    Layout.Box(self.input, { size = { height = prompt_height } }),
  }, { dir = 'col' })

  local config = {
    relative = 'editor',
    position = '100%',
    size = { width = '30%', height = '100%' },
  }

  return config, box
end

function ChatRenderer:update_layout() self.layout:update(self:get_layout_params()) end

function ChatRenderer:_add_highlight(hl_group, line, col_start, col_end)
  vim.api.nvim_buf_add_highlight(self.chat_window.bufnr, -1, hl_group, line, col_start, col_end)
end

return ChatRenderer
