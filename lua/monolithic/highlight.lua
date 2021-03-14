local highlight = {}
local api = vim.api
local utils = require "monolithic.utils"
local ts = vim.treesitter

function highlight.is_treesitter_supported(buf, langs)
  local is_supported = true
  local langs_set = utils.make_set_from_keys(langs)
  if vim.tbl_count(langs_set) > 1 then
    return false
  end

  for lang, _ in pairs(langs_set) do
    local success = pcall(ts.get_parser, buf, lang)
    if not success then
      is_supported = false
    end
  end
  return is_supported
end

function highlight.transform_to_treesitter_regions(regions)
  local ts_regions = {}
  for _, region in ipairs(regions) do
    local start_lnum, stop_lnum = unpack(region)
    table.insert(ts_regions, { {
      start_lnum, 0, stop_lnum, 0
    }})
  end
  return ts_regions
end

function highlight.create_treesitter_highlighter(buf, lang, regions)
  local parser = ts.get_parser(buf, lang)
  local ts_regions = highlight.transform_to_treesitter_regions(regions)
  parser:set_included_regions(ts_regions)

  -- might be a good idea to keep them in a list
  -- to free them afterwards somehow
  ts.highlighter.new(parser, {})
end

function highlight.highlight_with_treesitter(buf, langs, regions, ns_id, extmarks)
  assert(#langs == #regions)

  -- might be a good idea to cleanup everything related
  -- to treesitter first

  local regions_by_lang = utils.group_by_key(langs, regions)
  local extmarks_by_lang = utils.group_by_key(langs, extmarks)
  for lang, region in pairs(regions_by_lang) do
    highlight.create_treesitter_highlighter(buf, lang, region)
  end
  highlight.attach_buf(buf, ns_id, extmarks_by_lang)
end

function highlight.highlight_with_vim(buf, langs, regions)
  assert(api.nvim_get_current_buf() == buf)

  vim.api.nvim_command("syn clear")

  local lang_set = utils.make_set_from_keys(langs)
  for lang,_ in pairs(lang_set) do
    vim.api.nvim_command("syn include @" .. lang .. " syntax/" .. lang .. ".vim")
    vim.api.nvim_command("unlet b:current_syntax")
  end

  local block_num = 1
  for i=1,#langs do
    local startlnum, endlnum = unpack(regions[i])
    vim.api.nvim_command("syn region block" .. block_num .. " start=\"\\%" .. (startlnum+1) .. "l\" end=\"\\%" .. (endlnum+1) .. "l\" contains=@" .. langs[i])
    block_num = block_num + 1
  end

  -- slow but accurate, otherwise we get
  -- highlighting bug (no highlight) when 
  -- navigating in a large file
  vim.api.nvim_command("syn sync fromstart")
end

function highlight.highlight_headers(buf, lnums, hl_group)
  -- might also be useful to keep highlight ids
  -- in a list, but for now it shouldn't be necessary
  for _, lnum in ipairs(lnums) do
    vim.api.nvim_buf_add_highlight(buf, 0, hl_group, lnum, 0, -1)
  end
end

function highlight.attach_buf(buf, ns_id, extmarks)
  vim.api.nvim_buf_attach(buf, false, {
    on_lines = function(_, _, _, _, lastline, new_lastline, _)
      if lastline ~= new_lastline then
        vim.schedule(function()
          for lang, extmark in pairs(extmarks) do
            local parser = ts.get_parser(buf, lang)
            local new_regions = highlight.get_extmark_positions(buf, ns_id, extmark)

            local ts_regions = highlight.transform_to_treesitter_regions(new_regions)
            parser:set_included_regions(ts_regions)
            parser:invalidate()
            parser:parse()
          end
        end)
      end
    end })
end

function highlight.get_extmark_positions(buf, ns_id, extmarks)
  local new_regions = {}
  for _, mark in ipairs(extmarks) do
    local startext, endext = unpack(mark)
    local startlnum, _ = unpack(vim.api.nvim_buf_get_extmark_by_id(buf, ns_id, startext, {}))
    local endlnum, _ = unpack(vim.api.nvim_buf_get_extmark_by_id(buf, ns_id, endext, {}))
    table.insert(new_regions, {startlnum, endlnum})
  end
  return new_regions
end

return highlight
