local actions = require('mychatgpt.actions')
local utils = require('mychatgpt.utils')
local create_picker = require('mychatgpt.actions.picker')

local function reload()
  vim.cmd('wa')
  vim.cmd('source plugin/mychatgpt.lua')
  for k in pairs(package.loaded) do
    if k:match('^mychatgpt') then package.loaded[k] = nil end
  end
end

vim.keymap.set('x', 'v', function()
  reload()
  require('mychatgpt').teste()
end)

vim.keymap.set('n', '<leader>v', function()
  reload()
  require('mychatgpt').open_chat()
end)

create_picker({
  keymap = '<leader><leader>o',
  title = 'MyChatGPT',
  options = vim.tbl_keys(actions.prompts),
  callback = function(action)
    reload()
    actions.execute_action(action, function(prompt) require('mychatgpt').send_hidden_prompt(prompt) end)
  end,
})
