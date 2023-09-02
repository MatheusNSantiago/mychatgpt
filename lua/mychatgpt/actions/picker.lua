local actions = require('mychatgpt.actions')
local Selection = require('mychatgpt.selection')

local M = {}

--- Cria um picker pro telescope
---@class PickerOptions
---@field keymap string
---@field title string
---@field options string[]
---@field callback fun(prompt: string[], selection)

---@param opts PickerOptions
function M.create_picker(opts)
	local entry_maker = function(menu_item)
		return {
			value = menu_item,
			ordinal = menu_item,
			display = menu_item,
		}
	end

	vim.keymap.set({ 'n', 'x' }, opts.keymap, function()
		local delay_ms = 0
		local selection = nil

		-- Caso estaja em modo visual, o nvim precisa de um pouco de mais tempo
		-- para processar os marks '< e '>, então é necessário adicionar um delay
		local isVisualMode = vim.fn.mode() == 'v' or vim.fn.mode() == 'V'
		if isVisualMode then
			selection = Selection.get_selection()
			-- -- Sai do modo visual (para que os registradores '<,'> sejam preenchidos)
			-- local ESC_FEEDKEY = vim.api.nvim_replace_termcodes('<ESC>', true, false, true)
			-- vim.api.nvim_feedkeys(ESC_FEEDKEY, 'n', true)
			-- delay_ms = 100
		end

		vim.defer_fn(function()
			require('telescope.pickers')
					.new(require('telescope.themes').get_dropdown({}), {
						prompt_title = opts.title,
						finder = require('telescope.finders').new_table({
							results = opts.options,
							entry_maker = entry_maker,
						}),
						sorter = require('telescope.sorters').get_generic_fuzzy_sorter(),
						attach_mappings = function(prompt_buffer_number)
							local telescope_action = require('telescope.actions')

							-- On item select
							telescope_action.select_default:replace(function()
								local state = require('telescope.actions.state')
								local selected_entry = state.get_selected_entry()

								telescope_action.close(prompt_buffer_number) -- Closing the picker

								if selection then
									actions.execute_action(selected_entry.value, function(prompt)
										opts.callback(prompt, selection) -- executa o callback
									end)
								else
									-- opts.callback(prompt, selection) -- executa o callback
								end
							end)
							return true
						end,
					})
					:find()
		end, delay_ms)
	end)
end

return M
