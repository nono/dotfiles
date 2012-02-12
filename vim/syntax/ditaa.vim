" Ditaa syntax
" Language:    Ditaa
" Maintainer:  Bruno Michel <brmichel@free.fr>
" Last Change: Feb 12th, 2012
" Version:	   0.1
" URL:         https://github.com/nono/dotfiles

syn keyword    ditaaVArrow     V
syn match      ditaaColors     / c[0-9a-f]\{3\} /
syn keyword    ditaaColors     cRED cBLU cGRE CPNK cBLK CYEL
syn keyword    ditaaBullets    o
syn match      ditaaTag        /{\(d\|s\|io\)}/
syn match      ditaaText       /[^{}/\\+\-=|*:^<> ]\+/

hi def link    ditaaVArrow     Normal
hi def link    ditaaColors     Keyword
hi def link    ditaaBullets    Operator
hi def link    ditaaTag        Special
hi def link    ditaaText       Identifier

let b:current_syntax = 'ditaa'
