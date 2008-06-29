" LoadHeader
" Last Change: 25-04-2005
" Maintainer: Bruno Michel (brmichel@free.fr)

if exists("loaded_LoadHeader")
	finish
endif
let loaded_LoadHeader = 1

fun! LoadHeader(arg, source)
	if match(a:arg, '#include') < 0
		return
	endif
	let start = match(a:arg, "<\\|\"")
	let end   = match(a:arg, ">\\|\"[^\"]*$")
	if start < 0 || end < 0
		return
	endif

	let $filename = strpart(a:arg, start + 1, end - 1 - start )
	if a:source != 0
		let $filename = substitute($filename, "\.h", ".cpp", "")
	endif
	sfind $filename
endfunction
