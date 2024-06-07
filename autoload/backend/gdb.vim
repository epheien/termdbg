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
" TODO: Windows
"let s:config['init_cmds'] = 'source ' . s:dir . '/scripts/gdbinit'

function! s:init_argv(argv) abort
  let argv = a:argv
  return [argv[0], '-x', s:dir . '/scripts/gdbinit'] + argv[1:]
endfunction

let s:config['init_argv'] = function('s:init_argv')

" Temporary breakpoint 2, main () at /home/eph/cpp-cmake/src/main.cpp:5
" Breakpoint 1, main () at /home/eph/cpp-cmake/src/main.cpp:6
" #0  main () at /home/eph/cpp-cmake/src/main.cpp:5
" std::thread::thread<main()::<lambda(int)>, int>(struct {...} &&) (this=0x7fffffffdfa0, __f=...) at /usr/include/c++/11/bits/std_thread.h:127
" 也就是路径过长换行了
"     at /home/eph/.conan/data/xxxxx/1.1.4/_/_/build/31474e57b781878f04314a02557931e9b6a8891c/client/src/client.cc:309
let s:config['locate_pattern'] = {
      \ 'short': '^#\d\+ \|^Temporary breakpoint \d\+,\|^Breakpoint \d\+,\|^    at \|\v\) at ([^:]+):(\d+)$',
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
