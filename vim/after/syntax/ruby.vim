" Vim syntax file
" Language:    Ruby Yard
" Maintainer:  Bruno Michel <brmichel@free.fr>
" Last Change: Oct 14, 2008
" Version:     0.1
" URL:         http://yard.rubyforge.org/

syn match rubyYard contained containedin=rubyComment /@\(param\|yieldparam\|yield\|return\|deprecated\|raise\|see\|since\|version\|author\)/
syn match rubyYard contained containedin=rubyComment /==== .*$/

" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_lisp_syntax_inits")
  if version < 508
    let did_lisp_syntax_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  HiLink rubyYard       Keyword

  delcommand HiLink
endif
