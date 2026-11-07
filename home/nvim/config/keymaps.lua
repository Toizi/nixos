-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = vim.keymap.set
--
-- -- remap <leader>c to <leader>l
-- map("n", "<leader>lf", function()
--   LazyVim.format({ force = true })
-- end, { desc = "Format" })
--
-- map("n", "<leader>ld", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
--
-- -- remap launching lazy
-- map("n", "<leader>p", "<cmd>Lazy<cr>", { desc = "Lazy" })
--
-- vim.keymap.del("n", "<leader>cf")
-- vim.keymap.del("n", "<leader>cd")
-- vim.keymap.del("n", "<leader>l")

map("v", "<leader>y", '"+y', { desc = "Copy to clipboard" })

map(
  "n",
  "<leader>yP",
  "<cmd>let @+ = expand('%:~:.')<cr>",
  { desc = "Copy relative path" }
)

map(
  "n",
  "<leader>yp",
  "<cmd>let @+ = expand('%')<cr>",
  { desc = "Copy absolute path" }
)
