" Plugin for make folding that support AnNyung LInux
"
" Maintainer: JoungKyun.Kim <http://oops.org>
" Projects:   https://github.com/AnNyung/VIM_plugins
" Bug Report: https://github.com/AnNyung/VIM_plugins/issues
" Last Change: r2 2016/12/24
"
" INSTALL
"  1. Put annyungfolding.vim in your plugin directory (~/.vim/plugin)
"  2. If you don't want to this function set follow configuration
"     on your vimrc file
"
"       let g:annyungfolding=0
"
"  USAGE
"    Press the '+' key on the function declaration line or curly braces to
"    fold it on command mode.
"
"  MORE INFORMATION
"       This supports c/cpp/php/perl using filetype global variable.
"
"  This script is tested with Vim version >= 6.3 on windows and linux.


" Avoid reloading {{{
if exists('loaded_annyung_folding')
    finish
endif

let loaded_annyung_folding = 1
" }}}

map + :call AnNyungFolding ()<cr>

let s:curNo   = 0
let s:lineEnd = 0
let s:moveup  = 0
let s:foldtext = ''
let s:ftype    = ''
let s:foldmark = ''

let s:startNo = 0
let s:endNo   = 0

let s:phpdeclare = '\s*\(var\|public\|protected\|private\|static\)*\s*\(function\|class\)\s\c'
let s:perldeclare = '^\s*sub\s\+[a-z_][a-z0-9_]\+\c'
let s:cppclass   = 'class\s\+[a-z0-9:_ ]\+\s\?'
let s:cdeclare   = '\s*\([a-z_]\+\(\s*\*\)\?\s\+[a-z_][a-z0-9_]*\(::[a-z_][a-z0-9_]*\)\?\s*(\|' . s:cppclass . '\)\c'
let s:cdeclare_s = '\s*\([a-z_]\+\(\s*\*\)\?\s\+[a-z_][a-z0-9_]*\(::[a-z_][a-z0-9_]*\)\?\s*\|' . s:cppclass . '\)\c'
let s:ckeyword   = '\s*\(char\|const\|double\|enum\|extern\|float\|int\|long\|register\|short\|signed\|static\|unsigned\|void\|public\|private\|protected\)\s\+\c'
let s:conditions = '\(if\|switch\|for\|while\|do\)\c'

if !exists('g:annyungfolding')
    let g:annyungfolding=1
endif

function! AnNyungFolding ()
    if g:annyungfolding == 0
        normal j
        return 0
    endif

    " make folder mark format to '// [{]{{, // [}]}}'
    set commentstring=\ //\ %s
    let s:curNo = line ('.')
    let s:lineEnd = line ('$')
    let s:foldtext = ''

    if &filetype == 'php'
        let s:matches = s:phpdeclare
        let s:foldmark = '//'
    elseif &filetype == 'perl'
        let s:matches = s:perldeclare
        let s:foldmark = '#'
    elseif &filetype == 'c' || &filetype == 'cpp'
        let s:matches = s:cdeclare
        let s:foldmark = '//'
    else
        normal j
        return 0
    endif

    " 현재 위치에 fold가 있으면 접고 종료한다.
    if s:alreadyFolding (getline ('.')) == 0
        return 0
    endif

    " get current line
    let l:line = s:getLine(".")

    " function 라인에 barce가 존재하지 않을 경우 처리
    if l:line =~ '^\s*\(function\|if\|switch\|for\|while\|do\|else\)\s*\c' || (l:line =~ s:cdeclare_s && l:line =~ s:ckeyword && l:line !~ '^\s*\(//\|\*\)')
        let l:loop = 0
        while l:loop != 10
            let l:line = s:getLine (s:curNo + l:loop)

            if l:line =~ '{\s*$'
                let s:curNo += l:loop
                exec s:curNo
                break
            endif

            let l:loop += 1
        endwhile
    endif

    if l:line !~ '{\s*$' && l:line !~ '};\?\s*$'
        return 1
    endif

    if l:line =~ '{\s*$'
        let l:startNo = s:curNo
        let s:endNo   = s:getOppositeBrace ()
    else
        let s:endNo   = s:curNo
        let l:startNo = s:getOppositeBrace ()
    endif

    let l:brline  = l:startNo
    let l:startNo = s:functionDeclare (l:startNo)
    let s:startNo = s:conditionDeclare (l:startNo)

    " case that is not function or condition decalre
    if s:startNo == l:brline
        let l:cmt = s:CheckComments (l:brline - 1)
        let s:startNo = l:cmt == -1 ? l:brline : l:cmt
    endif

    " 현재 위치에 fold가 있으면 접고 종료한다.
    if s:alreadyFolding (getline (s:startNo)) == 0
        return 0
    endif

    "echo s:startNo
    "echo s:endNo
    call s:setStartMark ()
    call s:setEndMark ()
    call s:foldingFold ()

    return 0
