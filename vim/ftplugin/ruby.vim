setlocal keywordprg=qri\ -f\ plain
setlocal et
setlocal sw=2

vmap % "zdi<%= <C-R>z %><ESC>

inorea #! #!/usr/bin/env ruby
inorea ##- #-----------------------------
inorea ###- #-----------------------------------------------------------------------------

inorea bp require 'debug'; breakpoint


"inoremap <buffer> " <C-R>=<SID>Double('"','"')<CR>
"inoremap <buffer> ` <C-R>=<SID>Double('`','`')<CR>
"inoremap <buffer> ' <C-R>=<SID>Double("\'","\'")<CR>
"inoremap <buffer> ( ()<Left>
"inoremap <buffer> [ <C-R>=<SID>Double("[","]")<CR>
"inoremap <buffer> { <C-R>=<SID>Double("{","}")<CR>
"inoremap <buffer> \| <C-R>=<SID>Double("\|","\|")<CR>

function! s:Double(left,right)
    if strpart(getline(line(".")),col(".")-2,2) == a:left . a:right
	return "\<Del>"
    else
	return a:left . a:right . "\<Left>"
    endif
endfunction


iab <buffer> begin <C-R>=<SID>SpecialAbbrev("begin")<CR>
iab <buffer> def <C-R>=<SID>SpecialAbbrev("def")<CR>
iab <buffer> for <C-R>=<SID>SpecialAbbrev("for")<CR>
iab <buffer> if <C-R>=<SID>SpecialAbbrev("if")<CR>
iab <buffer> case <C-R>=<SID>SpecialAbbrev("case")<CR>
iab <buffer> class <C-R>=<SID>SpecialAbbrev("class")<CR>
iab <buffer> module <C-R>=<SID>SpecialAbbrev("module")<CR>
iab <buffer> unless <C-R>=<SID>SpecialAbbrev("unless")<CR>
iab <buffer> until <C-R>=<SID>SpecialAbbrev("until")<CR>
iab <buffer> while <C-R>=<SID>SpecialAbbrev("while")<CR>

function! s:SpecialAbbrev(string)
    if getline(line(".")) =~ '\S'  " Not a blank line.
	return a:string
    else 
	return a:string . "\<CR>end\<Esc>kA"
    endif
endfunction
