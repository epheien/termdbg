let s:config = backend#base#Get()
let s:config['prompt'] = '(lldb) '
let s:config['trim_ansi_escape'] = v:true
let s:config['next_cmd'] = 'next'
let s:config['step_cmd'] = 'step'
let s:config['finish_cmd'] = 'finish'
let s:config['continue_cmd'] = 'continue'
let s:config['break_cmd'] = 'b'
let s:config['clear_cmd'] = 'breakpoint delete'
let s:config['print_cmd'] = 'p'

let s:file = expand('<sfile>')
let s:dir = fnamemodify(s:file, ':h')
" TODO: Windows
let s:config['init_cmds'] = [
      \ 'command source ' . s:dir . '/scripts/lldbinit',
      \ 'command script import ' . s:dir . '/scripts/custom_breakpoint.py'
      \]

" frame #0: 0x0000000100000f74 a.out`main(argc=1, argv=0x00007ffeefbff700) at a.c:5:2
let s:config['locate_pattern'] = {
      \ 'short': '^\s*frame #',
      \ 'long': '\v^\s*frame #\d+: .+ at ([^:]+):(\d+):\d+',
      \ 'index': [1, 2],
      \ }

" Breakpoint 4: where = a.out`main + 22 at a.c:4:2, address = 0x0000000100000f66
" Breakpoint 00 set at /Users/eph/wsp/cpp-cmake/src/main.cpp:6
" backup: '\v^Breakpoint (\d+): where = .+ at ([^:]+):(\d+):\d+, .*$',
let s:config['new_breakpoint_pattern'] = {
      \ 'short': '^Breakpoint \d\+ ',
      \ 'long': '\v^Breakpoint (\d+) set at ([^:]+):(\d+)$',
      \ 'index': [1, 2, 3],
      \ }

" (lldb) breakpoint delete 2
" 1 breakpoints deleted; 0 breakpoint locations disabled.
" NOTE: lldb 没办法使用确认机制
let s:config['del_breakpoint_pattern'] = {
      \ 'short': '',
      \ 'long': '',
      \ 'index': [1],
      \ }

func backend#lldb#Get()
  return s:config
endfunc

" vi:set sts=2 sw=2 et:
