if (exists("b:did_ftplugin"))
  finish
endif
let b:did_ftplugin = 1

au User lsp_setup call lsp#register_server({
	\ 'name': 'elixir-ls',
	\ 'cmd': {server_info->['/home/nono/vendor/elixir-ls/language_server.sh']},
    \ 'allowlist': ['elixir', 'eelixir']
	\ })

setlocal comments=:#
setlocal commentstring=#\ %s
setlocal sw=2 ts=2 et iskeyword+=!,?
