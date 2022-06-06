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

-- `:h batteries.cmd()`
-- TODO: Implement this with `vim.api.nvim_create_user_command` instead of
-- string concatenation / `vim.cmd`.
function M.cmd(opts)
  local def = "command! "
  if opts.nargs then
    def = def .. "-nargs=" .. opts.nargs .. " "
  end
  if opts.complete then
    def = def .. "-complete=" .. opts.complete .. " "
  end
  if opts.range then
    if opts.range == true then
      def = def .. "-range "
    else
      def = def .. "-range=" .. opts.range .. " "
    end
  end
  if opts.count then
    def = def .. "-count=" .. opts.count .. " "
  end
  if opts.addr then
    def = def .. "-addr=" .. opts.addr .. " "
  end
  if opts.bang then
    def = def .. "-bang "
  end
  if opts.bar then
    def = def .. "-bar "
  end
  if opts.register then
    def = def .. "-register "
  end
  if opts.buffer then
    def = def .. "-buffer "
  end
  if opts.keepscript then
    def = def .. "-keepscript "
  end
  def = def .. opts[1] .. " " .. opts[2]
  vim.cmd(def)
end

function map_inner(buffer, mode, lhs, rhs, opts)
  function map_maybe_buffer(buffer, mode, lhs, rhs, opts)
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

function map_one(opts)
  local prefix = opts.prefix or ""
  local lhs = prefix .. opts[1]
  local rhs = opts[2]
  local desc = opts[3] or opts.desc
  local mode = opts.mode or "n"
  local set_opts = {
    desc = desc,
    expr = opts.expr,
    nowait = opts.nowait,
    noremap = opts.noremap,
    remap = opts.remap,
    replace_keycodes = opts.replace_keycodes,
    script = opts.script,
    silent = opts.silent,
    unique = opts.unique,
  }

  if set_opts.silent == nil then
    set_opts.silent = true
  end

  if type(rhs) == "function" then
    set_opts.callback = rhs
    rhs = ""
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
