local class = require('mychatgpt.shared.class')
local U = require('mychatgpt.utils')
local Layout = require('nui.layout')
local Input = require('mychatgpt.shared.input')

local MessagesWidget = require('mychatgpt.chat.messages_widget')

---@class Ui
local Ui = class('Ui')

---@class UiOptions
---@field on_submit_input fun(lines: string[])
---@field on_exit? function faz algo quando a UI é fechada

---@param opts UiOptions
function Ui:initialize(opts)
  self.editor_win = vim.api.nvim_get_current_win() -- salva o win atual pra voltar depois
  self.on_exit = function()
    U.restore_keymap(self.prior_wincmd_keymap)

    if opts.on_exit then opts.on_exit() end
  end

  self.chat_window = MessagesWidget({
    title = ' Mochila de Criança ',
    maps = {
      { 'n', '<C-k>', function() self.input:focus() end,      { desc = 'Focus on Input' } },
      { 'n', '<C-j>', function() self:_focus_on_editor() end, { desc = 'Focus on Editor' } },
      { 'n', 'q',     function() self:unmount() end,          { desc = 'Quit chat' } },
      { 'i', '<C-c>', function() self:unmount() end,          { desc = 'Quit chat' } },
    },
  })

  self.input = Input({
    on_submit = opts.on_submit_input,
    on_number_of_lines_change = function() self:update_layout() end,
    height_limit = 5,
    maps = {
      { 'n', '<C-l>', function() self.chat_window:focus() end, { desc = 'Focus on Chat' } },
      { 'n', '<C-j>', function() self:_focus_on_editor() end,  { desc = 'Focus on Editor' } },
      { 'n', 'q',     function() self:unmount() end,           { desc = 'Quit chat' } },
      { 'i', '<C-c>', function() self:unmount() end,           { desc = 'Quit chat' } },
    },
  })

  self.layout = Layout(self:get_layout_params())
  self:_setup_autocommands()
  self:_override_default_wincmd()

  -- Antes de quitar de qualquer componente, da um unmount e retorna o foco pro editor
  local components = { self.chat_window, self.input }
  for _, component in ipairs(components) do
    ---@diagnostic disable-next-line: undefined-field
    component:on('QuitPre', function()
      self:unmount()
      self:_focus_on_editor()
    end)
  end
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
    self.chat_window:set_lines(-1, -1, { '' }) -- Começa uma nova linha.
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
  local box = Layout.Box({
    Layout.Box(self.chat_window, { grow = 1 }),
    Layout.Box(self.input, { size = { height = self.input:get_prompt_height() + 2 } }), -- +2 porque por algum motivo ele mostra -2 linhas
  }, { dir = 'col' })

  local config = {
    relative = 'editor',
    position = '100%',
    size = { width = '30%', height = '100%' },
  }

  return config, box
end

function Ui:update_layout() self.layout:update(self:get_layout_params()) end

function Ui:mount()
  self.layout:mount()
end

function Ui:unmount()
  self.layout:unmount()
  self.on_exit()
end

function Ui:_focus_on_editor() vim.api.nvim_set_current_win(self.editor_win) end

function Ui:_setup_autocommands()
  U.augroup('mychatgpt', {
    event = 'VimResized',
    command = function() self.layout:update() end,
  })
end

---Faz com que o outline seja a última janela da direita
function Ui:_override_default_wincmd()
  local wincmd_left = '<M-C-A>'
  self.prior_wincmd_keymap = U.get_keymap('n', wincmd_left)

  vim.keymap.set('n', wincmd_left, function()
    if U.is_leftmost_window() then
      return self.input:focus()
    end
    vim.cmd('wincmd l')
  end)
end

---@alias Ui.constructor fun(options: UiOptions): Ui
---@type Ui|Ui.constructor
local _Ui = Ui

return _Ui
