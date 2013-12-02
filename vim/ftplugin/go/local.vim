setlocal sw=8
setlocal ts=8
setlocal noet
autocmd BufWritePre *.go :Fmt
let g:gofmt_command="goimports"
