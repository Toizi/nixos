return {
  {
    "saghen/blink.cmp",
    ---@module 'blink.cmp'
    ---@param opts blink.cmp.Config
    opts = function(_, opts)
      opts.completion.ghost_text.enabled = false
      -- don't accept autocompletion via enter
      opts.keymap['<CR>'] = {}
      -- accept autocompletion via ctrl+l instead
      opts.keymap['<C-l>'] = { 'accept', 'fallback' }
    end,
  },
}
