Folding Plugins
===

## 1. ABSTRACT

Folding about function and class and any {} block.

## 2. INSTALLATION

Download annyungfolding.vim file and save it in $VIM/vimfiles/plugin or ~/.vim/plugin

## 3. Usage

Press the '+' key on the function declaration line or curly braces to fold it on command mode.

If you want to change the toggle key from the "+" key to another key, find the next line in the source code and change the "+" character to another character:

```vim
map + :call AnNyungFolding ()<cr>
```

If you don't want to this function set follow configuration on your vimrc file

```vim
let g:annyungfolding=0
```



