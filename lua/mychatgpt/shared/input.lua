---@diagnostic disable: undefined-field
--[[ local NuiInput = require('nui.input')
local popup_options = require('mychatgpt.config').popup_input
local utils = require('mychatgpt.utils')
local classes = require('mychatgpt.shared.classes')

---@class Input
local Input = classes.class()

---@class OptionsArgs
---@field prompt? string (default: '')
---@field label? string (default: '')
---@field on_submit fun(lines: string[])
---@field close_after_submit? boolean (default: false)
---@field on_close? fun()
---@field on_change? fun(lines: string[])
---@field maps? {mode: string, lhs: string, rhs: string, opts: table}[]
---@field layout? { relative: string, position: { row: number, col: number }, size: number | table }


---@param options OptionsArgs
-- function Input:init()
--
-- end
-- local Input = NuiInput(
--   vim.tbl_extend('force', {
--     enter = true,
--     border = {
--       highlight = 'FloatBorder',
--       style = 'rounded',
--       text = { top_align = 'center', top = options.label or '' },
--       padding = { left = 1 },
--     },
--     win_options = { winhighlight = 'Normal:Normal,FloatBorder:FloatBorder' },
--     buf_options = { filetype = 'markdown' },
--   }, options.layout or {}),
--   {
--     on_close = options.on_close,
--     on_submit = function(value) options.on_submit(utils.split_into_lines(value)) end,
--     on_change = function(value) options.on_change(utils.split_into_lines(value)) end,
--     prompt = options.prompt or '',
--     default_value = '',
--     patch_cursor_position = true,
--   }
-- )

function Input:set_lines(lines) vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, lines) end

function Input:scroll_to_bottom()
  local line_count = vim.api.nvim_buf_line_count(self.bufnr)
  local win = self.winid
  vim.api.nvim_win_set_cursor(win, { line_count, 0 })
end

function Input:clear() self:set_lines({ '' }) end

-- TODO: descomenta isso
function Input:focus()
  -- vim.api.nvim_set_current_win(self.winid)
end

function Input:get_lines() return vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, false) end

-- function Input:mount()
--   NuiInput.mount(self)
--   vim.cmd('startinsert!')
-- end

if options.close_after_submit then Input:on({ 'BufLeave' }, function() Input:unmount() end) end

local after_submit = function()
  Input:clear()
  if options.close_after_submit then Input:unmount() end
end

Input:on('QuitPre', function() Input:unmount() end)
-- set keymaps
Input:map('i', popup_options.submit, function()
  local lines = Input:get_lines()
  options.on_submit(lines)
  after_submit()
end, { noremap = true })

Input:map('n', popup_options.submit_n, function()
  local lines = Input:get_lines()
  options.on_submit(lines)
  after_submit()
end, { noremap = true })

Input:map('n', 'q', function() Input:unmount() end, { desc = 'Quit chat' })
Input:map('i', '<C-c>', function() Input:unmount() end, { desc = 'Quit chat' })

if options.maps then
  for _, map in ipairs(options.maps) do
    Input:map(map[1], map[2], map[3], map[4])
  end
end

return Input ]]

local NuiInput = require('nui.input')
local popup_options = require('mychatgpt.config').popup_input
local utils = require('mychatgpt.utils')
local defaults = utils.defaults

---@class Input
local Input = NuiInput:extend('NuiInput')

---@class InputOptions
---@field prompt? string (default: '')
---@field label? string (default: '')
---@field on_submit fun(lines: string[])
---@field on_close? fun()
---@field on_change? fun(lines: string[])
---@field close_after_submit? boolean (default: false)
---@field close_on_unfocus? boolean (default: false)
---@field maps? {mode: string, lhs: string, rhs: string, opts: table}[]
---@field layout? { relative: string, position: { row: number, col: number }, size: number | table }

