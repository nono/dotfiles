setlocal et sw=2 ts=2

au User lsp_setup call lsp#register_server({
	\ 'name': 'javascript-typescript-stdio',
	\ 'cmd': {server_info->['javascript-typescript-stdio']},
    \ 'allowlist': ['javascript']
	\ })