endfunc

" {{{ +-- function! s:foldingFold()
"
" 처음의 위치로 이동한 후에, 폴딩을 실행한다.
"
function! s:foldingFold()
    " avoid conflict phpfolding
    set foldmethod=marker
    exec s:curNo
    normal zc
    " avoid conflict phpfolding
    if exists("g:DisableAutoPHPFolding")
        if &filetype == "php" && ! g:DisableAutoPHPFolding
            call g:EnablePHPFolds()
        endif
    endif
endfunc
" }}}

" {{{ +-- function! s:setFoldText ()
"
" function/class 선언을 찾아서 foldtext로 설정하고
" 주석에서 @return 문자열을 찾으면, 자료형을 추가한다.
"
function! s:setFoldText ()
    let l:lineno  = s:startNo
    let l:returns = ''

    while l:lineno < s:endNo
        let l:line  = getline (l:lineno)
        let l:cline = s:getLine (l:lineno)

        if l:line =~ s:matches && l:line !~ '^\s*\(//\|\*\)'
            let s:foldtext = substitute (l:cline, '^\s*\|\s*{.*', '', 'g')
            if &filetype == 'php' && s:foldtext =~ '^function'
                let s:foldtext = 'public ' . s:foldtext
            endif
            break
        endif

        if &filetype == 'c' || &filetype == 'cpp'
            if l:line =~ s:ckeyword . '[a-z0-9_]\+\(\[\]\)\?\s*=\c' && l:line !~ '^\s*\(//\|\*\)'
                let s:foldtext = substitute (l:cline, '^\s*\|\s*=.*', '', 'g')
            endif
        endif

        if l:line =~ '\*\s* @return\s'
            let l:returns = substitute (l:line, '.*@return\s*\c', '', 'g')
            let l:returns = substitute (l:returns, '\s.*', '', 'g')
        elseif l:cline =~ '^\s*\(if\|for\|foreach\|while\)\s*(\c'
            let s:foldtext = substitute (l:cline, '^\s*\|\s*{.*', '', 'g')
            break
        endif

        let l:lineno += 1
    endwhile

    if l:returns == ''
        let s:foldtext = substitute (s:foldtext, 'function\s\c', '', 'g')
    else
        let l:returns = '(' . l:returns . ') '
        let s:foldtext = substitute (s:foldtext, 'function\s\c', l:returns, 'g')
    endif

    let s:foldtext = substitute (s:foldtext, '()', '(void)', 'g')
endfunc
" }}}