---@param options InputOptions
function Input:init(options)
  self.prompt = defaults(options.prompt, '')
  self.label = defaults(options.label, '')
  self.on_submit = options.on_submit
  self.on_close = defaults(options.on_close, function() end)
  self.on_change = defaults(options.on_change, function() end)
  self.close_after_submit = defaults(options.close_after_submit, false)
  self.close_on_unfocus = defaults(options.close_on_unfocus, false)
  self.maps = defaults(options.maps, {})
  self.layout = defaults(options.layout, {})

  local input_options = vim.tbl_extend('force', {
    enter = true,
    border = {
      highlight = 'FloatBorder',
      style = 'rounded',
      text = { top_align = 'center', top = self.label },
      padding = { left = 1 },
    },
    win_options = { winhighlight = 'Normal:Normal,FloatBorder:FloatBorder' },
    buf_options = { filetype = 'markdown' },
  }, self.layout)

  Input.super.init(self, input_options, {
    on_close = self.on_close,
    on_submit = function(value) self.on_submit(utils.split_into_lines(value)) end,
    on_change = function(value) self.on_change(utils.split_into_lines(value)) end,
    prompt = self.prompt,
  })

  if self.close_on_unfocus then
    self:on({ 'BufLeave' }, function() self:unmount() end) --
  end

  self:setup_keymaps()
end

function Input:mount() Input.super.mount(self) end

function Input:on(event, callback, opts) Input.super.on(self, event, callback, opts) end

function Input:set_lines(lines) vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, lines) end

function Input:scroll_to_bottom()
  local line_count = vim.api.nvim_buf_line_count(self.bufnr)
  local win = self.winid
  vim.api.nvim_win_set_cursor(win, { line_count, 0 })
end

function Input:clear() self:set_lines({ '' }) end

function Input:focus() vim.api.nvim_set_current_win(self.winid) end

function Input:get_lines() return vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, false) end

function Input:setup_keymaps()
  local after_submit_hook = function()
    self:clear()
    if self.close_after_submit then self:unmount() end
  end

  -- self:on('QuitPre', function() self:unmount() end)
  self:map('i', popup_options.submit, function()
    local lines = self:get_lines()
    self.on_submit(lines)
    after_submit_hook()
  end, { noremap = true })

  self:map('n', popup_options.submit_n, function()
    local lines = self:get_lines()
    self.on_submit(lines)
    after_submit_hook()
  end, { noremap = true })

  self:map('n', 'q', function() self:unmount() end, { desc = 'Quit chat' })
  self:map('i', '<C-c>', function() self:unmount() end, { desc = 'Quit chat' })

  -- set aditional user defined keymaps
  for _, map in ipairs(self.maps) do
    self:map(map[1], map[2], map[3], map[4])
  end
end

---@alias Input.constructor fun(options: InputOptions): Input
---@type Input|Input.constructor
local _Input = Input
return _Input

--  ╾───────────────────────────────────────────────────────────────────────────────────╼

