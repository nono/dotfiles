" Vim syntax file
" Language:    Merb View
" Maintainer:  Bruno Michel <brmichel@free.fr>
" Last Change: Oct 12, 2008
" Version:     0.1
" URL:         http://www.merbivore.com/

if exists("b:current_syntax") && b:current_syntax =~ "merb_view"
  finish
endif


syn cluster erubyMrRegions  contains=erubyOneLiner,erubyBlock,erubyExpression,rubyInterpolation

syn keyword mrRailisms      contained containedin=@erubyMrRegions form_tag

syn keyword mrText          contained containedin=@erubyMrRegions cycle reset_cycle
syn keyword mrDateTime      contained containedin=@erubyMrRegions relative_date relative_date_span relative_time_span
syn keyword mrDateTime      contained containedin=@erubyMrRegions time_ago_in_words time_lost_in_words

syn keyword mrForm          contained containedin=@erubyMrRegions button check_box delete_button error_messages error_messages_for
syn keyword mrForm          contained containedin=@erubyMrRegions fieldset fieldset_for file_field form form_for
syn keyword mrForm          contained containedin=@erubyMrRegions hidden_field label password_field radio_button radio_group
syn keyword mrForm          contained containedin=@erubyMrRegions select submit text_area text_field

syn keyword mrAsset         contained containedin=@erubyMrRegions image_tag link_to escape_js js
syn keyword mrAsset         contained containedin=@erubyMrRegions require_css include_required_css css_include_tag
syn keyword mrAsset         contained containedin=@erubyMrRegions require_js  include_required_js  js_include_tag

syn keyword mrRender        contained containedin=@erubyMrRegions partial catch_content clear_content throw_content


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

  HiLink mrRailisms         Error

  HiLink mrText             PreProc
  HiLink mrDateTime         PreProc
  HiLink mrForm             PreProc

  HiLink mrAsset            Include
  HiLink mrRender           Include

  delcommand HiLink
endif


let b:current_syntax = 'eruby.merb_view'