" {{{ +-- function! s:setStartMark ()
function! s:setStartMark ()
    let s:moveup = 0
    let l:lineno = s:startNo

    " move start block
    exec s:startNo

    while l:lineno > 0
        let l:line = s:getLine (l:lineno)

        "
        " 공백 라인이나 brace만 존재하는 라인, 또는 조건문 라인은 현재
        " 라인에서 폴딩을 시작한다.
        "
        if l:line =~ '^\s*[{}]\{0,1}\s*$' || l:line =~ '^\s*\(if\|for\|foreach\|while\|do\)\s*(\c'
            let l:line = getline (l:lineno)
            " 현재 라인이 foldtext를 품고 있을 경우 loop를 멈춘다
            if l:line !~ '^\s*\(/\*\|//\|#\)\s*'
                break
            endif
        endif

        "
        "현재 라인이 function/class 선언일 경우 윗줄에서 폴딩을
        "시작을 선언하며, foldtext를 지정한 후 loop를 멈춘다.
        "
        let l:line = s:getLine (l:lineno)
        if l:line =~ s:matches && l:line !~ '^\s*\(//\|\*\)'
            let s:moveup = 1
            call s:setFoldText ()
            break
        endif

        " 현재 라인이 /* 스타일의 주석 시작일 경우 윗 라인에서
        " 폴딩을 선언한다.
        if s:moveup != 1
            let l:line = getline (l:lineno)
            if l:line =~ '^\s*\(/\*\|//\|#\)\s*'
                let s:moveup = 1
                call s:setFoldText ()
                break
            endif
        endif

        let l:lineno -= 1
    endwhile

    if s:moveup != 0
        let l:line = getline (s:startNo - 1)
        if l:line !~ '/\(/\|\*\|#\) [{]\{3}'
            exec 'normal! O' . s:foldmark . ' {{' . '{ +-- ' . s:foldtext
            let s:curNo += 1
            let s:endNo += 1
        endif
    else
        let l:line = getline ('.')
        if l:line !~ '/\(/\|\*\|#\) [{]\{3}'
            exec 'normal! $a ' . s:foldmark . ' {{' . '{'
        endif
    endif
endfunc
" }}}

" {{{ +-- function! s:setEndMark ()
function! s:setEndMark ()
    exec s:endNo
    if s:moveup != 0
        let l:line = getline (s:endNo + 1)
        if l:line !~ '\(//\|#\) [}]\{3}'
            exec 'normal! o' . s:foldmark . ' }}' . '}'
        endif
    else
        let l:line = getline ('.')
        if l:line !~ '\(//\|#\) [}]\{3}'
            exec 'normal! $a ' . s:foldmark . ' }}' . '}'
        endif
    endif
endfunc
" }}}


" {{{ +-- function! s:alreadyFolding ()
function! s:alreadyFolding (line)
    if a:line =~ '\(//\|/\*\|#\)\s*[{]\{3}' || a:line =~ '\(//\|/\*\|#\)\s*[}]\{3}'
        exe "normal! zc"
        return 0
    endif

    return 1
endfunc
" }}}

" {{{ +-- function! getOppositeBrace ()
function! s:getOppositeBrace ()
    normal 0
    :call search ('[{}]\s*\(/[/\*].*\)*\s*$', '', line ('.'))
    normal %
    let l:lineno = line ('.')
    normal %

    return l:lineno
endfunc
" }}}

" +-- function! s:getLine (line) {{{
function! s:getLine (lineno)
    let l:line = substitute (getline (a:lineno), '\(\/\/\|/[*]\).*', '', 'g')
    let l:line = substitute (l:line, '{[^}]*}', '', 'g')

    return l:line
endfunc
" }}}

" {{{ +-- function! s:CheckComments (line)
function! s:CheckComments (lineno)
    if a:lineno == 1
        return -1
    endif

    let l:lineno = a:lineno
    let l:line = getline (l:lineno)

    if l:line =~ '\*/\s*$'
        " C style 주석
        let l:commentstyle = 'c'
    elseif l:line =~ '^\s*//\s*'
        " C++ style 주석
        let l:commentstyle = 'cpp'
    elseif l:line =~ '^\s*#\s*'
        if &filetype != 'perl' && &filetype != 'php'
            return l:lineno + 1
        endif
        let l:commentstyle = '#'
    else
        " C/C++ 주석 형식이 아니면 function/class declare line
        " 을 시작줄로 반환
        return l:lineno + 1
    endif

    while l:lineno > 2
        let l:lineno -= 1
        let l:line = getline (l:lineno)

        if l:commentstyle == 'c'
            " /* 구문이 나오면 주석이 시작되는 지점이며, 이 위치를
            " 시작 위치로 반환
            if l:line =~ '^\s*/\*'
                return l:lineno
            endif
        elseif l:commentstyle == 'cpp'
            " C++ sytle에서는 시작이 //로 되지 않으면 주석 시작
            " 이전 시점으로 판단하여 이전 라인을 시작 위치로 반환
            if l:line !~ '^\s*//'
                return l:lineno + 1
            endif
        else
            " perl sytle에서는 시작이 #로 되지 않으면 주석 시작
            " 이전 시점으로 판단하여 이전 라인을 시작 위치로 반환
            if l:line !~ '^\s*#'
                return l:lineno + 1
            endif
        endif
    endwhile

    return -1