-- local Popup = require('nui.popup')
-- local Text = require('nui.text')
-- local defaults = require('nui.utils').defaults
-- local event = require('nui.utils.autocmd').event
-- local popup_options = require('mychatgpt.config').popup_input
--
-- -- exiting insert mode places cursor one character backward,
-- -- so patch the cursor position to one character forward
-- -- when unmounting input.
-- ---@param target_cursor number[]
-- ---@param force? boolean
-- local function patch_cursor_position(target_cursor, force)
--   local cursor = vim.api.nvim_win_get_cursor(0)
--
--   if target_cursor[2] == cursor[2] and force then
--     -- didn't exit insert mode yet, but it's gonna
--     vim.api.nvim_win_set_cursor(0, { cursor[1], cursor[2] + 1 })
--   elseif target_cursor[2] - 1 == cursor[2] then
--     -- already exited insert mode
--     vim.api.nvim_win_set_cursor(0, { cursor[1], cursor[2] + 1 })
--   end
-- end
--
-- local Input = Popup:extend('NuiInput')
--
-- ---@class OptionsArgs
-- ---@field efault_value string
-- ---@field prompt string
-- ---@field label? string
-- ---@field maps? {mode: string, lhs: string, rhs: string, opts: table}[]
-- ---@field layout? { relative: string, position: { row: number, col: number }, size: number }
-- ---@field disable_cursor_position_patch boolean
-- ---@field on_submit fun(value: string)
-- ---@field on_close fun()
-- ---@field on_change fun(lines: string[])
--
-- ---@param options OptionsArgs
-- function Input:init(options)
--   vim.fn.sign_define('multiprompt_sign', { text = ' ', texthl = 'LineNr', numhl = 'LineNr' })
--   vim.fn.sign_define('singleprompt_sign', { text = ' ', texthl = 'LineNr', numhl = 'LineNr' })
--
--   local default_options = {
--     enter = true,
--     border = {
--       highlight = 'FloatBorder',
--       style = 'rounded',
--       text = { top_align = 'center', top = options.label or '' },
--     },
--     win_options = {
--       winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
--     },
--   }
--
--   Input.super.init(self, vim.tbl_extend('keep', default_options, options.layout or {}))
--
--   self.maps = options.maps
--   self._.default_value = defaults(options.default_value, '')
--   self._.prompt = Text(defaults(options.prompt, ''))
--   self._.disable_cursor_position_patch = defaults(options.disable_cursor_position_patch, false)
--
--
--   local props = {}
--
--   self.input_props = props
--
--   props.on_submit = function(value)
--     local target_cursor = vim.api.nvim_win_get_cursor(self._.position.win)
--
--     local prompt_normal_mode = vim.fn.mode() == 'n'
--
--     vim.schedule(function()
--       if prompt_normal_mode then
--         -- NOTE: on prompt-buffer normal mode <CR> causes neovim to enter insert mode.
--         --  ref: https://github.com/neovim/neovim/blob/d8f5f4d09078/src/nvim/normal.c#L5327-L5333
--         vim.api.nvim_command('stopinsert')
--       end
--
--       if not self._.disable_cursor_position_patch then patch_cursor_position(target_cursor, prompt_normal_mode) end
--
--       if options.on_submit then
--         self:clear()
--         options.on_submit(value)
--       end
--     end)
--   end
--
--   props.on_close = function()
--     local target_cursor = vim.api.nvim_win_get_cursor(self._.position.win)
--
--     self:unmount()
--
--     vim.schedule(function()
--       if vim.fn.mode() == 'i' then vim.api.nvim_command('stopinsert') end
--
--       if not self._.disable_cursor_position_patch then patch_cursor_position(target_cursor) end
--
--       if options.on_close then options.on_close() end
--     end)
--   end
--
--   if options.on_change then
--     props.on_change = function()
--       local lines = self:get_lines()
--
--       if #lines == 1 then
--         vim.fn.sign_place(0, 'my_group', 'singleprompt_sign', self.bufnr, { lnum = 1, priority = 10 })
--       else
--         for i = 1, #lines do
--           vim.fn.sign_place(0, 'my_group', 'multiprompt_sign', self.bufnr, { lnum = i, priority = 10 })
--         end
--       end
--       options.on_change(lines)
--     end
--   end
-- end
--
-- function Input:set_lines(lines) vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, lines) end
--
-- function Input:scroll_to_bottom()
--   local line_count = vim.api.nvim_buf_line_count(self.bufnr)
--   local win = self.winid
--   vim.api.nvim_win_set_cursor(win, { line_count, 0 })
-- end
--
-- function Input:clear() self:set_lines({ '' }) end
--
-- function Input:focus()
--   local win = self.winid
--   vim.api.nvim_set_current_win(win)
-- end
--
-- function Input:mount()
--   local props = self.input_props
--
--   Input.super.mount(self)
--   vim.api.nvim_buf_set_option(self.bufnr, 'filetype', 'markdown')
--
--   if props.on_change then
--     vim.api.nvim_buf_attach(self.bufnr, false, {
--       on_lines = props.on_change,
--     })
--   end
--
--   if #self._.default_value then
--     self:on(event.InsertEnter, function() vim.api.nvim_feedkeys(self._.default_value, 'n', false) end, { once = true })
--   end
--
--   self:setup_keymaps(props)
--
--   vim.api.nvim_command('startinsert!')
--   vim.fn.sign_place(0, 'my_group', 'singleprompt_sign', self.bufnr, { lnum = 1, priority = 10 })
-- end
--
-- function Input:get_lines() return vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, false) end
--
-- function Input:setup_keymaps(props)
--   self:map('i', popup_options.submit, function()
--     local lines = self:get_lines()
--     props.on_submit(lines)
--   end, { noremap = true })
--
--   self:map('n', popup_options.submit_n, function()
--     local lines = self:get_lines()
--     props.on_submit(lines)
--   end, { noremap = true })
--
--   self:map('n', 'q', ':q<CR>', { desc = 'Quit chat' })
--   self:map('i', '<C-c>', '<ESC><CMD>q<CR>', { desc = 'Quit chat' })
--
--   local maps = self.maps
--   if maps then
--     for _, map in ipairs(maps) do
--       self:map(map[1], map[2], map[3], map[4])
--     end
--   end
-- end
--
-- return Input
