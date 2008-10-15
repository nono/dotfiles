" This file is taken from the Rails.vim plugin by Tim Pope
" http://rails.vim.tpope.net/

" surround.vim
if exists("g:loaded_surround")
  " The idea behind the || part here is that one can normally define the
  " surrounding to omit the hyphen (since standard ERuby does not use it)
  " but have it added in Rails ERuby files.  Unfortunately, this makes it
  " difficult if you really don't want a hyphen in Rails ERuby files.  If
  " this is your desire, you will need to accomplish it via a rails.vim
  " autocommand.
  if !exists("b:surround_45") || b:surround_45 == "<% \r %>" " -
    let b:surround_45 = "<% \r -%>"
  endif
  if !exists("b:surround_61") " =
    let b:surround_61 = "<%= \r %>"
  endif
  if !exists("b:surround_35") " #
    let b:surround_35 = "<%# \r %>"
  endif
  if !exists("b:surround_101") || b:surround_101 == "<% \r %>\n<% end %>" "e
    let b:surround_5   = "<% \r -%>\n<% end -%>"
    let b:surround_69  = "<% \1expr: \1 -%>\r<% end -%>"
    let b:surround_101 = "<% \r -%>\n<% end -%>"
  endif
endif
