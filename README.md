# monolithic.nvim

[monolithic.nvim]() allows you to open multiple files in one buffer. It is an experimental plugin to explore code reading.

[![Capture.png](https://i.postimg.cc/3wvmhBLN/Capture.png)](https://postimg.cc/8FTjBhgg)

## Requirements

* Neovim 0.5
* [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) for correct embedded syntax highlighting (optional but recommended)

## Install

The easiest method is install through plugin manager such as [vim-plug](https://github.com/junegunn/vim-plug).

Add this to your plug-in list:

```vim
Plug 'jbyuki/monolithic.vim'
```



## Get started

Add the following to your `init.vim`:

```vim
command OpenAll lua require"monolithic".open()
```

## Basic usage

1. Change the working directory to your project's directory using `:cd`.
2. Invoke **monolithic** using `:OpenAll` or `:lua require"monolithic.open()`.

## Configuration

#### Add additionnal filetypes

`init.vim`
```lua
lua << END
require"monolithic".setup {
	-- add additionnal extensions to be deteted for syntax highlighting
	-- existing defaults can also be replaced
	ext_map = { 
		"md" = "markdown"
	},

	-- highlight group for header with filename
	header_hl_group = "Title",

	-- header styling
	header_pre = "## ",  
	header_post = " #####",
}
END
```

Note: See `:lua print(vim.inspect(require"monolithic"._ext_map))` for the default configuration.

## But why?

With current programming methodologies, source code is often split up into multiple small modules. When you read the source code for the first time, it's often a pain to navigate between the files without the proper tools.

### Existing solution

The standard solution to go about this is to use a grep-like tool. Now with all the plugin integration which adds fuzzy-finding on-top, previewing, etc... it's really a breeze to search for a word accross files. However it's still a tool that needs to be invoked, you need to confirm you search, some UI you have to interact with which can feel heavy for some people.

### New solution

For small - medium projects, I think it's reasonable to open all files in one-go. This allows to have everything loaded in the buffer and now searching becomes instantenous and quickly skimming accross the files is natural.