endfunc
" }}}

" {{{ *** Function Declare check ***
"
" {{{ +-- function! s:functionDeclare (lineno)
function! s:functionDeclare (lineno)
    if a:lineno < 1
        return a:lineno
    endif

    if s:getLine (a:lineno) =~ '^\s*\(if\|switch\|for\|while\|do\|function\)\c'
        return a:lineno
    elseif s:getLine (a:lineno) =~ '^\s*{\s*$'
        if s:getLine (a:lineno - 1) =~ '^\s*\(if\|switch\|for\|while\|do\|function\)\c'
            return a:lineno - 1
        endif
    endif

    if &filetype == 'php'
        return s:phpFunctionDeclare (a:lineno)
    elseif &filetype == 'c' || &filetype == 'cpp'
        return s:cFunctionDeclare (a:lineno)
    elseif &filetype == 'perl'
        return s:perlFunctionDeclare (a:lineno)
    endif

    return a:lineno
endfunc
" }}}

" {{{ +-- function! s:phpFunctionDeclare (lineno)
function! s:phpFunctionDeclare (lineno)
    let l:lineno = a:lineno

    " 현재 라인이 '{' 문자로 시작할 경우 윗라인이 function/class 선언인지 확인
    if s:getLine (l:lineno) =~ '\(^\|)\)\s*{'
        if s:getLine (l:lineno - 1) =~ s:phpdeclare
            let l:lineno -= 1
        endif
    endif

    " 현재 라인이 '(' 문자로 시작할 경우 윗라인이 function 선언인지 확인
    if s:getLine (l:lineno) =~ '^\s*('
        if s:getLine (l:lineno - 1) =~ '^\s*\(var\|public\|protected\|private\|static\)*\s*function\c'
            let l:lineno -= 1
        endif
    endif

    if s:getLine (l:lineno) =~ ')\s*{'
        let l:limit = 10
        let l:lno   = 1
        while l:limit > 0
            let l:line = s:getLine (l:lineno - l:lno)

            if l:line =~ '^\s*\(if\|switch\|for\|while\|do\)\c' || l:line =~ '^\s*$'
                break
            endif

            if l:line =~ '^\s*\(var\|public\|protected\|private\|static\)*\s*function\c'
                let l:lineno -= l:lno
                break
            endif
            let l:limit -= 1
            let l:lno   += 1
        endwhile
    endif

    if (s:getLine (l:lineno) =~ ')\s*$' && s:getLine (l:lineno + 1) =~ '^\s*{') || (s:getLine (l:lineno) =~ '^\s*{' && s:getLine (l:lineno - 1) =~ ')\s*$')
        let l:limit = 10
        let l:lno   = 1
        while l:limit > 0
            let l:line = s:getLine (l:lineno - l:lno)

            if l:line =~ '^\s*\(if\|switch\|for\|while\|do\)\c' || l:line =~ '^\s*$'
                break
            endif

            if l:line =~ '^\s*\(var\|public\|protected\|private\|static\)*\s*function\c'
                let l:lineno -= l:lno
                break
            endif
            let l:limit -= 1
            let l:lno   += 1
        endwhile
    endif

    " 현재 라인이 class keyword 일 경우 아래 라인이 function/class 인지 확인
    if s:getLine (l:lineno) =~ '^\s\(protected\|private\|public\|var\|static\)\s*$\c'
        if s:getLine (l:lineno + 1) =~ '^\s*\(function\|class\)\c'
            let l:lineno += 1
        endif
    endif

    let l:line = s:getLine (l:lineno)
    if l:line =~ '^\s*\(var\|public\|protected\|private\|static\)*\s*\(function\|class\)\c'
        let l:lineno -= 1

        " 함수 정의 윗줄에 class keyword가 있으면 처리
        let l:line = s:getLine (l:lineno)
        if l:line =~ '^\s*\(public\|protected\|private\|var\|static\)\s*$\c'
            let l:lineno -= 1
        endif

        let l:cmt = s:CheckComments (l:lineno)
        return l:cmt == -1 ? l:lineno : l:cmt
    endif

    return l:lineno
