local create_picker = require('mychatgpt.actions.picker')

create_picker('<Leader><Leader>o', 'ChatGPT', {
  { name = 'Chat', handler = '' },
  { name = 'Documentar', handler = '' },
  { name = 'Explicar', handler = '' },
  { name = 'Ver se o código ta legível e se tem que trocar algo', handler = '' },
})

vim.keymap.set('x', 'v', function()
  vim.cmd('wa')
  vim.cmd('source plugin/mychatgpt.lua')
  for k in pairs(package.loaded) do
    if k:match('^mychatgpt') then package.loaded[k] = nil end
  end

  require('mychatgpt').send_selection_to_chat()
end)
vim.keymap.set('n', '<leader>v', function()

  vim.cmd('wa')
  vim.cmd('source plugin/mychatgpt.lua')
  for k in pairs(package.loaded) do
    if k:match('^mychatgpt') then package.loaded[k] = nil end
  end

  require('mychatgpt').open_chat()
end)
