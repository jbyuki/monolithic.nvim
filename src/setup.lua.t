##monolithic
@implement+=
function M.setup(opts)
  opts = opts or {}
  @validate_setup_options
  @set_options
end

@validate_setup_options+=
vim.validate {
  ["opts.excluded_pat"] = { opts.excluded_pat, 't', true },
  ["opts.mappings"] = { opts.mappings, 't', true },
}

@set_options+=
if opts.mappings then
  mappings = opts.mappings
end

if opts.excluded_pat then
  excluded_patterns = opts.excluded_pat
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
