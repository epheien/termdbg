let s:config = backend#base#Get()
let s:config['prompt'] = '(gdb) '
let s:config['trim_ansi_escape'] = v:true
let s:config['next_cmd'] = 'n'
let s:config['step_cmd'] = 's'
let s:config['finish_cmd'] = 'fin'
let s:config['continue_cmd'] = 'c'
let s:config['break_cmd'] = 'b'
let s:config['clear_cmd'] = 'd'
let s:config['print_cmd'] = 'p'

let s:file = expand('<sfile>')
let s:dir = fnamemodify(s:file, ':h')
if has('win32')
  let s:config['init_cmds'] = 'source ' . s:dir . '\scripts\gdbinit'
else
  let s:config['init_cmds'] = 'source ' . s:dir . '/scripts/gdbinit'
endif

" Temporary breakpoint 2, main () at /home/eph/cpp-cmake/src/main.cpp:5
" Breakpoint 1, main () at /home/eph/cpp-cmake/src/main.cpp:6
" #0  main () at /home/eph/cpp-cmake/src/main.cpp:5
let s:config['locate_pattern'] = {
      \ 'short': '^#\d\+ \|^Temporary breakpoint \d\+,\|^Breakpoint \d\+,',
      \ 'long': '\v.+ at ([^:]+):(\d+)$',
      \ 'index': [1, 2],
      \ }

" Breakpoint 2 at 0x555555560f5c: file /home/eph/cpp-cmake/src/main.cpp, line 5.
let s:config['new_breakpoint_pattern'] = {
      \ 'short': '^Breakpoint \d\+ ',
      \ 'long': '\v^Breakpoint (\d+) at [^:]+: file ([^, ]+), line (\d+)\.$',
      \ 'index': [1, 2, 3],
      \ }

" gdb 没办法使用确认机制
let s:config['del_breakpoint_pattern'] = {
      \ 'short': '',
      \ 'long': '',
      \ 'index': [1],
      \ }

func backend#gdb#Get()
  return s:config
endfunc

" vi:set sts=2 sw=2 et:
