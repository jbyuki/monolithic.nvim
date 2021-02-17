# monolithic.nvim

[monolithic.nvim]() allows you to open multiple files in one buffer. It is an experimental plugin to explore code reading.

[![Capture.png](https://i.postimg.cc/3wvmhBLN/Capture.png)](https://postimg.cc/8FTjBhgg)

## Requirements

Neovim 0.5

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

or your `init.lua`:

```lua
vim.api.nvim_command([[command OpenAll lua require"monolithic".open()]])
```

**Optional**: For correct embedded syntax highlighting support install [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter). (highly recommended)

## Basic usage

* Change the working directory to your project's directory using `:cd`.
* Invoke **monolithic** using `:OpenAll`

## Configuration

#### Add additionnal filetypes

`init.vim`
```vim
lua << END
require"monolithic".ext["extension_here"] = "syntax_filename_here"
END
```

Note: See `:lua print(vim.inspect(require"monolithic".ext["extension_here"]))` for the default configuration.

#### Change the filename header styling

`init.vim`
```vim
lua << END
require"monolithic".header_pre = "## "
require"monolithic".header_post = " ###########"
END
```

## But why?

With current programming methodologies, source code is often split up into multiple small modules. When you read the source code for the first time, it's often a pain to navigate between the files without the proper tools.

### Existing solution

The standard solution to go about this is to use a grep-like tool. Now with all the plugin integration which adds fuzzy-finding on-top, previewing, etc... it's really a breeze to search for a word accross files. However it's still a tool that needs to be invoked, you need to confirm you search, some UI you have to interact with which can feel heavy for some people.

### New solution

For small - medium projects, I think it's reasonable to open all files in one-go. This allows to have everything loaded in the buffer and now searching becomes instantenous and quickly skimming accross the files is natural.
