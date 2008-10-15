" Vim ftplugin file
" Language:    Datamapper migrations
" Maintainer:  Bruno Michel <brmichel@free.fr>
" Last Change: Oct 15, 2008
" Version:     0.1
" URL:         http://www.datamapper.org/

inorea <buffer> ct create_table
inorea <buffer> dt drop_table
inorea <buffer> mt modify_table

inorea <buffer> ai add_index
inorea <buffer> di drop_index

inorea <buffer> col column
inorea <buffer> ac add_column
inorea <buffer> dc drop_column
inorea <buffer> rc rename_column
inorea <buffer> cc change_column
