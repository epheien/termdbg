" Description:  Terminal debugger
" Maintainer:   fanhe <fanhed@163.com>
" License:      GPLv2
" Create:       2019-02-11
" Change:       2019-02-11

if !has('nvim') && !has('terminal')
  echohl WarningMsg
  echomsg 'termdbg need compliled with +terminal'
  echohl None
  finish
endif

if exists('g:loaded_termdbg')
  finish
endif
let g:loaded_termdbg = 1

command -nargs=* -complete=file -bang Termdbg call termdbg#StartDebug(<bang>0, '', <q-mods>, <f-args>)

"func TermdbgComplete(argLead, cmdLine, cursorPos)
"  echomsg string(a:argLead) string(a:cmdLine) string(a:cursorPos)
"  return join(['pdb', 'pdb3', 'ipdb', 'ipdb3', 'dlv', 'gdb', 'lldb'], "\n")
"endfunc

" vim:sts=2:sw=2:et:
