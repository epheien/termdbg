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

"command -nargs=* -complete=file -bang Termdbg call termdbg#StartDebug(<bang>0, '', <q-mods>, <f-args>)
command -nargs=* -complete=customlist,s:TermdbgComplete -bang Termdbg call termdbg#StartDebug(<bang>0, '', <q-mods>, <f-args>)

func s:TermdbgComplete(ArgLead, CmdLine, CursorPos) abort
  let debuggers = ['pdb', 'pdb3', 'ipdb', 'ipdb3', 'dlv', 'gdb', 'lldb']

  if a:CmdLine =~ '^\w\+\s\+\w*$'
    " 如果命令行只有一个参数,使用 debuggers 列表进行补全
    return filter(copy(debuggers), 'v:val =~ "^" . a:ArgLead')
  else
    " 对于其他参数,使用文件补全
    "return map(glob(a:ArgLead . '*', 0, 1), {key, val -> isdirectory(val) ? val . '/' : val})
    return getcompletion(a:ArgLead, 'file')
  endif
endfunc

" vim:sts=2:sw=2:et:
