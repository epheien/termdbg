" Description:  Terminal debugger
" Maintainer:   fanhe <fanhed@163.com>
" License:      GPLv2
" Create:       2019-02-11
" Change:       2019-02-11

if !has('nvim') && !has('terminal')
  "echohl WarningMsg
  "echomsg 'termdbg need compliled with +terminal'
  "echohl None
  finish
endif

if exists('s:loaded')
  finish
endif
let s:loaded = 1

command -nargs=+ -complete=file -bang Termdbg call termdbg#StartDebug(<bang>0, '', <q-mods>, <f-args>)

" vim:sts=2:sw=2:et:
