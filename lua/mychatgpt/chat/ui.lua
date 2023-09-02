local classes = require('mychatgpt.shared.classes')
local Layout = require('nui.layout')
local Input = require('mychatgpt.chat.components.input')
local MessagesWidget = require('mychatgpt.chat.components.messages_widget')

local Ui = classes.class()

---@class UiOptions
---@field on_submit_input fun(lines: string[])
---@field on_exit function

---@param opts UiOptions
function Ui:init(opts)
  self.chat_window = MessagesWidget({
    title = ' Mochila de Criança ',
    maps = {
      { 'n', '<C-k>', function() self.input:focus() end, { desc = 'Focus on Input' } },
      { 'n', 'q',     ':q<CR>',                          { desc = 'Quit chat' } },
    },
  })

  self.prompt_lines = 1
  self.max_prompt_height = 12
  self.min_prompt_height = 5

  self.input = Input({
    on_submit = opts.on_submit_input,
    on_change = vim.schedule_wrap(function(lines)
      local has_number_of_lines_changed = self.prompt_lines ~= #lines
      if has_number_of_lines_changed then
        self.prompt_lines = #lines -- update prompt_lines
        self:update_layout()
      end
    end),
    maps = {
      { 'n', '<C-l>', function() self.chat_window:focus() end, { desc = 'Focus on Chat' } },
    },
  })

  self.layout = Layout(self:get_layout_params())

  self.components = { self.chat_window, self.input }
  for _, component in ipairs(self.components) do
    component:on('QuitPre', function()
      vim.schedule(function()
        if opts.on_exit then opts.on_exit() end
        self.layout:unmount()
      end)
    end)
  end
end

function Ui:mount() self.layout:mount() end

function Ui:render_message(message)
  local start_line = message.start_line
  local end_line = message.end_line
  local lines = message.lines

  if message.role == 'assistant' then
    self.chat_window:set_lines(start_line - 1, -1, { '' }) -- apaga a mensagem parcial
  else
    self.chat_window:set_sign('mychatgpt_question_sign', start_line)
  end

  -- mostra a mensagem pronta
  self.chat_window:set_lines(start_line, end_line, lines)
end

---@param delta string[]
function Ui:render_answer_delta(delta, state)
  if state == 'START' then
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

function Ui:get_layout_params()
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

function Ui:update_layout() self.layout:update(self:get_layout_params()) end

return Ui