" Description:  Terminal debugger
" Maintainer:   fanhe <fanhed@163.com>
" License:      GPLv2
" Create:       2019-02-11
" Change:       2019-02-11
"
" NOTE:
"   - 只留一个窗口显示 WinBar，如果此窗口被关闭，则新建一个窗口再添加 WinBar

" In case this gets loaded twice.
if exists('s:loaded')
  finish
endif
let s:loaded = 1
let s:debug = v:false
"let s:debug = v:true

let s:job_id = 0
let s:ptybuf = 0
let s:dbgwin = 0
let s:config = {}

func! s:splitdrive(p)
  if a:p[1:1] ==# ':'
    return [a:p[0:1], a:p[2:]]
  endif
  return ['', a:p]
endfunc

func! s:isabs(s)
  if has('unix')
    return a:s =~# '^/'
  else
    let s = s:splitdrive(a:s)[1]
    return s !=# '' && s[0:0] =~# '/\|\\'
  endif
endfunc

func! s:GetCmdOutput(sCmd)
    let bak_lang = v:lang

    " 把消息统一为英文
    exec ":lan mes en_US.UTF-8"

    try
        redir => sOutput
        silent! exec a:sCmd
    catch
        " 把错误消息设置为最后的 ':' 后的字符串?
        "let v:errmsg = substitute(v:exception, '^[^:]\+:', '', '')
    finally
        redir END
    endtry

    exec ":lan mes " . bak_lang

    return sOutput
endfunc

let s:pc_id = 1002
let s:break_id = 1010
let s:winbar_winids = []
let s:cache_lines = []
" for debug
let termdbg#cache_lines = s:cache_lines
let s:prompt = '(Pdb) '
" {bpnr: {lnum: ..., file: ...}, ...}
let s:breakpoints = {}

hi default link TermdbgCursor Identifier
hi default link TermdbgBreak Special

function! s:InitVariable(var, value, ...)
  let force = a:0 > 0 ? a:1 : 0
  if force || !exists(a:var)
    if exists(a:var)
      unlet {a:var}
    endif
    let {a:var} = a:value
  endif
endfunction

" 启动时是否使用 shell
call s:InitVariable('g:termdbg_use_shell', 0)

" (bang, type, *argv)
function termdbg#StartDebug(bang, type, ...) abort
  if s:dbgwin > 0
    echoerr 'Terminal debugger is already running'
    return
  endif
  if !executable(a:1)
    echoerr 'command not found:' a:1
    return
  endif

  let s:startwin = win_getid(winnr())
  let s:startsigncolumn = &signcolumn

  let argv = copy(a:000)
  " 使用 shell 来运行调试器的话，可以避免一些奇怪问题，主要是环境变量问题
  if g:termdbg_use_shell
    let argv = [&shell, &shellcmdflag] + [join(map(argv, {idx, val -> shellescape(val)}), ' ')]
  endif

  if has('nvim')
    let callbacks = {
      \ 'on_stdout': function('s:on_event'),
      \ 'on_stderr': function('s:on_event'),
      \ 'on_exit': function('s:on_event')
      \ }
    new 'Terminal debugger'
    let s:ptybuf = bufnr('%')
    let s:job_id = termopen(argv, extend({}, callbacks))
  else
    let s:ptybuf = term_start(argv, {
          \ 'term_name': 'Terminal debugger',
          \ 'out_cb': function('termdbg#on_stdout'),
          \ 'err_cb': function('s:on_stderr'),
          \ 'exit_cb': function('s:on_exit'),
          \ 'term_finish': 'close',
          \ })
  endif
  let s:dbgwin = win_getid(winnr())

  call s:InstallCommands()
  call win_gotoid(s:startwin)
  stopinsert
  call s:InstallWinbar()

  " Sign used to highlight the line where the program has stopped.
  " There can be only one.
  sign define TermdbgCursor text==> linehl=CursorLine texthl=TermdbgCursor

  " Sign used to indicate a breakpoint.
  " Can be used multiple times.
  sign define TermdbgBreak text=o texthl=TermdbgBreak

  let type = a:type
  if type == ''
    " 直接取命令名称作为类型
    let type = fnamemodify(argv[0], ':t')
  endif

  if type ==# 'ipdb' || type ==# 'ipdb3'
    let config = backend#ipdb#Get()
  elseif type ==# 'pdb' || type ==# 'pdb3'
    let config = backend#pdb#Get()
  elseif type ==# 'dlv'
    let config = backend#dlv#Get()
  elseif type ==# 'lldb'
    let config = backend#lldb#Get()
  else
    echoerr 'unknown dbg type' type
    return
  endif

  let s:prompt = config['prompt']
  let s:config = config

  augroup Termdbg
    autocmd BufRead * call s:BufRead()
    autocmd BufUnload * call s:BufUnloaded()
  augroup END

  " 初始跳到调试窗口，以方便输入命令，然而，回调会重定位光标
  call win_gotoid(s:ptybuf)
