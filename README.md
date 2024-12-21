# ch.sh-telescope
use cht.sh with nvim-telescope

### Disclaimer
This is a personal project, very much a WIP.

## Installation
via [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
  "zmoney20/cht-telescope",
  dependencies = { "nvim-telescope/telescope.nvim" },
  config = function()
    require("cht-telescope").setup({
      -- options
      -- debounce = 100,
    })
  end
}
```

## Usage
```lua
vim.keymap.set("n", "<leader>sc", require("cht-telescope").search_cht_sh, { desc = "[S]earch [C]heat Sheet" })
```
