" Plugin for distict between TAB and SPACE character
"
" Maintainer: JoungKyun.Kim <hostmaster@oops.org>
" Projects:   https://github.com/AnNyung/VIM_plugins
" Bug Report: https://github.com/AnNyung/VIM_plugins/issues
" Revision:   r2 2019/09/05
"
" INSTALL
"  Put tabdistinct.vim in vim plugin directory($VIM/vimfiles/plugin) or
"  your plugin directory(~/.vim/plugin).
"
" USAGE
"  on command mode, toggle with "_" key.

" Avoid reloading {{{
if exists('loaded_tab_distinct')
    finish
endif

let loaded_tab_distinct = 1
" }}}

map _ :call TabDistinct ()<cr>
let s:ToggleDistinct = 0

function! TabDistinct ()
    if !exists("g:syntax_on") || g:syntax_on == 0
        echo "Tab distinct: nothigng because of Syntax off"
        return 0
    endif

    if s:ToggleDistinct == 0
        hi SpecialKey ctermbg=blue guibg=blue ctermfg=blue guifg=blue
        set list listchars=tab:··
        let s:ToggleDistinct = 1
        echo "Tab distinct:tab bgcolor turun on"
    else
        set nolist
        let s:ToggleDistinct = 0
        echo "Tab distinct:tab bgcolor turun off"
    endif
endfunc

"
" Local variables:
" tab-width: 4
" c-basic-offset: 4
" indent-tabs-mode nil
" End:
" vim: filetype=vim si et sw=4 ts=4 sts=4 fdm=marker:
"
