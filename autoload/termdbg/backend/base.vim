" 这是基类
" 每个后端需要指定的信息有
"   - next
"   - step
"   - finish
"   - continue
"   - SetBreakpoint
"   - ClearBreakpoint
"   - LocateCursor pattern
"   - new breakpoint pattern
"   - del breakpoint pattern

let s:config = {}
let s:config['prompt'] = '(Pdb) '
let s:config['next_cmd'] = 'next'
let s:config['step_cmd'] = 'step'
let s:config['finish_cmd'] = 'return'
let s:config['continue_cmd'] = 'continue'
let s:config['break_cmd'] = 'break'
let s:config['clear_cmd'] = 'clear'
let s:config['bt_cmd'] = 'bt'
let s:config['print_cmd'] = 'p'

function! s:init_argv(argv) abort
  return a:argv
endfunction
let s:config['init_argv'] = function('s:init_argv')

" 用于快速判断输出的类型是否为定位字符串, 以提高性能
" 提取定位的模式, 第一个子匹配为文件, 第二个子匹配为行号
" 文件名, 行号匹配组ID
let s:config['locate_pattern'] = {
      \ 'short': '^> ',
      \ 'long': '\v^\> (.+)\((\d+)\).*\(.*\).*$',
      \ 'index': [1, 2],
      \ }

" index: [breaknum, file, line]
let s:config['new_breakpoint_pattern'] = {
      \ 'short': '^Breakpoint \d\+ at ',
      \ 'long': '^Breakpoint \(\d\+\) at \(.\+\):\(\d\+\)',
      \ 'index': [1, 2, 3],
      \ }

" index: [breaknum, file, line]
let s:config['del_breakpoint_pattern'] = {
      \ 'short': '^Deleted breakpoint \d\+ at ',
      \ 'long': '^Deleted breakpoint \(\d\+\) at \(.\+\):\(\d\+\)',
      \ 'index': [1, 2, 3],
      \ }

func termdbg#backend#base#Get()
  return deepcopy(s:config)
endfunc

" vi:set sts=2 sw=2 et:
