" Vim plugin for converting a syntax highlighted file to Ansi Sequence.
" Maintainer: Rogerz Zhang <rogerz.zhang@gmail.com>
" Last Change: 2004 Nov 10
" Based on tohtml.vim

" Don't do this when:
" - when 'compatible' is set
" - this plugin was already loaded
" - user commands are not available.
if !&cp && !exists(":TOansi") && has("user_commands")
  command -range=% TOansi :call Convert2ANSI(<line1>, <line2>)

  func Convert2ANSI(line1, line2)
    if a:line2 >= a:line1
      let g:ansi_start_line = a:line1
      let g:ansi_end_line = a:line2
    else
      let g:ansi_start_line = a:line2
      let g:ansi_end_line = a:line1
    endif

    runtime syntax/2ansi.vim

    unlet g:ansi_start_line
    unlet g:ansi_end_line
  endfunc
endif
