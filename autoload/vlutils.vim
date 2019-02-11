" Description:  Common function utilities
" Maintainer:   fanhe <fanhed@163.com>
" License:      GPLv2
" Create:       2011-07-15
" Last Change:  2011-07-15

if exists('s:loaded')
    finish
endif
let s:loaded = 1

" NOTE:
" 除非指定 g: 来访问全局变量，否则在autoload的其他脚本无法直接调用此脚本的符号
" 而plugin的脚本无此限制

" 初始化
function! vlutils#Init() "{{{2
    return 0
endfunction
"}}}2
" 初始化变量, 仅在没有变量定义时才赋值
" Param1: sVarName - 变量名, 必须是可作为标识符的字符串
" Param2: defaultVal - 默认值, 可为任何类型
" Return: 0 表示赋值为默认, 否则为 1
function! vlutils#InitVariable(sVarName, defaultVal) "{{{2
    if exists(a:sVarName)
        return 1
    endif
    "let {a:sVarName} = a:defaultVal
    exec "let" a:sVarName "=" string(a:defaultVal)
    return 0
endfunction
"}}}
" 与 exec 命令相同，但是运行时 set eventignore=all
" 主要用于“安全”地运行某些命令，例如窗口跳转
" TODO: 这个名字太容易混淆了，迟早要干掉
function! vlutils#Exec(sCmd) "{{{2
    exec 'noautocmd' a:sCmd
endfunction
"}}}
" argv 为列表，类似于c的main函数的argv，如['ls', '-lh', '/home']
" envd 为字典，作为环境变量
" 这个命令一般只在Linux下面用
function! vlutils#RunCmd(argv, envd) "{{{2
    let sCmd = ''

    " 环境变量字符串，只在Linux下才处理
    if vlutils#IsWindowsOS()
        let sCmd .= '!'
    else
        let sEnv = ''
        for [k, v] in items(a:envd)
            let sEnv .= printf("export %s=%s; ", k, shellescape(v, 1))
        endfor
        let sCmd .= '!' . sEnv
    endif

    for arg in a:argv
        let sCmd .= shellescape(arg, 1) . ' '
    endfor

    exec sCmd
endfunction
"}}}
" 与 exec 命令类似，但是运行时 set eventignore=all
" 主要用于“安全”地运行某些命令，例如窗口跳转
function! vlutils#ExecNoau(sCmd) "{{{2
    exec 'noautocmd' a:sCmd
