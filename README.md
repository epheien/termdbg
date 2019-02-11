# termdbg
Termdbg is a terminal debugger plugin for vim 8.1 and later.

Currently, termdbg support pdb and ipdb, if you need gdb support, try termdebug (`:h termdebug`)

Currently, termdbg just only do these things:
- locate cursor to current runing line when debugger
- simply toggle breakpoints in buffer

## Install
> Need vim 8.1 and later and compiled with +terminal feature.

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
call s:InitVariable('g:termdbg_pdb_prog',   'pdb')
call s:InitVariable('g:termdbg_pdb3_prog',  'pdb3')
call s:InitVariable('g:termdbg_ipdb_prog',  'ipdb')
call s:InitVariable('g:termdbg_ipdb3_prog', 'ipdb3')
```
