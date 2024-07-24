-- The batteries module. `:h batteries.nvim`
local M = {
  debug = false,
}

-- `:h batteries.tbl_pick()`
function M.tbl_pick(t, keys)
  -- `vim.tbl_filter` doesn't work here because it filters based on the values,
  -- not the keys of the map.
  local ret = {}
  for key, value in pairs(t) do
    if vim.tbl_contains(keys, key) then
      ret[key] = value
    end
  end
  return ret
end

CMD_OPTS = {
  "nargs",
  "complete",
  "range",
  "count",
  "addr",
  "bang",
  "bar",
  "register",
  "buffer",
  "keepscript",
  "force",
  "desc",
}

local function cmd_one(opts)
  local name = opts[1]
  local replacement = opts[2]
  local cmd_opts = M.tbl_pick(opts, CMD_OPTS)
  cmd_opts.desc = opts[3] or opts.desc
  vim.api.nvim_create_user_command(name, replacement, cmd_opts)
end

-- `:h batteries.cmd()`
function M.cmd(cmds)
  if type(cmds[1]) == "string" then
    -- `cmds[1]` is a name; pass to `cmd_one`.
    cmd_one(cmds)
  else
    -- `cmds[1]` is a table; merge top-level `cmds` attrs into each element
    -- before recursing.
    for _, cmd in ipairs(cmds) do
      local resolved_cmd = vim.tbl_extend(
        "keep", -- leftmost
        cmd,
        M.tbl_pick(cmds, CMD_OPTS)
      )
      M.cmd(resolved_cmd)
    end
  end
end

local function map_inner(buffer, mode, lhs, rhs, opts)
  local function map_maybe_buffer(buffer, mode, lhs, rhs, opts)
    if buffer then
      if M.debug then
        print(
          "batteries: nvim_buf_set_keymap("
            .. buffer
            .. ', "'
            .. mode
            .. '", "'
            .. lhs
            .. '", "'
            .. rhs
            .. '", '
            .. vim.inspect(opts)
        )
      end
      vim.api.nvim_buf_set_keymap(buffer, mode, lhs, rhs, opts)
    else
      if M.debug then
        print('batteries: nvim_set_keymap("' .. mode .. '", "' .. lhs .. '", "' .. rhs .. '", ' .. vim.inspect(opts))
      end
      vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
    end
  end

  if type(mode) == "table" then
    -- Multiple modes.
    for _, one_mode in ipairs(mode) do
      map_maybe_buffer(buffer, one_mode, lhs, rhs, opts)
    end
  else
    -- Single mode.
    map_maybe_buffer(buffer, mode, lhs, rhs, opts)
  end
end

local function map_one(opts)
  local prefix = opts.prefix or ""
  local lhs = prefix .. opts[1]
  local rhs = opts[2]
  local mode = opts.mode or "n"
  local set_opts = M.tbl_pick(opts, {
    "expr",
    "nowait",
    "noremap",
    "remap",
    "replace_keycodes",
    "script",
    "silent",
    "unique",
  })
  set_opts.desc = opts[3] or opts.desc

  if set_opts.silent == nil then
    set_opts.silent = true
  end

  if type(rhs) == "function" then
    set_opts.callback = rhs
    rhs = ""
  end

  if rhs == nil then
    vim.notify(
      "`batteries.map` was called with a nil right-hand side for mapping " .. vim.inspect(lhs),
      vim.log.levels.ERROR
    )
    return
  end

  if set_opts.noremap == nil and set_opts.remap == nil then
    set_opts.noremap = not vim.startswith(rhs, "<Plug>")
  end

  map_inner(opts.buffer, mode, lhs, rhs, set_opts)
end

-- `:h batteries.map()`
function M.map(mappings)
  if mappings.name ~= nil then
    -- Set the name for this prefix with `which-key`.
    -- See: https://github.com/folke/which-key.nvim
    require("which-key").register {
      [mappings.prefix] = { name = mappings.name },
    }
  end

  if type(mappings[1]) == "string" then
    -- `mappings[1]` is a lhs; pass to `map_one`.
    map_one(mappings)
  else
    -- `mappings[1]` is a table; merge top-level `mappings` attrs into each
    -- element before recursing.
    for _, mapping in ipairs(mappings) do
      local resolved_mapping = vim.tbl_extend(
        "keep", -- leftmost
        -- Concatenate prefixes, but use other keys from `mapping` and `mappings`.
        { prefix = (mappings.prefix or "") .. (mapping.prefix or "") },
        mapping,
        M.tbl_pick(mappings, {
          "desc",
          "mode",
          "expr",
          "nowait",
          "noremap",
          "remap",
          "replace_keycodes",
          "script",
          "silent",
          "unique",
        })
      )
      M.map(resolved_mapping)
    end
  end
end

return M
