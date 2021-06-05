# monolithic.nvim

**After using this plugin somewhat regularly, I came to the conlusion that this plug-in should be repurposed to be used with a floating window. Opening directly inside a buffer gives the wrong impression that the files should directly be editable. But in fact, monolithic.nvim is just for code reading and navigation. If you want to use the previous version, please revert back to the comit** https://github.com/jbyuki/monolithic.nvim/commit/bb5f500047383abb4f5025d444ce48cba82b688e .

[monolithic.nvim]() allows you to open multiple files inside a float. It is an experimental plugin to explore code reading.

## Requirements

* Neovim 0.5
* [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) 

## Install

The easiest method is install through plugin manager such as [vim-plug](https://github.com/junegunn/vim-plug).

Add this to your plug-in list:

```vim
Plug 'jbyuki/monolithic.vim'
```

## But why?

With current programming methodologies, source code is often split up into multiple small modules. When you read the source code for the first time, it's often a pain to navigate between the files without the proper tools.

### Existing solution

The standard solution to go about this is to use a grep-like tool. Now with all the plugin integration which adds fuzzy-finding on-top, previewing, etc... it's really a breeze to search for a word accross files. However it's still a tool that needs to be invoked, you need to confirm you search, some UI you have to interact with which can feel heavy for some people.

### New solution

For small - medium projects, I think it's reasonable to open all files in one-go. This allows to have everything loaded in the buffer and now searching becomes instantenous and quickly skimming accross the files is natural.
