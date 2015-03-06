setlocal cindent noet sw=8 ts=8 tw=78

" Give the :Man command
runtime ftplugin/man.vim
nmap K :Man <cword><CR>

inorea <buffer> #d #define
inorea <buffer> #I #include <><Left>
inorea <buffer> #i #include ""<Left>
inorea <buffer> #n #ifndef NDEBUG
inorea <buffer> #e #endif
inorea <buffer> /** /**<CR>/<Up>
