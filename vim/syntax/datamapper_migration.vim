" Vim syntax file
" Language:    Datamapper migrations
" Maintainer:  Bruno Michel <brmichel@free.fr>
" Last Change: Oct 15, 2008
" Version:     0.1
" URL:         http://www.datamapper.org/

if exists("b:current_syntax") && b:current_syntax =~ "datamapper_migration"
  finish
endif


syn case match
set isk+=!


syn keyword dmRailisms      remove_column remove_columns rename_table remove_index

syn keyword dmSay           say say_with_time
syn keyword dmUpDown        migration up down
syn keyword dmTable         create_table drop_table modify_table
syn keyword dmIndex         add_index drop_index
syn keyword dmColumn        add_column drop_column column rename_column change_column
syn keyword dmHelper        now uuid auto_migrate!


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

  HiLink dmUpDown           Statement

  HiLink dmSay              Function
  HiLink dmTable            Function
  HiLink dmIndex            Function
  HiLink dmColumn           Function

  HiLink dmHelper           Keyword

  delcommand HiLink
endif


let b:current_syntax = 'ruby.datamapper_migration'