endfunction

" 只要在终端窗口一定时间内（n毫秒）有连续的输出，就会进入此回调
" 不保证 msg 是一整行
" 因为绝大多数程序的标准输出是行缓冲的，所以一般情况下（手动输入除外），
" msg 是成整行的，可能是多个整行
" BUG: 虽然 msg 每次过来基本可以确定是整行的，但是行之间的顺序是不定的！
function termdbg#on_stdout(job_id, msg)
  "echomsg string(a:msg)
  if get(s:config, 'trim_ansi_escape')
    " 去除 ipdb 的转义字符
    let lines = split(s:TrimAnsiEscape(a:msg), "\r")
  else
    let lines = split(a:msg, "\r")
  endif

  for idx in range(len(lines))
    " 去除 "^\n"
    let lines[idx] = substitute(lines[idx], '^\n', '', '')
  endfor

  " 去除 ipdb 中多余的空行输出
  if get(s:config, 'trim_ansi_escape')
    call filter(lines, {idx, val -> val !~# '^\s\+$'})
    call filter(lines, '!empty(v:val)')
  endif

  call extend(s:cache_lines, lines)
  if len(s:cache_lines) > 100
    call filter(s:cache_lines, {idx, val -> idx >= len(s:cache_lines) - 100})
  endif

  " 无脑逐行匹配动作！
  for line in reverse(lines)
    call s:dbg(line)
    if line =~# s:config.locate_pattern.short
      " 光标定位
      if !termdbg#LocateCursor(line)
        execute 'sign unplace' s:pc_id
      endif
    elseif line =~# s:config.new_breakpoint_pattern.short
      call s:HandleNewBreakpoint(line)
    elseif !empty(s:config.del_breakpoint_pattern.short) && line =~# s:config.del_breakpoint_pattern.short
      call s:HandleDelBreakpoint(line)
    endif
  endfor
endfunction

" Breakpoint 1 at /Users/eph/a.py:16
func s:HandleNewBreakpoint(msg)
  let matches = matchlist(a:msg, s:config.new_breakpoint_pattern.long)
  call s:dbg(matches)
  let nr = get(matches, 1, 0)
  let file = get(matches, 2, '')
  let lnum = get(matches, 3, 0)
  if nr == 0 || empty(file) || lnum == 0
    return
  endif

  if has_key(s:breakpoints, nr)
    let entry = s:breakpoints[nr]
  else
    let entry = {}
    let s:breakpoints[nr] = entry
  endif
  let entry['file'] = fnamemodify(file, ':p') " 转为绝对路径
  let entry['lnum'] = lnum

  if bufloaded(file)
    call s:PlaceSign(nr, entry)
  endif
endfunc

" Deleted breakpoint 1 at /Users/eph/a.py:16
func s:HandleDelBreakpoint(msg)
  if empty(s:config.del_breakpoint_pattern.short)
    return
  endif
  let matches = matchlist(a:msg, s:config.del_breakpoint_pattern.long)
  call s:dbg(matches)
  let bpnr = get(matches, 1, 0)
  "let file = get(matches, 2, '')
  "let lnum = get(matches, 3, 0)
  if bpnr == 0
    return
  endif
  if has_key(s:breakpoints, bpnr)
    let entry = s:breakpoints[bpnr]
    if get(entry, 'placed', 0)
      execute 'sign unplace' (s:break_id + bpnr)
      let entry['placed'] = 0
    endif
    unlet s:breakpoints[bpnr]
  endif
endfunc

func s:PlaceSign(bpnr, entry)
  exe 'sign place ' . (s:break_id + a:bpnr) . ' line=' . a:entry['lnum'] . ' name=TermdbgBreak file=' . a:entry['file']
  let a:entry['placed'] = 1
endfunc

func s:on_event(job_id, data, event) dict abort
  if a:event == 'stdout'
    call termdbg#on_stdout(a:job_id, join(a:data, "\n"))
  elseif a:event == 'stderr'
    call s:on_stderr(a:job_id, join(a:data, "\n"))
  else " 'exit'
    call s:on_exit(a:job_id, a:data)
  endif
endfunc

function s:on_stderr(job_id, data)
endfunction

function s:on_exit(job_id, status)
  execute 'bwipe!' s:ptybuf
  let s:ptybuf = 0
  let s:dbgwin = 0
  call filter(s:cache_lines, 0)

  let curwinid = win_getid(winnr())

  if win_gotoid(s:startwin)
    let &signcolumn = s:startsigncolumn
  endif

  call s:DeleteCommands()
  call s:DeleteWinbar()
  execute 'sign unplace' s:pc_id
  for key in keys(s:breakpoints)
    exe 'sign unplace ' . (s:break_id + key)
  endfor

  sign undefine TermdbgCursor
  sign undefine TermdbgBreak
  call filter(s:breakpoints, 0)

  autocmd! Termdbg
endfunction

function s:getbufmaxline(bufnr)
  if has('nvim')
    return nvim_buf_line_count(a:bufnr)
  else
    return pyxeval('len(vim.buffers['.(a:bufnr).'])')
  endif
endfunction

func s:GotoStartwinOrCreateIt()
  if !win_gotoid(s:startwin)
    new
    let s:startwin = win_getid(winnr())
    call s:InstallWinbar()
  endif
endfunc

" Install the window toolbar in the current window.
func s:InstallWinbar()
  if !has('nvim') && has('menu') && &mouse != ''
    nnoremenu <silent> WinBar.Break  :call <SID>ToggleBreak()<CR>
    nnoremenu <silent> WinBar.Next   :TNext<CR>
    nnoremenu <silent> WinBar.Step   :TStep<CR>
    nnoremenu <silent> WinBar.Finish :TFinish<CR>
    nnoremenu <silent> WinBar.Contin :TContinue<CR>
    nnoremenu <silent> WinBar.Locate :TLocateCursor<CR>
    call add(s:winbar_winids, win_getid(winnr()))
  endif
endfunc

function s:TermdbgNext()
  call s:SendCommand(s:config['next_cmd'])
endfunction

function s:TermdbgStep()
  call s:SendCommand(s:config['step_cmd'])
endfunction

function s:TermdbgFinish()
  call s:SendCommand(s:config['finish_cmd'])
endfunction

function s:TermdbgContinue()
  call s:SendCommand(s:config['continue_cmd'])
endfunction

" 返回 0 表示定位失败，否则表示定位成功
func termdbg#LocateCursor(msg)
  if a:msg !~# s:config.locate_pattern.short
    return 0
  endif

  let wid = win_getid(winnr())

  let pattern = s:config.locate_pattern.long
  let matches = matchlist(a:msg, pattern)
  call s:dbg(matches)
  let fname = ''
  if len(matches) >= 3
    let fname = matches[s:config.locate_pattern.index[0]]
    if filereadable(fname)
      let lnum = str2nr(matches[s:config.locate_pattern.index[1]])
    endif
  endif
  "if empty(fname) || !s:isabs(fname)
  if empty(fname)
    return 0
  endif
  if !bufexists(fname) && !filereadable(fname)
    echoerr fname 'not found'
    return 0
  endif

  call s:GotoStartwinOrCreateIt()

  " 如果调试窗口的编辑的文件不是正在调试的文件，则切换为正在调试的文件
  if expand('%:p') != fnamemodify(fname, ':p')
    " 如果此窗口的文件已经修改，就分隔一个窗口来显示调试文件
    if &modified
      " TODO: find existing window
      execute 'split' fnameescape(fname)
      let s:startwin = win_getid(winnr())
      call s:InstallWinbar()
    else
      execute 'edit' fnameescape(fname)
    endif
  endif

  " 定位调试行
  execute lnum
  execute 'sign unplace' s:pc_id
  execute printf('sign place %s line=%d name=TermdbgCursor file=%s', s:pc_id, lnum, fname)
  "setlocal signcolumn=yes

  call win_gotoid(wid)

  return 1
endfunc

function s:LocateCursor()
  if s:ptybuf <= 0
    return
  endif
  let maxlnum = s:getbufmaxline(s:ptybuf)
  let min = 1
  let pdb_cnt = 0
  for lnum in range(maxlnum, min, -1)
    let line = getbufline(s:ptybuf, lnum)[0]
    if line ==# s:prompt
      let pdb_cnt += 1
      "if pdb_cnt >= 2
        "break
      "endif
    endif
    if line !~# s:config.locate_pattern.short
      continue
    endif
    if !termdbg#LocateCursor(line)
      execute 'sign unplace' s:pc_id
    endif
    break
  endfor
endfunction

func s:InstallCommands()
  command TNext call s:TermdbgNext()
  command TStep call s:TermdbgStep()
  command TFinish call s:TermdbgFinish()
  command TContinue call s:TermdbgContinue()
  command TLocateCursor call s:LocateCursor()
  command TBreakpoint call s:SetBreakpoint()
  command TClearBreak call termdbg#ClearBreakpoint()
  command TToggleBreak call s:ToggleBreak()
  command -nargs=1 TSendCommand call s:SendCommand(<q-args>)
endfunc

func s:DeleteCommands()
  delcommand TNext
  delcommand TStep
  delcommand TFinish
  delcommand TContinue
  delcommand TLocateCursor
  delcommand TBreakpoint
  delcommand TClearBreak
  delcommand TToggleBreak
  delcommand TSendCommand
endfunc

func s:DeleteWinbar()
  let curwinid = win_getid(winnr())
  for winid in s:winbar_winids
    if win_gotoid(winid)
      aunmenu WinBar.Next
      aunmenu WinBar.Step
      aunmenu WinBar.Finish
      aunmenu WinBar.Contin
      aunmenu WinBar.Break
      aunmenu WinBar.Locate
    endif
  endfor
  call win_gotoid(curwinid)
  let s:winbar_winids = []
endfunc

func s:SendCommand(cmd)
  if has('nvim')
    if s:job_id > 0
      call jobsend(s:job_id, "\<C-u>")
      call jobsend(s:job_id, a:cmd . "\r")
    endif
  else
    call term_sendkeys(s:ptybuf, "\<C-u>")
    call term_sendkeys(s:ptybuf, a:cmd . "\r")
  endif
endfunc

func s:TrimAnsiEscape(msg)
  let pat = '\C\v(%x9B|%x1B\[)[0-?]*[ -/]*[@-~]'
  return substitute(a:msg, pat, '', 'g')
endfunc

func s:SetBreakpoint()
  call s:SendCommand(printf('%s %s:%d', s:config.break_cmd, fnameescape(expand('%:p')), line('.')))
endfunc

func termdbg#ClearBreakpoint()
  let file = fnameescape(expand('%:p'))
  let lnum = line('.')
  for [bpid, entry] in items(s:breakpoints)
    if entry['file'] ==# file && entry['lnum'] == lnum
      call s:SendCommand(printf('%s %s', s:config.clear_cmd, bpid))
      " lldb 无法使用兜底的确认机制, 这里就直接删除
      if empty(s:config.del_breakpoint_pattern.short)
        if get(entry, 'placed', 0)
          execute 'sign unplace' (s:break_id + bpid)
          let entry['placed'] = 0
        endif
        unlet s:breakpoints[bpid]
      endif
      break
    endif
  endfor
endfunc

" 仅列出当前缓冲区的标号
func termdbg#sign_getplaced() abort
  let result = []
  let li = split(s:GetCmdOutput('sign place buffer=' . bufnr('%')), "\n")
  for line in li[2:]
    let fields = split(line)
    " vim 8.1 之后，增加了 priority 字段，所以分隔后，字段数可能为 4
    if len(fields) < 3
      continue
    endif
    let entry = {}
    for field in fields
      let ret = matchlist(field, '\(^\w\+\)=\(.\+\)$')
      let key = ret[1]
      let val = ret[2]
      if key ==# 'line' || key ==# 'id' || key ==# 'priority'
        let entry[key] = str2nr(val)
      else
        let entry[key] = val
      endif
    endfor
    " 输出的是 line，后面标准化的时候是 lnum
    let entry['lnum'] = get(entry, 'line', 0)
    call add(result, entry)
  endfor
  return result
endfunc

func s:ToggleBreak()
  " --- Signs ---
  " Signs for /Users/eph/a.py:
  "     line=3  id=1002  name=TermdbgCursor
  "     line=9  id=1004  name=TermdbgBreak
  "     line=16  id=1007  name=TermdbgBreak
  "     line=16  id=1006  name=TermdbgBreak
  "     line=16  id=1005  name=TermdbgBreak
  let found = 0
  let li = termdbg#sign_getplaced()
  for entry in li
    if get(entry, 'name') ==# 'TermdbgBreak' && get(entry, 'lnum', 0) is line('.')
      let found = 1
      break
    endif
  endfor
  if found
    call termdbg#ClearBreakpoint()
  else
    call s:SetBreakpoint()
  endif
endfunc

function termdbg#SendCommand(cmd)
  call s:SendCommand(a:cmd)
endfunction

" Handle a BufRead autocommand event: place any signs.
func s:BufRead()
  let file = expand('<afile>:p')
  for [bpnr, entry] in items(s:breakpoints)
    if entry['file'] ==# file
      call s:PlaceSign(bpnr, entry)
    endif
  endfor
endfunc

" Handle a BufUnloaded autocommand event: unplace any signs.
func s:BufUnloaded()
  let file = expand('<afile>:p')
  for [bpnr, entry] in items(s:breakpoints)
    if entry['file'] == file
      let entry['placed'] = 0
    endif
  endfor
endfunc

func s:dbg(...)
  if !s:debug
    return
  endif
  let li = copy(a:000)
  let li = map(li, {_, j -> string(j)})
  echomsg join(li, ' ')
endfunc

" vi:set sts=2 sw=2 et:
