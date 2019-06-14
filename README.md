# termdbg

Termdbg is a terminal debugger plugin for vim 8.1+ and neovim 0.3.6+.  
Currently, termdbg only supports pdb, if you need gdb support, try termdebug (`:h termdebug`)

Currently, termdbg just only do these things:
- locate cursor to current runing line when debugger
- simply toggle breakpoints in buffer

## Install

> Need vim 8.1+ (+terminal) and neovim 0.3.6+.

For vim-plug

```viml
Plug 'epheien/termdbg'
```

For manual installation

- Extract the files and put them in your .vim directory  
  (usually `~/.vim`).

## Usage

Run `TermdbgPdb {pyfile}`

## Commands

- `:TNext` Step over
- `:TStep` Step in
- `:TFinish` Return from current function
- `:TContinue` Continue
- `:TLocateCursor` Locate cursor to running line
- `:TToggleBreak` Toggle breakpoint in current line


## Options

```viml
let g:termdbg_pdb_prog = 'pdb'
let g:termdbg_pdb3_prog = 'pdb3'
let g:termdbg_ipdb_prog = 'ipdb'
let g:termdbg_ipdb3_prog = 'ipdb3'
```

## Screenshots

![termdbg](https://ws3.sinaimg.cn/large/006tNc79gy1g02vid3jvij30u00ucdq1.jpg)
