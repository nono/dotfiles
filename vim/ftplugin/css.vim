setlocal et sw=2 ts=2 iskeyword+=-

au User lsp_setup call lsp#register_server({
	\ 'name': 'vscode-css-languageserver-bin',
	\ 'cmd': {server_info->['css-languageserver', '--stdio']},
    \ 'allowlist': ['css']
	\ })
