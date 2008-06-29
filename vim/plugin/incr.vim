" IncrementColumn
" Last Change: 25-04-2005
" Maintainer: Bruno Michel (brmichel@free.fr)

if exists("loaded_IncrementColumn")
	finish
endif
let loaded_IncrementColumn = 1

fun! IncrementColumn()
	let l  = line(".")
	let c  = virtcol("'<")
	let l1 = line("'<")
	let l2 = line("'>")
	if l1 > l2
		let a = l - l2
	else
		let a = l - l1
	endif
	
	if a != 0
		exe 'normal '.c.'|'
		exe 'normal '.a."\<c-a>"
	endif
	
	normal `<
endfunction
