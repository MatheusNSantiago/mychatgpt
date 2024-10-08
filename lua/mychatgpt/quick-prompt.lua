local Input = require('mychatgpt.shared.input')
local utils = require('mychatgpt.utils')
local Selection = require('mychatgpt.selection')
local M = {}

function M.open(callback)
  local selection = Selection.get_selection()

  if selection then selection:mark_with_sign() end

  local input
  input = Input({
    label = 'Prompt',
    relative = 'cursor',
    position = { row = 2, col = 0 },
    height_limit = { min = 1, max = 4 },
    on_submit = function(prompt)
      if not selection then return callback(prompt) end

      local final_text = utils.concat_lists(selection.lines, { '---' }, prompt)
      callback(final_text)
    end,
    on_close = function()
      if selection then selection:remove_signs() end
    end,
    close_after_submit = true,
    close_on_unfocus = true,
    on_number_of_lines_change = function() input:update_size() end,
    maps = {
      { 'n', 'q',     ':q<CR>',                                 { desc = 'Quit quick prompt' } },
      { 'i', '<C-c>', function() vim.cmd('stopinsert | q') end, { desc = 'Quit quick prompt' } },
    },
  })

  input:mount()
end

return M