endfunc
" }}}

" {{{ +-- function! s:perlFunctionDeclare (lineno)
function! s:perlFunctionDeclare (lineno)
    let l:lineno = a:lineno

    " 현재 라인이 '{' 문자로 시작할 경우 윗라인이 function/class 선언인지 확인
    if s:getLine (l:lineno) =~ '\(^\|)\)\s*{'
        if s:getLine (l:lineno - 1) =~ s:perldeclare
            let l:lineno -= 1
        endif
    endif

    " 현재 라인이 '(' 문자로 시작할 경우 윗라인이 function 선언인지 확인
    " void test
    "        (blah, blah) {
    if s:getLine (l:lineno) =~ '^\s*('
        let l:line = s:getLine (l:lineno - 1)
        if l:line =~ s:perldeclare
            let l:lineno -= 1
        endif
    endif

    if s:getLine (l:lineno) =~ ')\s*{'
        let l:limit = 10
        let l:lno   = 1
        while l:limit > 0
            let l:line = s:getLine (l:lineno - l:lno)

            if l:line =~ '^\s*\(if\|switch\|for\|while\|do\)\c' || l:line =~ '^\s*$'
                break
            endif

            if l:line =~ s:perldeclare
                let l:lineno -= l:lno
                break
            endif
            let l:limit -= 1
            let l:lno   += 1
        endwhile
    endif

    if (s:getLine (l:lineno) =~ ')\s*$' && s:getLine (l:lineno + 1) =~ '^\s*{') || (s:getLine (l:lineno) =~ '^\s*{' && s:getLine (l:lineno - 1) =~ ')\s*$')
        let l:limit = 10
        let l:lno   = 1
        while l:limit > 0
            let l:line = s:getLine (l:lineno - l:lno)

            if l:line =~ '^\s*\(if\|switch\|for\|while\|do\)\c' || l:line =~ '^\s*$'
                break
            endif

            if l:line =~ s:perldeclare
                let l:lineno -= l:lno
                break
            endif
            let l:limit -= 1
            let l:lno   += 1
        endwhile
    endif

    let l:line = s:getLine (l:lineno)
    if l:line =~ s:matches && l:line !~ '^\s*\(//\|\*\)'
        let l:cmt = s:CheckComments (l:lineno - 1)
        return l:cmt == -1 ? l:lineno : l:cmt
    endif

    return l:lineno
endfunc
" }}}

" {{{ +-- function! s:cFunctionDeclare (lineno)
function! s:cFunctionDeclare (lineno)
    let l:lineno = a:lineno

    " 현재 라인이 '{' 문자로 시작할 경우 윗라인이 function/class 선언인지 확인
    if s:getLine (l:lineno) =~ '\(^\|)\)\s*{'
        if s:getLine (l:lineno - 1) =~ s:cdeclare_s
            let l:lineno -= 1
        endif
    endif

    " 현재 라인이 '(' 문자로 시작할 경우 윗라인이 function 선언인지 확인
    " void test
    "        (blah, blah) {
    if s:getLine (l:lineno) =~ '^\s*('
        let l:line = s:getLine (l:lineno - 1)
        if l:line =~ s:cdeclare_s && l:line =~ s:ckeyword
            let l:lineno -= 1
        endif
    endif

    if s:getLine (l:lineno) =~ ')\s*{'
        let l:limit = 10
        let l:lno   = 1
        while l:limit > 0
            let l:line = s:getLine (l:lineno - l:lno)

            if l:line =~ '^\s*\(if\|switch\|for\|while\|do\)\c' || l:line =~ '^\s*$'
                break
            endif

            if l:line =~ s:cdeclare_s && l:line =~ s:ckeyword && l:line !~ '^\s*\(//\|\*\)'
                let l:lineno -= l:lno
                break
            endif
            let l:limit -= 1
            let l:lno   += 1
        endwhile
    endif

    if (s:getLine (l:lineno) =~ ')\s*$' && s:getLine (l:lineno + 1) =~ '^\s*{') || (s:getLine (l:lineno) =~ '^\s*{' && s:getLine (l:lineno - 1) =~ ')\s*$')
        let l:limit = 10
        let l:lno   = 1
        while l:limit > 0
            let l:line = s:getLine (l:lineno - l:lno)

            if l:line =~ '^\s*\(if\|switch\|for\|while\|do\)\c' || l:line =~ '^\s*$'
                break
            endif

            if l:line =~ s:cdeclare_s && l:line =~ s:ckeyword && l:line !~ '^\s*\(//\|\*\)'
                let l:lineno -= l:lno
                break
            endif
            let l:limit -= 1
            let l:lno   += 1
        endwhile
    endif

    let l:line = s:getLine (l:lineno)
    if l:line =~ s:matches && l:line !~ '^\s*\(//\|\*\)'
        let l:cmt = s:CheckComments (l:lineno - 1)
        return l:cmt == -1 ? l:lineno : l:cmt
    endif

    return l:lineno
