local Input = require('mychatgpt.shared.input')
local utils = require('mychatgpt.utils')
local M = {}

function M.open(callback)
  local selection_ok, selection = pcall(require('mychatgpt.selection').get_selection)
  local input

  input = Input({
    label = 'ola',
    relative = 'cursor',
    position = { row = 2, col = 0 },
    height_limit = { min = 1, max = 4 },
    on_submit = function(prompt)
      local final_text = prompt

      if selection_ok then
        final_text = utils.concat_lists(selection.lines, { '---' }, prompt) --
      end

      callback(final_text)
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
