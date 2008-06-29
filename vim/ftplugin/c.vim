setlocal cindent
setlocal sw=8
setlocal ts=8
setlocal tw=78

" Give the :Man command
runtime ftplugin/man.vim
nmap K :Man <cword><CR>

inorea <buffer> #d #define
inorea <buffer> #I #include <><Left>
inorea <buffer> #i #include ""<Left>
inorea <buffer> #n #ifndef NDEBUG
inorea <buffer> #e #endif
inorea <buffer> /** /**<CR>/<Up>
inorea <buffer> pub public:<CR>
inorea <buffer> pro protected:<CR>
inorea <buffer> pri private:<CR>

" inorea <buffer> if if () {<CR>}<Left><C-O>?)<CR>
" inorea <buffer> for for (;;) {<CR>}<C-O>?;;<CR>
" inorea <buffer> while while () {<CR>}<C-O>?)<CR>
" inorea <buffer> else else {<CR>x;<CR>}<C-O>?x;<CR><Del><Del>
" inorea <buffer> ifelse if () {<CR>}<CR>else {<CR>}<C-O>?)<CR>


inoremap <buffer> " <C-R>=<SID>Double('"','"')<CR>
inoremap <buffer> ` <C-R>=<SID>Double('`','`')<CR>
inoremap <buffer> ' <C-R>=<SID>Double("\'","\'")<CR>
inoremap <buffer> ( ()<Left>
inoremap <buffer> [ <C-R>=<SID>Double("[","]")<CR>
inoremap <buffer> { <C-R>=<SID>Double("{","}")<CR>

function! s:Double(left,right)
    if strpart(getline(line(".")),col(".")-2,2) == a:left . a:right
	return "\<Del>"
    else
	return a:left . a:right . "\<Left>"
    endif
endfunction

