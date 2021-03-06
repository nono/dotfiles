" Vim filetype plugin
" Language:    Elixir
" Maintainer:  Carlos Galdino <carloshsgaldino@gmail.com>
" URL:         https://github.com/elixir-lang/vim-elixir

if (exists("b:did_ftplugin"))
  finish
endif
let b:did_ftplugin = 1

setlocal comments=:#
setlocal commentstring=#\ %s
setlocal sw=2 ts=2 et iskeyword+=!,?

nnoremap <silent> K :call LanguageClient#textDocument_hover()<CR>
nnoremap <silent> gd :call LanguageClient#textDocument_definition()<CR>
