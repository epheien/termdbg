# termdbg

Termdbg is a terminal debugger plugin for vim 8.1+ and neovim 0.3.6+.
Currently, termdbg supports pdb, ipdb, lldb, dlv(go Delve), gdb.
If you need advanced gdb support, try termdebug (`:h termdebug`)

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

Run `Termdbg {debugger} {file}`

## Commands

- `:TNext` Step over
- `:TStep` Step in
- `:TFinish` Return from current function
- `:TContinue` Continue
- `:TLocateCursor` Locate cursor to running line
- `:TToggleBreak` Toggle breakpoint in current line
- `:TSendCommand` Send command to debugger


## Options
None.

## Screenshots

![termdbg](https://raw.githubusercontent.com/epheien/termdbg/master/screenshots/dlv.png)
