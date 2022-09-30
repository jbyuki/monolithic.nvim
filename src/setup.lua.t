##monolithic
@implement+=
function M.setup(opts)
  opts = opts or {}
  -- @deprecation_warnings
  @validate_setup_options
  @set_options
end

@validate_setup_options+=
vim.validate {
  ["opts.mappings"] = { opts.mappings, 't', true },
}

@set_options+=
if opts.mappings then
  mappings = opts.mappings
end

@validate_setup_options+=
vim.validate {
  ["opts.perc_width"] = { opts.perc_width, 'n', true },
  ["opts.perc_height"] = { opts.perc_height, 'n', true },
}

@set_options+=
if opts.perc_width then
  perc_width = opts.perc_width
end

if opts.perc_height then
  perc_height = opts.perc_height
end

@deprecation_warnings+=
if opts.search_pat then
  vim.api.nvim_echo({{"search_pat is deprecated. See README.md", "ErrorMsg"}}, true, {})
end

if opts.excluded_pat then
  vim.api.nvim_echo({{"(monolithic.nvim): excluded_pat is deprecated. See README.md", "ErrorMsg"}}, true, {})
end

@validate_setup_options+=
vim.validate {
  ["opts.valid_ext"] = { opts.valid_ext, 't', true },
}

@script_variables+=
local valid_ext = {
  ["lua"] = true,
  ["py"] = true,
  ["cpp"] = true,
  ["c"] = true,
  ["h"] = true,
  ["hpp"] = true,
}

@set_options+=
if opts.valid_ext then
  valid_ext = {}
  for _, v in ipairs(opts.valid_ext) do
    valid_ext[v] = true
  end
end

@script_variables+=
local exclude_dirs = {
  [".git"] = true,
  ["__pycache__"] = true,
}

@validate_setup_options+=
vim.validate {
  ["opts.exclude_dirs"] = { opts.exclude_dirs, 't', true },
}

@set_options+=
if opts.exclude_dirs then
  exclude_dirs = {}
  for _, v in ipairs(opts.exclude_dirs) do
    exclude_dirs[v] = true
  end
end

@validate_setup_options+=
vim.validate {
  ["opts.highlight"] = { opts.enable_highlight, 'b', true },
}

@script_variables+=
local highlight = true

@set_options+=
if opts.highlight ~= nil then
  highlight = opts.highlight
end
