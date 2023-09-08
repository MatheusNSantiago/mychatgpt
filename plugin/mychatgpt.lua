local picker = require('mychatgpt.actions.picker')
local mychatgpt = require('mychatgpt')

local function reload()
  vim.cmd('wa')
  vim.cmd('source plugin/mychatgpt.lua')
  for k in pairs(package.loaded) do
    if k:match('^mychatgpt') then package.loaded[k] = nil end
  end
end

vim.keymap.set('n', '<leader>a', function()
  reload()
  mychatgpt.replace_selection_with_last_code_block()
  mychatgpt.selection:mark_with_sign()
end)

vim.keymap.set('n', '<leader>v', function()
  reload()
  mychatgpt.open_new_chat()
end)

picker.create_picker({
  keymap = '<leader><leader>o',
  title = 'MyChatGPT',
  callback = function(messages, selection)
    reload()
    if selection then
      mychatgpt.set_current_selection(selection)
      mychatgpt.selection:mark_with_sign()

      mychatgpt.open_new_chat({
        on_exit = function() mychatgpt.selection:remove_signs() end,
      })
    end

    mychatgpt.send_messages(messages)
  end,
})
