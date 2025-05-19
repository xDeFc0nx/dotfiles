return {
  "richardhapb/neospeller.nvim",
  opt = true,
  config = function() require('neospeller').setup() end,
  cmd = "CheckSpell",
  keys = {
    { "<leader>S", ":CheckSpell<CR>",     mode = { "x", "n" }, desc = "Check spelling" },
    { "<leader>D", ":CheckSpellText<CR>", mode = { "x", "n" }, desc = "Check spelling" }
  }
}
