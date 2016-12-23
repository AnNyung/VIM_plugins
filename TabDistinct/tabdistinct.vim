" Plugin for distict between TAB and SPACE character
"
" Maintainer: JoungKyun.Kim <http://annyung.oops.org>
" Revision:   r1 2016/12/23
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
		syn match Tab "\t"
		hi def Tab guifg=blue ctermbg=blue
		let s:ToggleDistinct = 1
		echo "Tab distinct:tab bgcolor turun on"
	else
		syn off
		syn on
		let s:ToggleDistinct = 0
		echo "Tab distinct:tab bgcolor turun off"
	endif
endfunc
