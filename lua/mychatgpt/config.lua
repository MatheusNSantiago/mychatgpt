return {
  openai_params = {
    -- model = 'gpt-4',
    model = 'gpt-3.5-turbo',
    frequency_penalty = 0,
    presence_penalty = 0,
    max_tokens = 300,
    temperature = 0,
    top_p = 1,
    n = 1,
  },
  popup_input = {
    focusable = true,
    prompt = '  ',
    border = {
      highlight = 'FloatBorder',
      style = 'rounded',
      text = { top_align = 'center', top = ' Prompt ' },
    },
    win_options = {
      winhighlight = 'Normal:Normal,FloatBorder:FloatBorder',
    },
    submit = '<Enter>',
    submit_n = '<Enter>',
  },
  popup_layout = {
    default = 'center',
    center = {
      width = '80%',
      height = '80%',
    },
    right = {
      width = '30%',
      width_settings_open = '50%',
    },
  },
}
