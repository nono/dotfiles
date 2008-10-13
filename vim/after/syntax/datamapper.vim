" Vim syntax file
" Language:    Datamapper
" Maintainer:  Bruno Michel <brmichel@free.fr>
" Last Change: Oct 12, 2008
" Version:     0.2
" URL:         http://www.datamapper.org/

if exists("b:current_syntax") && b:current_syntax =~ "datamapper"
  finish
endif


syn case match

syn keyword dmRailisms      find find_first find_all find_or_create
syn keyword dmRailisms      attr_accessible attr_protected

syn keyword dmProperty      property
syn keyword dmAssociations  has belongs_to many_to_one
syn keyword dmCardinality   n

syn keyword dmValidations   validates_present validates_absent validates_is_accepted validates_is_confirmed
syn keyword dmValidations   validates_format validates_length validates_with_method validates_with_block
syn keyword dmValidations   validates_is_number validates_is_unique validates_within

syn keyword dmCallbacks     before after before_class_method after_class_method

syn keyword dmIs            is_a_tree is_a_nested_set
 

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

  HiLink dmRailisms         Error

  HiLink dmProperty         PreProc
  HiLink dmAssociations     PreProc
  HiLink dmValidations      PreProc
  HiLink dmCallbacks        PreProc
  HiLink dmIs               PreProc

  HiLink dmCardinality      Number

  delcommand HiLink
endif


let b:current_syntax = 'ruby.datamapper'
