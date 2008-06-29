" Vim color file
" Maintainer:	Bruno Michel <brmichel@free.fr>
" Last Change:	2004 Sept 6

set background=dark
hi clear
if exists("syntax_on")
  syntax reset
endif

let colors_name = "atmos"

highlight Comment     term=bold ctermfg=5 
highlight Constant    term=underline ctermfg=6 
highlight Delimiter   term=bold cterm=bold ctermfg=1 
highlight Directory   term=bold ctermfg=DarkBlue 
highlight Error       term=standout cterm=bold ctermbg=1 ctermfg=1 
highlight ErrorMsg    term=standout cterm=bold ctermfg=1 
highlight Identifier  term=underline ctermfg=3 
highlight LineNr      term=underline cterm=bold ctermfg=3 
highlight ModeMsg     term=bold cterm=bold ctermfg=3 ctermbg=1 
highlight MoreMsg     term=bold cterm=bold ctermfg=2 
highlight NonText     term=bold ctermfg=2 
highlight Normal      ctermfg=white ctermbg=black 
highlight Normal      ctermfg=white 
highlight PreProc     term=underline ctermfg=14 
highlight Question    term=standout cterm=bold ctermfg=2 
highlight Search      term=reverse ctermbg=2 
highlight Special     term=bold ctermfg=5 
highlight SpecialKey  term=bold ctermfg=DarkBlue 
highlight Statement   term=bold ctermfg=2 
highlight StatusLine  term=reverse cterm=bold ctermfg=3 ctermbg=4 
highlight StatusLineNC term=bold ctermfg=3 ctermbg=2 
highlight Title       term=bold cterm=bold ctermfg=4 
highlight Todo        term=underline ctermfg=red ctermbg=yellow 
highlight Type        term=underline cterm=bold ctermfg=3 
highlight Visual      term=reverse cterm=bold ctermfg=6 ctermbg=5 
highlight WarningMsg  term=standout cterm=bold ctermfg=1 ctermbg=4 

