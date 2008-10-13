" Vim syntax file
" Language:    Merb Controller
" Maintainer:  Bruno Michel <brmichel@free.fr>
" Last Change: Oct 12, 2008
" Version:     0.1
" URL:         http://www.merbivore.com/

if exists("b:current_syntax") && b:current_syntax =~ "merb_controller"
  finish
endif


syn case match

syn keyword mrRailisms      after_filter before_filter around_filter
syn keyword mrRailisms      skip_after_filter skip_before_filter skip_filter
syn keyword mrRailisms      url_for verify_action verify_method
syn keyword mrRailisms      rescue_action_in_public rescue_action_locally
syn keyword mrRailisms      filter_parameter_logging render_to_string
syn keyword mrRailisms      redirect_to redirect_back_or_default

syn keyword mrFilters       after before skip_after skip_before
syn keyword mrLayout        layout
syn keyword mrParamsFilter  log_params_filtered params_accessible params_protected
syn keyword mrResponders    provides only_provides does_not_provide clear_provides reset_provides

syn keyword mrUrl           absolute_url relative_url url resource
syn keyword mrRender        render display redirect redirect_back_or
syn keyword mrRender        render_chunked render_deferred render_then_call
syn keyword mrRender        run_later send_chunk send_data send_file send_mail
syn keyword mrCookies       cookies set_cookie delete_cookie
syn keyword mrContentType   content_type


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

  HiLink mrFilters          PreProc
  HiLink mrLayout           PreProc
  HiLink mrParamsFilter     PreProc
  HiLink mrResponders       PreProc

  HiLink mrUrl              Keyword
  HiLink mrRender           Keyword
  HiLink mrCookies          Keyword
  HiLink mrContentType      Keyword

  delcommand HiLink
endif


let b:current_syntax = 'ruby.merb_controller'
