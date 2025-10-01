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

let s:config = termdbg#backend#base#Get()
let s:config['prompt'] = 'ipdb> '
let s:config['prompt_pattern'] = '^ipdb>\|^ipdb>ipdb>'
let s:config['trim_ansi_escape'] = v:true
let s:config['next_cmd'] = 'next'
let s:config['step_cmd'] = 'step'
let s:config['finish_cmd'] = 'return'
let s:config['continue_cmd'] = 'continue'
let s:config['break_cmd'] = 'break'
let s:config['clear_cmd'] = 'clear'

let s:config['locate_pattern'] = {
      \ 'short': '^> ',
      \ 'long': '\v^\> (.+)\((\d+)\).*\(.*\).*$',
      \ 'index': [1, 2],
      \ }

let s:config['new_breakpoint_pattern'] = {
      \ 'short': '^Breakpoint \d\+ at ',
      \ 'long': '^Breakpoint \(\d\+\) at \(.\+\):\(\d\+\)',
      \ 'index': [1, 2, 3],
      \ }

let s:config['del_breakpoint_pattern'] = {
      \ 'short': '^Deleted breakpoint \d\+ at ',
      \ 'long': '^Deleted breakpoint \(\d\+\) at \(.\+\):\(\d\+\)',
      \ 'index': [1, 2, 3],
      \ }

func termdbg#backend#ipdb#Get()
  return s:config
endfunc

" vi:set sts=2 sw=2 et:
