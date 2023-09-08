local Selection = require('mychatgpt.selection')
local utils = require('mychatgpt.utils')
local options = require('mychatgpt.actions.options')
local Message = require('mychatgpt.message')

local M = {}

---@class PickerOptions
---@field keymap string
---@field title string
---@field callback fun(messages: Message[], selection)

---Cria um picker pro telescope
---@param opts PickerOptions
function M.create_picker(opts)
	local entry_maker = function(menu_item) return { value = menu_item, ordinal = menu_item, display = menu_item } end

	vim.keymap.set({ 'n', 'x' }, opts.keymap, function()
		local selection = nil

		local isVisualMode = vim.fn.mode() == 'v' or vim.fn.mode() == 'V'
		if isVisualMode then selection = Selection.get_selection() end

		require('telescope.pickers')
				.new(require('telescope.themes').get_dropdown({}), {
					prompt_title = opts.title,
					finder = require('telescope.finders').new_table({
						results = vim.tbl_keys(options),
						entry_maker = entry_maker,
					}),
					sorter = require('telescope.sorters').get_generic_fuzzy_sorter(),
					attach_mappings = function(prompt_buffer_number)
						local telescope_action = require('telescope.actions')

						-- On item select
						telescope_action.select_default:replace(function()
							local state = require('telescope.actions.state')
							local selected_entry = state.get_selected_entry()
							local option = selected_entry.value

							telescope_action.close(prompt_buffer_number) -- Closing the picker

							if selection then
								local messages = M.get_messages(option, selection)

								opts.callback(messages, selection) -- executa o callback
							else
								-- opts.callback(prompt, selection) -- executa o callback
							end
						end)
						return true
					end,
				})
				:find()
	end)
end

---@return Message[]
function M.get_messages(title, selection)
	local item = options[title]
	local messages = {}

	for _, message in ipairs(item.messages) do
		local lines = M._render_template(message, item.variables, selection)
		local role = message.role

		table.insert(messages, Message.new({ role = role, lines = lines, is_hidden = false }))
	end

	return messages
end

function M._render_template(message, variables, selection)
	local filetype = utils.get_buf_filetype()
	local content = message.content
	-- find all words that are surrounded by {{}}
	local variables_matched = content:gmatch('{{(.-)}}')

	-- replace all {{}} with the value of the variable
	for variable in variables_matched do
		local value

		if variable == 'filetype' then
			value = filetype
		elseif variable == 'selection' then
			value = table.concat(selection.lines, '\n')
		elseif variable == 'selection_with_line_number' then
			value = table.concat(selection:get_lines_with_line_number(), '\n')
		else -- variável foi setada pelo usuário
			value = variables[variable]
			value = value[filetype] or value.default
		end

		content = content:gsub('{{' .. variable .. '}}', value)
	end

	local content_lines = utils.split_into_lines(content)
	return content_lines
end

return M
