" Usage: cd /path/to/this/plugin; vim -u misc/vimrc.vim
if &compatible
  set nocompatible
endif

execute 'set runtimepath+=' . expand('<sfile>:h:h')

set buftype=nofile noswapfile noundofile
set expandtab smarttab shiftwidth=2

nnoremap q <C-w>q

call backpair#enable()
call backpair#add_pair('(', ')')
