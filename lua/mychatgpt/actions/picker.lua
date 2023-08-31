local M = {}

--- Cria um picker pro telescope
---@class PickerOptions
---@field keymap string
---@field title string
---@field options string[]
---@field callback function

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

		-- Caso estaja em modo visual, o nvim precisa de um pouco de mais tempo
		-- para processar os marks '< e '>, então é necessário adicionar um delay
		local isVisualMode = vim.fn.mode() == 'v' or vim.fn.mode() == 'V'
		if isVisualMode then
			-- Sai do modo visual (para que os registradores '<,'> sejam preenchidos)
			local ESC_FEEDKEY = vim.api.nvim_replace_termcodes('<ESC>', true, false, true)
			vim.api.nvim_feedkeys(ESC_FEEDKEY, 'n', true)
			delay_ms = 100
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
							local actions = require('telescope.actions')

							-- On item select
							actions.select_default:replace(function()
								local state = require('telescope.actions.state')
								local selection = state.get_selected_entry()

								actions.close(prompt_buffer_number) -- Closing the picker

								opts.callback(selection.value)  -- executa o callback
							end)
							return true
						end,
					})
					:find()
		end, delay_ms)
	end)
end

return M.create_picker
