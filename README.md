# batteries.nvim

Ergonomic Neovim Lua bindings.

See `:h batteries` or [9999years.github.io/batteries.nvim][docs] for thorough
documentation.

[docs]: https://9999years.github.io/batteries.nvim/

# batteries.map()

Define key mappings:

```lua
-- :nnoremap <silent> <Leader>og <Cmd>Browse<CR>
require("batteries").map {
  -- When I hit `\og`...
  "<Leader>og",
  -- Execute the `:Browse` command.
  "<Cmd>Browse<CR>",
  -- Set a description:
  "Open file on GitHub",
}

-- Define multiple mappings with a common prefix together:
require("batteries").map {
  prefix = "<Leader>",
  { "t", "<Cmd>Telescope<CR>", "Telescope" },
  -- Buffer local mapping:
  { "f", "<Cmd>Telescope find_files<CR>", "Find files", buffer = 3 },
}
```

The following definitions are equivalent:

```lua
require("batteries").map {
  prefix = "<Leader>f",
  name = "+file",
  { "f", "<Cmd>Telescope find_files<CR>", "Find file" },
  { "r", "<Cmd>Telescope oldfiles<CR>", "Open recent file" },
  { "n", "<Cmd>enew<CR>", "New file" },
}

require("batteries").map {
  { prefix = "<Leader>f", name = "+file" },
  { "<Leader>ff", "<Cmd>Telescope find_files<CR>", "Find file" },
  { "<Leader>fr", "<Cmd>Telescope oldfiles<CR>", "Open recent file" },
  { "<Leader>fn", "<Cmd>enew<CR>", "New file" },
}
```

# batteries.cmd()

Define a command:

```lua
require("batteries").cmd {
  range = true,
  nargs = 0,
  "Browse",
  "<line1>,<line2>OpenGithubFile",
}

require("batteries").cmd {
  nargs = "?",
  complete = "filetype",
  "EditFtplugin",
  "call misc#EditFtplugin(<f-args>)",
}
```
