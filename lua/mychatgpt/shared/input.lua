---@diagnostic disable: undefined-field
local Popup = require('nui.popup')
local defaults = require('nui.utils').defaults

---@class Input
local Input = Popup:extend('NuiInput')

---@class InputOptions
---@field prompt? string (default: '')
---@field label? string (default: '')
---@field on_submit fun(lines: string[])
---@field on_close? fun()
---@field on_change? fun(lines: string[])
---@field on_number_of_lines_change? function
---@field close_on_unfocus? boolean (default: false)
---@field maps? {mode: string, lhs: string, rhs: string, opts: table}[]
---@field relative? string (default: 'editor')
---@field position? { row: number, col: number }
---@field height_limit {min: number, max: number} | number
---@field close_after_submit? boolean (default: false)
---@field width_limit? {min: number, max: number} | number (default: 25)

---@param opts InputOptions
function Input:init(opts)
  self.prompt = defaults(opts.prompt, '')
  self.label = defaults(opts.label, '')
  self.on_submit = opts.on_submit
  self.on_close = defaults(opts.on_close, function() end)
  self.on_change = defaults(opts.on_change, function() end)
  self.on_number_of_lines_change = defaults(opts.on_number_of_lines_change, function() end)
  self.close_after_submit = defaults(opts.close_after_submit, false)
  self.maps = defaults(opts.maps, {})
  self.relative = defaults(opts.relative, 'editor')
  self.position = opts.position
  self.close_on_unfocus = defaults(opts.close_on_unfocus, false)

  self.height_limit = type(opts.height_limit) == 'number' and { min = opts.height_limit, max = opts.height_limit }
      or opts.height_limit
  self.width_limit = type(opts.width_limit) == 'number' and { min = opts.width_limit, max = opts.width_limit }
      or opts.width_limit
      or { min = 25, max = 25 } -- default width

  local input_options = {
    enter = true,
    border = {
      highlight = 'FloatBorder',
      style = 'rounded',
      text = { top_align = 'center', top = self.label },
      padding = { left = 1 },
    },
    win_options = { winhighlight = 'Normal:Normal,FloatBorder:FloatBorder' },
    buf_options = { filetype = 'markdown' },
    relative = self.relative,
    position = self.position,
    size = { width = self.width_limit.min, height = self.height_limit.min },
  }

  Input.super.init(self, input_options)

  if self.close_on_unfocus then
    self:on({ 'BufLeave' }, function()
      vim.schedule(function() self:unmount() end)
    end)
  end

  self:_setup_keymaps()

  self.prompt = {}
  self.cursor_before = vim.api.nvim_win_get_cursor(0)
end

function Input:mount()
  Input.super.mount(self)

  vim.api.nvim_buf_attach(self.bufnr, false, {
    on_lines = function()
      local lines = self:get_lines()
      self.on_change(lines)

      local prompt_height_before = self:get_prompt_height()
      local prompt_height_after = self:get_prompt_height(lines)

      local has_number_of_lines_changed = prompt_height_before ~= prompt_height_after
      if has_number_of_lines_changed then vim.schedule(self.on_number_of_lines_change) end

      self.prompt = lines
    end,
  })

  vim.schedule(function() vim.cmd('startinsert!') end)
end

function Input:set_lines(lines) vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, lines) end

function Input:scroll_to_bottom()
  local line_count = vim.api.nvim_buf_line_count(self.bufnr)
  vim.api.nvim_win_set_cursor(self.winid, { line_count, 0 })
end

function Input:clear() self:set_lines({ '' }) end

function Input:focus() vim.api.nvim_set_current_win(self.winid) end

function Input:get_lines() return vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, false) end

---@param prompt? string[] (default: self.lines)
function Input:get_prompt_height(prompt)
  prompt = prompt or self.prompt

  local wrap_height = 0
  for _, line in ipairs(prompt) do
    local line_width = vim.fn.strdisplaywidth(line)
    local can_wrap = line_width >= self.width_limit.max
    if can_wrap then
      local num_of_wraps = math.floor(line_width / self.width_limit.max)
      wrap_height = wrap_height + num_of_wraps
    end
  end
  local text_height = wrap_height + #prompt
  local lines_over_min_height = math.max(0, text_height - self.height_limit.min)

  local prompt_height = math.min(self.height_limit.min + lines_over_min_height, self.height_limit.max)
  return prompt_height
end

function Input:update_size()
  local row, col = unpack(self.cursor_before)

  self:update_layout({
    relative = {
      type = 'buf',
      position = { row = row - 1, col = col },
    },
    anchor = 'NW',
    size = { width = self.width_limit.min, height = self:get_prompt_height() },
  })
end

function Input:_setup_keymaps()
  local after_submit_hook = function()
    self:clear()
    if self.close_after_submit then self:unmount() end
  end

  self:map('i', '<Enter>', function()
    local lines = self:get_lines()
    self.on_submit(lines)
    after_submit_hook()
  end, { noremap = true })

  self:map('n', '<Enter>', function()
    local lines = self:get_lines()
    self.on_submit(lines)
    after_submit_hook()
  end, { noremap = true })

  -- set aditional user defined keymaps
  for _, map in ipairs(self.maps) do
    self:map(map[1], map[2], map[3], map[4])
  end
end

---@alias Input.constructor fun(options: InputOptions): Input
---@type Input|Input.constructor
local _Input = Input
return _Input
