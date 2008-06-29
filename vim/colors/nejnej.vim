" Vim color file
" Maintainer:	Bruno Michel <brmichel@free.fr>
" Last Change:	23/04/2006


set background=dark
hi clear
if exists("syntax_on")
  syntax reset
endif

let colors_name = "nejnej"

hi Comment      ctermfg=Blue
hi Constant     ctermfg=LightRed
hi DiffAdd      cterm=bold ctermbg=DarkBlue
hi DiffChange   ctermbg=Red
hi DiffDelete   ctermfg=Yellow ctermbg=Blue
hi DiffText     cterm=bold ctermbg=DarkRed
hi Directory    ctermfg=LightCyan
hi Error        cterm=bold ctermbg=DarkRed ctermfg=white
hi ErrorMsg     cterm=bold ctermbg=DarkRed ctermfg=White
hi Identifier   cterm=none ctermfg=Magenta
hi Ignore       ctermfg=Grey
hi IncSearch    ctermfg=Red
hi ModeMsg      cterm=bold
hi MoreMsg      ctermfg=LightGreen
hi NonText      ctermfg=LightBlue
hi Normal       ctermfg=Grey
hi PreProc      cterm=bold ctermfg=Green
hi Question     ctermfg=LightGreen
hi Search       ctermbg=Yellow ctermfg=Black
hi Special      cterm=bold ctermfg=LightRed
hi SpecialKey   ctermfg=LightBlue
hi Statement    cterm=bold ctermfg=Yellow
hi StatusLine   cterm=reverse,bold
hi StatusLineNC cterm=reverse
hi Title        cterm=bold ctermfg=LightRed
hi Todo         ctermbg=Red
hi Type         ctermfg=Green
hi Underlined   cterm=underline ctermfg=LightCyan
hi VertSplit    cterm=reverse
hi Visual       cterm=reverse
hi WarningMsg   ctermfg=LightRed
hi MatchParen   NONE
hi MatchParen   cterm=bold ctermfg=Green