endfunc
" }}}

" }}}

" {{{ +-- function! s:conditionDeclare (lineno)
function! s:conditionDeclare (lineno)
    if a:lineno < 1
        return a:lineno
    endif

    let l:lineno = a:lineno
    let l:line = s:getLine (l:lineno)

    " 현재 라인이 function / class 조건이면 종료
    if l:line =~ s:matches && l:line !~ '^\s*\(//\|\*\)'
        return l:lineno
    endif

    " 현재 라인이 조건문인지 확인
    if s:getLine (l:lineno) =~ '^\s*\(if\|switch\|for\|while\|do\)\c'
        let l:cmt = s:CheckComments (l:lineno - 1)
        return l:cmt == -1 ? l:lineno : l:cmt
    endif


    " 현재 라인이 '{' 문자로 시작할 경우 윗라인이 조건문인지 확인
    if s:getLine (l:lineno) =~ '\(^\|)\)\s*{'
        if s:getLine (l:lineno - 1) =~ '^\s*\(if\|switch\|for\|while\|do\)\c'
            let l:cmt = s:CheckComments (l:lineno - 2)
            return l:cmt == -1 ? l:lineno - 1 : l:cmt
        endif
    endif

    " 현재 라인이 '(' 문자로 시작할 경우 윗라인이 조건문인지 확인
    if s:getLine (l:lineno) =~ '^\s*('
        if s:getLine (l:lineno - 1) =~ '^\s*\(if\|switch\|for\|while\|do\)\c'
            let l:lineno -= 1
        endif
    endif

    if s:getLine (l:lineno) =~ ')\s*{'
        let l:limit = 10
        let l:lno   = 1
        while l:limit > 0
            if s:getLine (l:lineno - l:lno) =~ '^\s*\(if\|switch\|for\|while\|do\)\c'
                let l:lineno -= l:lno
                break
            endif
            let l:limit -= 1
            let l:lno   += 1
        endwhile
    endif

    if (s:getLine (l:lineno) =~ ')\s*$' && s:getLine (l:lineno + 1) =~ '^\s*{') || (s:getLine (l:lineno) =~ '^\s*{' && s:getLine (l:lineno - 1) =~ ')\s*$')
        let l:limit = 10
        let l:lno   = 1
        while l:limit > 0
            if s:getLine (l:lineno - l:lno) =~ '^\s*\(if\|switch\|for\|while\|do\)\c'
                let l:lineno -= l:lno
                break
            endif
            let l:limit -= 1
            let l:lno   += 1
        endwhile
    endif

    " 현재 라인이 조건문인지 확인
    if s:getLine (l:lineno) =~ '^\s*\(if\|switch\|for\|while\|do\)\c'
        let l:cmt = s:CheckComments (l:lineno - 1)
        return l:cmt == -1 ? l:lineno : l:cmt
    endif

    return a:lineno
endfunc
"}}}

" Local variables:
" tab-width: 4
" c-basic-offset: 4
" indent-tabs-mode nil
" End:
" vim: set filetype=vim et sw=4 ts=4 sts=4 fdm=marker:
" vim600: et sw=4 ts=4 sts=4 fdm=marker
" vim<600: et sw=4 ts=4 sts=4
