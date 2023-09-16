local class = require('mychatgpt.shared.class')
local Layout = require('nui.layout')
local defaults = require('mychatgpt.utils').defaults
local Input = require('mychatgpt.shared.input')
local Split = require('nui.split')

local MessagesWidget = require('mychatgpt.chat.messages_widget')

---@class Ui
local Ui = class('Ui')

---@class UiOptions
---@field on_submit_input fun(lines: string[])
---@field on_exit function faz algo quando a UI é fechada
---@field prompt_height? {min: number, max: number} (default {min = 5, max = 12})

---@param opts UiOptions
function Ui:initialize(opts)
  self.editor_win = vim.api.nvim_get_current_win()
  self.chat_window = MessagesWidget({
    title = ' Mochila de Criança ',
    maps = {
      { 'n', '<C-k>', function() self.input:focus() end,      { desc = 'Focus on Input' } },
      { 'n', '<C-j>', function() self:_focus_on_editor() end, { desc = 'Focus on Editor' } },
      { 'n', 'q',     ':q<CR>',                               { desc = 'Quit chat' } },
    },
  })

  self.prompt_lines = 1

  ---@type {min: number, max: number}
  self.prompt_height = defaults(opts.prompt_height, { min = 5, max = 12 })
  self.input = Input({
    on_submit = opts.on_submit_input,
    on_change = function(lines)
      -- local has_number_of_lines_changed = self.prompt_lines ~= #lines
      -- if has_number_of_lines_changed then
      --   self.prompt_lines = #lines -- update prompt_lines
      --   self:update_layout()
      -- end
    end,
    maps = {
      { 'n', '<C-l>', function() self.chat_window:focus() end, { desc = 'Focus on Chat' } },
      { 'n', '<C-j>', function() self:_focus_on_editor() end,  { desc = 'Focus on Editor' } },
    },
  })

  self.layout = Layout(self:get_layout_params())

  local components = { self.chat_window, self.input }
  for _, component in ipairs(components) do
    component:on('QuitPre', function()
      vim.schedule(function()
        self:unmount()
        if opts.on_exit then opts.on_exit() end
        --
        --   self:unmount()
        --   self:_focus_on_editor()
      end)
    end)
  end
end

function Ui:mount()
  -- self.fake_buffer = self:init_fake_buffer()
  self.layout:mount()
end

function Ui:unmount()
  -- self.fake_buffer:unmount()
  self.layout:unmount()
end

---Um hack para transformar a UI em um focusable buffer
---Isso é pq o Input e o Popup não tem como focar
function Ui:init_fake_buffer()
  local split = Split({ position = 'right', size = '1%' }) -- menor tamanho possível
  split:mount()

  -- Focou no buffer? -> Foca no input
  split:on('BufEnter', function() self.input:focus() end)

  return split
end

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
  local base_height = 2 + self.prompt_height.min -- esse 2 é o mínimo para o input (menos que 2 da erro)
  local lines_over_min_height = math.max(0, self.prompt_lines - self.prompt_height.min)

  local prompt_height = math.min(base_height + lines_over_min_height, self.prompt_height.max)

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

function Ui:_focus_on_editor() vim.api.nvim_set_current_win(self.editor_win) end

---@alias Ui.constructor fun(options: UiOptions): Ui
---@type Ui|Ui.constructor
local _Ui = Ui

return _Ui
