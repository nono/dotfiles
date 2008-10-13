" Vim syntax file
" Language:    Merb Mailer
" Maintainer:  Bruno Michel <brmichel@free.fr>
" Last Change: Oct 14, 2008
" Version:     0.1
" URL:         http://www.merbivore.com/

if exists("b:current_syntax") && b:current_syntax =~ "merb_mailer"
  finish
endif


syn case match

syn keyword mrUrl           absolute_url relative_url url
syn keyword mrRender        render_mail attach


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

  HiLink mrUrl              Keyword
  HiLink mrRender           Keyword

  delcommand HiLink
endif


let b:current_syntax = 'ruby.merb_mailer'