endfunction
"}}}
" 把路径分割符替换为 posix 的 '/'
function! vlutils#PosixPath(sPath) "{{{2
    if vlutils#IsWindowsOS()
        return substitute(a:sPath, '\', '/', 'g')
    else
        return a:sPath
    endif
endfunction
"}}}
" 打开指定缓冲区的窗口数目
function! vlutils#BufInWinCount(nBufNr) "{{{2
    let nCount = 0
    let nWinNr = 1
    while 1
        let nWinBufNr = winbufnr(nWinNr)
        if nWinBufNr < 0
            break
        endif
        if nWinBufNr ==# a:nBufNr
            let nCount += 1
        endif
        let nWinNr += 1
    endwhile

    return nCount
endfunction
"}}}
" 判断窗口是否可用
" 可用 - 即可用其他窗口替换本窗口而不会令本窗口的内容消失
function! vlutils#IsWindowUsable(nWinNr) "{{{2
    let nWinNr = a:nWinNr
	" 特殊窗口，如特殊缓冲类型的窗口、预览窗口
    let bIsSpecialWindow = getwinvar(nWinNr, '&buftype') !=# ''
                \|| getwinvar(nWinNr, '&previewwindow')
    if bIsSpecialWindow
        return 0
    endif

	" 窗口缓冲是否已修改
    let bModified = getwinvar(nWinNr, '&modified')

	" 如果可允许隐藏，则无论缓冲是否修改
    if &hidden
        return 1
    endif

	" 如果缓冲区没有修改，或者，已修改，但是同时有其他窗口打开着，则表示可用
	if !bModified || vlutils#BufInWinCount(winbufnr(nWinNr)) >= 2
		return 1
	else
		return 0
	endif
endfunction
"}}}
" 获取第一个"可用"(常规, 非特殊)的窗口
" 特殊: 特殊的缓冲区类型、预览缓冲区、已修改的缓冲并且不能隐藏
" Return: 窗口编号 - -1 表示没有可用的窗口
function! vlutils#GetFirstUsableWinNr() "{{{2
    let i = 1
    while i <= winnr("$")
		if vlutils#IsWindowUsable(i)
			return i
		endif

        let i += 1
    endwhile
    return -1
endfunction
"}}}
" 获取宽度最大的窗口编号
function! vlutils#GetMaxWidthWinNr() "{{{2
	let i = 1
	let nResult = 0
	let nMaxWidth = 0
	while i <= winnr("$")
		let nCurWidth = winwidth(i)
		if nCurWidth > nMaxWidth
			let nMaxWidth = nCurWidth
			let nResult = i
		endif
		let i += 1
	endwhile

	return nResult
endfunction
"}}}
" 获取高度最大的窗口编号
function! vlutils#GetMaxHeightWinNr() "{{{2
	let i = 1
	let nResult = 0
	let nMaxHeight = 0
	while i <= winnr("$")
		let nCurHeight = winheight(i)
		if nCurHeight > nMaxHeight
			let nMaxHeight = nCurHeight
			let nResult = i
		endif
		let i += 1
	endwhile

	return nResult
endfunction
"}}}
" '优雅地'打开一个文件, 在需要的时候会分割窗口
" 水平分割和垂直分割的具体方式由 'splitbelow' 和 'splitright' 选项控制
" vlutils#OpenFile... 系列函数的分割都是这样控制的
" 只有一个窗口时会垂直分割窗口, 否则是水平分割
" 规则:
" 1. 需要打开的文件已经在某个窗口打开, 跳至那个窗口, 结束
" 2. 如果上一个窗口(wincmd p)可用, 用此窗口打开文件, 结束
" 3. 如果没有可用的窗口, 且窗口数为 1, 垂直分割打开
" 4. 如果没有可用的窗口, 且窗口数多于 1, 跳至宽度最大的窗口水平分割打开
function! vlutils#OpenFile(sFile, ...) "{{{2
    let sFile = a:sFile
    if sFile ==# ''
        return
    endif

    let bKeepCursorPos = 0
    if a:0 > 0
        let bKeepCursorPos = a:1
    endif

    " 跳回原始窗口的算法
    " 1. 先保存此窗口的编号, 再保存此窗口对应的缓冲的编号
    " 2. 打开文件后, 检查保存的窗口是否对应原来的缓冲编号, 如果对应, 跳回,
    "    否则, 继续算法
    " 3. 查找到对应保存的缓冲编号的窗口, 若返回有效编号, 跳回, 否则, 不操作
    let nBackWinNr = winnr()
    let nBackBufNr = bufnr('%')

    let nBufWinNr = bufwinnr('^' . sFile . '$')
    if nBufWinNr != -1
        " 文件已经在某个窗口中打开, 直接跳至那个窗口
        exec nBufWinNr 'wincmd w'
    else
        " 文件没有在某个窗口中打开
        let nPrevWinNr = winnr('#')
        if !vlutils#IsWindowUsable(nPrevWinNr)
            if vlutils#GetFirstUsableWinNr() == -1
                " 上一个窗口不可用并且没有可用的窗口, 需要分割窗口
                if winnr('$') == 1
                    " 窗口总数为 1, 垂直分割
                    " TODO: 分割方式应该可控制...
                    exec 'vsplit' fnameescape(sFile)
                else
                    "有多个窗口, 找一个宽度最大的窗口然后水平分割窗口
                    let nMaxWidthWinNr = vlutils#GetMaxWidthWinNr()
                    call vlutils#ExecNoau(nMaxWidthWinNr . 'wincmd w')
                    exec 'split' fnameescape(sFile)
                endif
            else
                call vlutils#ExecNoau(vlutils#GetFirstUsableWinNr() . "wincmd w")
                exec 'edit' fnameescape(sFile)
            endif
        else
            call vlutils#ExecNoau('wincmd p')
            exec 'edit' fnameescape(sFile)
        endif
    endif

    if bKeepCursorPos
        if winbufnr(nBackWinNr) == nBackBufNr
            " NOTE: 是否必要排除自动命令?
            call vlutils#ExecNoau(nBackWinNr . 'wincmd w')
        elseif bufwinnr(nBackBufNr) != -1
            call vlutils#ExecNoau(bufwinnr(nBackBufNr) . 'wincmd w')
        else
            " 不操作
        endif
    endif
endfunction
"}}}
" 在新的标签页中打开文件
" OptParam: 默认 0, 1 表示不切换到新标签那里, 即保持光标在原始位置
function! vlutils#OpenFileInNewTab(sFile, ...) "{{{2
    let sFile = a:sFile
    if sFile ==# ''
        return
    endif

    let bKeepCursorPos = 0
    if a:0 > 0
        let bKeepCursorPos = a:1
    endif

    let nCurTabNr = tabpagenr()

    exec 'tabedit' fnameescape(sFile)

    if bKeepCursorPos
        " 跳回原来的标签
        " 为什么用 ':tabnext' 也可以? 理应用 ':tab'
        exec 'tabnext' nCurTabNr
    endif
endfunction
"}}}
" '优雅地'水平分割打开文件
function! vlutils#OpenFileSplit(sFile, ...) "{{{2
    let sFile = a:sFile
    if sFile ==# ''
        return
    endif

    let bKeepCursorPos = 0
    if a:0 > 0
        let bKeepCursorPos = a:1
    endif

    let nBackWinNr = winnr()
    let nBackBufNr = bufnr('%')

    " 跳到宽度最大的窗口再水平分割
    call vlutils#ExecNoau(vlutils#GetMaxWidthWinNr() . 'wincmd w')
    exec 'split' fnameescape(sFile)

    if bKeepCursorPos
        if winbufnr(nBackWinNr) == nBackBufNr
            " NOTE: 是否必要排除自动命令?
            call vlutils#ExecNoau(nBackWinNr . 'wincmd w')
        elseif bufwinnr(nBackBufNr) != -1
            call vlutils#ExecNoau(bufwinnr(nBackBufNr) . 'wincmd w')
        else
            " 不操作
        endif
    endif
endfunction
"}}}
" '优雅地'垂直分割打开文件
function! vlutils#OpenFileVSplit(sFile, ...) "{{{2
    let sFile = a:sFile
    if sFile ==# ''
        return
    endif

    let bKeepCursorPos = 0
    if a:0 > 0
        let bKeepCursorPos = a:1
    endif

    let nBackWinNr = winnr()
    let nBackBufNr = bufnr('%')

    " 跳到宽度最大的窗口再水平分割
    call vlutils#ExecNoau(vlutils#GetMaxHeightWinNr() . 'wincmd w')
    exec 'vsplit' fnameescape(sFile)

    if bKeepCursorPos
        if winbufnr(nBackWinNr) == nBackBufNr
            " NOTE: 是否必要排除自动命令?
            call vlutils#ExecNoau(nBackWinNr . 'wincmd w')
        elseif bufwinnr(nBackBufNr) != -1
            call vlutils#ExecNoau(bufwinnr(nBackBufNr) . 'wincmd w')
        else
            " 不操作
        endif
    endif
endfunction
"}}}
" 生成带编号菜单选择列表
" NOTE: 第一项(即li[0])不会添加编号
function! vlutils#GenerateMenuList(li) "{{{2
    let li = a:li
    let nLen = len(li)
    let lResult = []

    if nLen > 0
        call add(lResult, li[0])
        let l = len(string(nLen -1))
        let n = 1
        for str in li[1:]
            call add(lResult, printf('%*d. %s', l, n, str))
            let n += 1
        endfor
    endif

    return lResult
endfunction
"}}}
" 获取选择的文本，从 mark 插件复制过来的...
function! vlutils#GetVisualSelection() "{{{2
	let save_clipboard = &clipboard
	set clipboard= " Avoid clobbering the selection and clipboard registers.
	let save_reg = getreg('"')
	let save_regmode = getregtype('"')
	silent normal! gvy
	let res = getreg('"')
	call setreg('"', save_reg, save_regmode)
	let &clipboard = save_clipboard
	return res
endfunction
"}}}
" 是否在 Windows 平台
function! vlutils#IsWindowsOS() "{{{2
    return has('win32') || has('win64') || has('win32unix')
endfunction
"}}}
function! vlutils#EchoWarnMsg(msg) "{{{2
    if empty(a:msg)
        return ''
    endif
    echohl WarningMsg
    for sLine in split(a:msg, '\n')
        echomsg sLine
    endfor
    "echomsg '!!!Catch an exception!!!'
    echohl None
    return ''
endfunction
"}}}
" 供clientserver调用, 只是添加一行提示信息而已
function! vlutils#EchoMsgx(msg) "{{{2
    let extramsg = "\nThere are some warning messages! Please run ':messages' for details."
    return vlutils#EchoWarnMsg(a:msg . extramsg)
endfunction
function! vlutils#EchoErrMsg(msg) "{{{2
    if empty(a:msg)
        return ''
    endif
    echohl ErrorMsg
    for sLine in split(a:msg, '\n')
        echomsg sLine
    endfor
    "echomsg '!!!Catch an exception!!!'
    echohl None
    return ''
endfunction
"}}}
" 支持重复input的接口
function! vlutils#Inputs(prompt, ...) "{{{2
    let sPrompt = a:prompt
    let sText = get(a:000, 0, '')
    let sCompletion = get(a:000, 1, '')
    let lResult = []
    " 第一次
    let sInput = input(sPrompt, sText, sCompletion)
    if empty(sInput)
        return []
    endif
    call add(lResult, sInput)

    while 1
        let sInput = input("\nContinue to input...\n".sPrompt, sText, sCompletion)
        if empty(sInput)
            break
        endif
        call add(lResult, sInput)
    endwhile

    let sAnswer = input('Do you wish to commit all your input? (y/n): ', 'y')
    if sAnswer !~? '^y'
        " 不提交的话直接清空
        let lResult = []
    endif

    return lResult
endfunction
"}}}
" 进度条函数，arg1 - 当前进度，[arg2] - 总体进度
function vlutils#Progress(n, ...) "{{{2
    let n = a:n
    let m = get(a:000, 0, 100)

    let nRange = 10
    let nRatio = n * nRange / m

    echoh Pmenu
    echon repeat(' ', nRatio)
    echoh None
    echon repeat(' ', nRange - nRatio)
    echon printf("%4d%%", n * 100 / m)
    redraw
    return ''
endfunction
"}}}
" 添加 cscope 数据库的动作，统一 cs add 动作，用于处理缺陷
function! vlutils#CscopeAdd(file, ...) "{{{2
    let file = a:file
    let prepath = get(a:000, 0, '')
    let flags = get(a:000, 1, '')

    if empty(file)
        return -1
    endif

    if file =~# '\s'
        " fallback
        let relfile = fnamemodify(file, ':.')
        if relfile =~# '\s'
            let msg = printf('Cscope can not support this file path: %s', file)
            call vlutils#EchoWarnMsg(msg)
            return -1
        endif
        let file = relfile
    endif

    if prepath =~# '\s'
        let msg = printf('Cscope can not support this pre-path: %s',
                \        prepath)
        call vlutils#EchoWarnMsg(msg)
        return -1
    endif

    exec 'silent! cs kill' fnameescape(file)

    let cmd = printf('cs add %s', fnameescape(file))
    if !empty(prepath)
        let cmd .= ' ' . fnameescape(prepath)
    endif
    if !empty(flags)
        let cmd .= ' ' . flags
    endif
    exec cmd
endfunction
"}}}
" 用于保存vim选项，最终用于恢复
" 参数支持两种方式传入，(['a', 'b']) 或 ('a', 'b')
function! vlutils#SaveVimOptions(...) "{{{2
    let opts = a:000
    let length = len(a:000)
    if length == 1 && type(get(a:000, 0)) == type([])
        let opts = get(a:000, 0)
    endif

    let dict = {}
    for opt in opts
        exec 'let val = &' . opt
        let dict[opt] = val
    endfor
    return dict
endfunction
"}}}
function! vlutils#RestoreVimOptions(optdict) "{{{2
    for [key, val] in items(a:optdict)
        if type(val) == type('')
            " 字符串型
            let cmd = printf("let &%s = '%s'",
                    \        key, substitute(val, "'", "''", "g"))
        else
            " 数值和布尔型
            let cmd = printf('let &%s = %d', key, val)
        endif
        exec cmd
    endfor
endfunction
"}}}
" 供 vimdialog 使用的一个共用回调函数，一般情况下请不要使用
" eg. call ctl.ConnectButtonCallback(function('vlutils#EditTextBtnCbk'), &ft)
function! vlutils#EditTextBtnCbk(ctl, data) "{{{2
    let ft = a:data " data 需要设置的文件类型
    let editDialog = g:VimDialog.New('Edit', a:ctl.owner)
    let content = a:ctl.GetValue()
    call editDialog.SetIsPopup(1)
    call editDialog.SetAsTextCtrl(1)
    call editDialog.SetTextContent(content)
    call editDialog.ConnectSaveCallback(function('vlutils#EditTextSaveCbk'),
            \                           a:ctl)
    call editDialog.Display()
    if ft !=# ''
        let &filetype = ft
    endif
endfunction
"}}}
" 配合 vlutils#EditTextBtnCbk() 使用
function! vlutils#EditTextSaveCbk(dlg, data) "{{{2
    let textsList = getline(1, '$')
    call filter(textsList, 'v:val !~ "^\\s\\+$\\|^$"')
    call a:data.SetValue(textsList)
    call a:data.owner.RefreshCtl(a:data)
endfunction
"}}}
function! vlutils#GetCmdOutput(sCmd) "{{{2
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
endfunction
"}}}
" 扩展的位置获取的恢复函数，尽量准确的恢复光标到原来的位置
function! vlutils#GetPos(expr) "{{{2
    let lPos = getpos(a:expr)
    let pos = {}
    let pos.orgbuf = bufnr('%')
    let pos.bufnum = lPos[0]
    let pos.lnum = lPos[1]
    let pos.col = lPos[2]
    let pos.off = lPos[3]
    let pos.winnum = winnr()
    let pos.wincnt = winnr('$')
    return pos
endfunction
"}}}
function! vlutils#SetPos(expr, pos) "{{{2
    let pos = a:pos
    let lPos = [pos.bufnum, pos.lnum, pos.col, pos.off]
    " 1. 先跳回原来的窗口
    if !(pos.wincnt == winnr('$') && winnr() == pos.winnum)
    " 窗口增减或者光标跳动过
        if pos.winnum > winnr('$')
            " 原来的窗口已经关闭...，不知道怎么继续，返回错误
            return -1
        endif
        let nWinNr = pos.winnum
        " 如果窗口变动过，那么优先使用 bufwinnr() 的结果
        if pos.wincnt != winnr('$')
            let nTmp = bufwinnr(pos.orgbuf)
            if nTmp != -1
                let nWinNr = nTmp
            endif
        endif
        call vlutils#ExecNoau(nWinNr . 'wincmd w')
    endif

    " 2. 再切换到原来的缓冲区
    if bufnr('%') != pos.orgbuf
        " 切到指定的缓冲区
        try
            exec 'b' pos.orgbuf
        catch
            if bJmpWin
                call vlutils#ExecNoau('wincmd p')
            endif
            return -1
        endtry
    endif
    " 3. 最后恢复到原来的光标的位置
    return setpos(a:expr, lPos)
endfunction
"}}}
" NOTE: 已经处理了多字节字符
function! vlutils#ExpandTabs(str, tabsize) "{{{2
    let str = a:str
    let tabsize = a:tabsize
    let out = ''
    let j = 0
    let idx = 0
    for charidx in range(strchars(str))
        let byteidx = byteidx(str, charidx + 1)
        if byteidx == -1
            let char = str[idx : -1]
        else
            let char = str[idx : byteidx-1]
        endif
        if char ==# "\t"
            " 补上必要的空白
            if tabsize > 0
                let pads = tabsize - (j % tabsize)
                let out .= repeat(' ', pads)
                let j += pads
            endif
        else
            let out .= char
            let j += strwidth(char)
            if char ==# "\n" || char ==# "\r"
                let j = 0
            endif
        endif
        let idx = byteidx
    endfor
    return out
endfunction
"}}}
" linux 内核通知链的 vim 版本
let vlutils#Notifier = {}
let vlutils#Notifier.DONE = 0
let vlutils#Notifier.OK = 1
let vlutils#Notifier.BAD = 2
let vlutils#Notifier.STOP = 4
" ... -> data = 0
function! vlutils#Notifier.New(name, ...) "{{{2
    let inst = copy(self)
    let inst.name = a:name
    let inst.data = get(a:000, 0, 0)
    " {'callback': callback, 'priority': priority, 'private': private}
    let inst.callbacks = []
    return inst
endfunction
"}}}
" ... -> private = 0
function! vlutils#Notifier.Register(callback, priority, ...) "{{{2
    let d = {}
    let d['callback'] =
            \ type(a:callback) == type('') ? function(a:callback) : a:callback
    let d['priority'] = a:priority
    let d['private'] = get(a:000, 0, 0)
    let idx = 0
    for item in self.callbacks
        if a:priority > item['priority']
            let idx += 1
            break
        endif
        let idx += 1
    endfor
    call insert(self.callbacks, d, idx)
    return 0
endfunction
"}}}
function! vlutils#Notifier.Unregister(callback, priority) "{{{2
    " 回调函数变量的首字母必须是大写...
    let Cbk = a:callback
    if type(Cbk) == type('')
        unlet Cbk
        let Cbk = function(a:callback)
    endif
    let idx = 0
    for item in self.callbacks
        if item['callback'] is Cbk && item['priority'] == a:priority
            call remove(self.callbacks, idx)
            return 0
        endif
        let idx += 1
    endfor
    return -1
endfunction
"}}}
" ... -> data = 0, nr_to_call = -1
function! vlutils#Notifier.CallChain(val, ...) "{{{2
    let ret = self.DONE
    let nr_call = 0
    let data = get(a:000, 0, 0)
    let nr_to_call = get(a:000, 1, -1)
    if empty(data)
        unlet data
        let data = self.data
    endif

    for item in self.callbacks
        if !nr_to_call
            break
        endif

        let priv = item['private']
        let ret = item['callback'](a:val, data, priv)
        let nr_call += 1

        if ret == self.BAD || ret == self.STOP
            break
        endif
        let nr_to_call -= 1
    endfor
    return ret
endfunction
"}}}
" 简单的计时器静态类
let s:TimerData = {'t1': 0, 't2': 0} "{{{1
function! vlutils#TimerStart() "{{{2
	let s:TimerData.t1 = reltime()
endfunction

function! vlutils#TimerEnd() "{{{2
	let s:TimerData.t2 = reltime()
endfunction

function! vlutils#TimerEchoMes() "{{{2
	echom printf("%f", ((str2float(reltimestr(s:TimerData.t2)) 
				\- str2float(reltimestr(s:TimerData.t1)))))
endfunction

function! vlutils#TimerGetDelta() "{{{2
	return (str2float(reltimestr(s:TimerData.t2))
            \ - str2float(reltimestr(s:TimerData.t1)))
endfunction

function! vlutils#TimerEndEcho() "{{{2
	call vlutils#TimerEnd()
	call vlutils#TimerEchoMes()
endfunction
"}}}1
" 分割 sep 作为分割符的字符串为列表，双倍的 sep 代表 sep 自身
function! vlutils#SplitSmclStr(s) "{{{2
    let s = a:s
    let sep = ';'
    let idx = 0
    let result = []
    let l = len(s)
    let tmps = ''
    while idx < l
        let char = s[idx]
        if char ==# sep
            " 检查随后的是否为自身
            if idx + 1 < l
                if s[idx+1] ==# sep
                    let tmps .= sep
                    let idx += 1
                else
                    if !empty(tmps)
                        call add(result, tmps)
                    endif
                    let tmps = ''
                endif
            else
                " 最后的字符为分隔符，直接忽略
            endif
        else
            let tmps .= char
        endif
        let idx += 1
    endwhile

    if tmps !=# ''
        call add(result, tmps)
    endif
    let tmps = ''

    return result
endfunction
"}}}
" 串联字符串列表为 sep 分割的字符串，sep 用双倍的 sep 来表示
function! vlutils#JoinToSmclStr(li) "{{{2
    let li = a:li
    let sep = ';'
    let tempList = []
    for elm in li
        if !empty(elm)
            call add(tempList, substitute(elm, sep, sep.sep, 'g'))
        endif
    endfor
    return join(tempList, sep)
endfunction
"}}}
" 模拟 python 的 os 和 os.path 模块
" os, os.path {{{2
let s:os = {}

" posixpath 类 {{{1
let s:posixpath = {}
let s:posixpath.curdir = '.'
let s:posixpath.pardir = '..'
let s:posixpath.extsep = '.'
let s:posixpath.sep = '/'
let s:posixpath.pathsep = ':'
let s:posixpath.defpath = ':/bin:/usr/bin'
let s:posixpath.altsep = ''
let s:posixpath.devnull = '/dev/null'

function! s:posixpath.dirname(s) "{{{2
    return fnamemodify(a:s, ':h')
endfunction

function! s:posixpath.normcase(s) "{{{2
    return a:s
endfunction

function! s:posixpath.isabs(s) "{{{2
    return a:s =~# '^/'
endfunction

function! s:posixpath.join(a, ...) "{{{2
    let path = a:a
    for b in a:000
        if b =~# '^/'
            let path = b
        elseif path ==# '' || path =~# '/$'
            let path .= b
        else
            let path .= '/' . b
        endif
    endfor
    return path
endfunction

" ntpath 类 {{{1
let s:ntpath = {}
let s:ntpath.curdir = '.'
let s:ntpath.pardir = '..'
let s:ntpath.extsep = '.'
let s:ntpath.sep = '\'
let s:ntpath.pathsep = ';'
let s:ntpath.defpath = '.:C:\bin'
let s:ntpath.altsep = '/'
let s:ntpath.devnull = 'nul'

function! s:ntpath.dirname(s) "{{{2
    return fnamemodify(a:s, ':h')
endfunction

function! s:ntpath.normcase(s) "{{{2
    return tolower(substitute(a:s, '/', '\', 'g'))
endfunction

function! s:ntpath.splitdrive(p) "{{{2
    if a:p[1:1] ==# ':'
        return [a:p[0:1], a:p[2:]]
    endif
    return ['', a:p]
endfunction

function! s:ntpath.isabs(s) "{{{2
    let s = s:ntpath.splitdrive(a:s)[1]
    return s !=# '' && s[0:0] =~# '/\|\\'
endfunction

function! s:ntpath.join(a, ...) "{{{2
    let path = a:a
    let p = a:000
    for b in p
        let b_wins = 0 " set to 1 iff b makes path irrelevant
        if path ==# ''
            let b_wins = 1
        elseif s:ntpath.isabs(b)
            " This probably wipes out path so far.  However, it's more
            " complicated if path begins with a drive letter:
            "     1. join('c:', '/a') == 'c:/a'
            "     2. join('c:/', '/a') == 'c:/a'
            " But
            "     3. join('c:/a', '/b') == '/b'
            "     4. join('c:', 'd:/') = 'd:/'
            "     5. join('c:/', 'd:/') = 'd:/'
            if path[1:1] !=# ':' || b[1:1] ==# ':'
                " Path doesn't start with a drive letter, or cases 4 and 5.
                let b_wins = 1
            " Else path has a drive letter, and b doesn't but is absolute.
            elseif len(path) > 3 || (len(path) == 3 && path[-1:-1] !~# '/\|\\')
                " case 3
                let b_wins = 1
            endif
        endif

        if b_wins
            let path = b
        else
            " Join, and ensure there's a separator.
            if empty(path) | throw 'Invalid path string' | endif
            if path[-1:-1] =~# '/\|\\'
                if !empty(b) && b[0] =~# '/\|\\'
                    let path .= b[1:]
                else
                    let path .= b
                endif
            elseif path[-1:-1] ==# ':'
                let path .= b
            elseif !empty(b)
                if b[0] =~# '/\|\\'
                    let path .= b
                else
                    let path .= '\' . b
                endif
            else
                " path is not empty and does not end with a backslash,
                " but b is empty; since, e.g., split('a/') produces
                " ('a', ''), it's best if join() adds a backslash in
                " this case.
                let path .= '\'
            endif
        endif
    endfor

    return path
endfunction

"{{{1
if vlutils#IsWindowsOS()
    let s:os.name = 'nt'
    let s:os.path = s:ntpath
else
    let s:os.name = 'posix'
    let s:os.path = s:posixpath
endif

let s:os.curdir = s:os.path.curdir
let s:os.pardir = s:os.path.pardir
let s:os.sep = s:os.path.sep
let s:os.pathsep = s:os.path.pathsep
let s:os.defpath = s:os.path.defpath
let s:os.extsep = s:os.path.extsep
let s:os.altsep = s:os.path.altsep

function! s:os.path.basename(p) "{{{2
    return fnamemodify(a:p, ':t')
endfunction
"}}}
function! s:os.path.dirname(p) "{{{2
    return fnamemodify(a:p, ':h')
endfunction
"}}}
function! s:os.path.extname(p) "{{{2
    return fnamemodify(a:p, ':e')
endfunction
"}}}
function! s:os.path.splitext(p) "{{{2
    let ext = fnamemodify(a:p, ':e')
    let r = fnamemodify(a:p, ':r')
    return [r, self.extsep . ext]
endfunction
"}}}

" 导出全局变量
let g:vlutils#os = s:os
let g:vlutils#posixpath = s:posixpath
let g:vlutils#ntpath = s:ntpath
" 这个变量在函数中无论如何都用不了的，没办法，只能用上面那个变量
"let vlutils#os = os
"}}}1

" vim:fdm=marker:fen:fdl=1:et:ts=4:sw=4:sts=4:
