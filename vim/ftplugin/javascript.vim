setlocal et
setlocal sw=2 ts=2
autocmd User Rails/**/*.js set sw=2

noremap K :exec '!'.g:browser.' http://api.jquery.com/'.expand('<cword>').' &'<CR><CR>
