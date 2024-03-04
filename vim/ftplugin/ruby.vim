setlocal sw=2 et
inorea #! #!/usr/bin/env ruby

au User lsp_setup call lsp#register_server({
	\ 'name': 'solargraph',
	\ 'cmd': {server_info->['solargraph', 'stdio']},
    \ 'allowlist': ['ruby']
	\ })
