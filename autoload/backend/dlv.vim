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

let s:config = backend#base#Get()
let s:config['prompt'] = '(dlv) '
let s:config['trim_ansi_escape'] = v:true
let s:config['next_cmd'] = 'next'
let s:config['step_cmd'] = 'step'
let s:config['finish_cmd'] = 'stepout'
let s:config['continue_cmd'] = 'continue'
let s:config['break_cmd'] = 'break'
let s:config['clear_cmd'] = 'clear'
let s:config['print_cmd'] = 'p'

" > main.main() ./a.go:14 (hits goroutine(1):1 total:1) (PC: 0x10f47db)
" Frame 1: ./fsrunner/runner.go:10343 (PC: 166d13a)
let s:config['locate_pattern'] = {
      \ 'short': '^> ',
      \ 'long': '\v^\> [^ ]+\(\) ([^:]+):(\d+) .+$',
      \ 'index': [1, 2],
      \ }

" Breakpoint 2 set at 0x10f47db for main.main() ./a.go:14
let s:config['new_breakpoint_pattern'] = {
      \ 'short': '^Breakpoint \d\+ set at ',
      \ 'long': '\v^Breakpoint (\d+) set at .+\(\) ([^:]+):(\d+)$',
      \ 'index': [1, 2, 3],
      \ }

" Breakpoint 1 cleared at 0x10f47db for main.main() ./a.go:14
let s:config['del_breakpoint_pattern'] = {
      \ 'short': '^Breakpoint \d\+ cleared at ',
      \ 'long': '\v^Breakpoint (\d+) cleared at .+\(\) ([^:]+):(\d+)$',
      \ 'index': [1, 2, 3],
      \ }

func backend#dlv#Get()
  return s:config
endfunc

" vi:set sts=2 sw=2 et:
