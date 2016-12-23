TabDistinct Plugins
===

## 1. ABSTRACT

Distinction between tab and space character.

## 2. INSTALLATION

Download tabdistinct.vim file and save it in $VIM/vimfiles/plugin or ~/.vim/plugin

## 3. Usage

You can toggle with the "_" key. When ***TabDistinct*** is on, the tab is displayed in blue.

If you want to change the toggle key from the "\_" key to another key, find the next line in the source code and change the "_" character to another character:

```vim
map _ :call TabDistinct ()<cr>
```

## 4. Support

Only tested on VIM 7.
