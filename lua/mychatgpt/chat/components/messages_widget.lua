local Popup = require('nui.popup')

local chat_window = Popup({
  border = {
    highlight = 'FloatBorder',
    style = 'rounded',
    text = {
      top = ' Mochila de Criança ',
    },
  },
  win_options = {
    wrap = true,
    linebreak = true,
    foldcolumn = '1',
    winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
  },
  buf_options = {
    filetype = 'markdown',
  },
})

chat_window:map('n', 'q', ':q<CR>', { desc = 'Quit chat' })

return chat_window
