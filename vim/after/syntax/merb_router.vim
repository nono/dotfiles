" Vim syntax file
" Language:    Merb Router
" Maintainer:  Bruno Michel <brmichel@free.fr>
" Last Change: Oct 7, 2008
" Version:     0.1
" URL:         http://www.merbivore.com/

if exists("b:current_syntax") && b:current_syntax =~ "merb_router"
  finish
endif


syn case match
setlocal iskeyword+=:

syn keyword mrBehaviour capture default default_routes defaults defer
syn keyword mrBehaviour defer_to fixatable full_name identify match
syn keyword mrBehaviour name namespace options redirect register to with
syn keyword mrResources resource resources

syn keyword mrOptions   :method :path :params :controller :action :id
syn keyword mrOptions   :namespace :name_prefix :collection :member :keys
syn keyword mrOptions   :user_agent :protocol :domain :subdomains


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

  HiLink mrBehaviour    Identifier
  HiLink mrResources    Identifier

  HiLink mrOptions      Include

  delcommand HiLink
endif


let b:current_syntax = 'ruby.merb_router'
