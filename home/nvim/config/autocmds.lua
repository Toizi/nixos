-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("Change_InlayHintColor", { clear = true}),
  callback = function()
    vim.api.nvim_set_hl(0, "LspInlayHint", { fg = "#a19c9c"})
    vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", { fg = "#7191A8" })
  end,
  desc = "Change inlay hint color",
})
