if exists("svn_diff_helper")
	finish
endif
let svn_diff_helper = 1


function! SvnCommitReadDiff()
	" Save window position
	let l:netrw_line = line(".")
	let l:netrw_col  = virtcol(".")
	norm! H0
	let l:netrw_hline= line(".")

	if (!exists("b:svn_commited_files"))
		let b:svn_status = ""
		let l:end_file = line('$')
		0/^--
		let l:line_num = line('.') + 1
		let b:svn_commited_files = ''
		let l:description = ''
		while l:line_num <= l:end_file
			let b:svn_status = b:svn_status.getline(l:line_num)."\n"
			let l:filename = substitute(getline(l:line_num), '^.....\(.*\)', '\1', '')
			if strlen(l:filename) > 0
				let b:svn_commited_files = b:svn_commited_files." '".l:filename."'"
				let l:description = l:description."* ".l:filename.":\n"
			endif
			let l:line_num = l:line_num + 1
		endwhile
		exe 'norm! '.l:end_file.'G'
		go
		" exe 'norm! i'.l:description
		" set ft=diff
	endif

	0/^--/
	if (line('.') < line('$')) " Delete diff only if there is actually something
		0/^--/+,$d
	endif
	0/^--/
	exe 'norm! o'.b:svn_status

	silent exe 'norm! G'
	silent exe 'r!svn diff -N '.b:svn_commited_files

	" Restore window position
	exe "norm! ".l:netrw_hline."G0z\<CR>"
	exe "norm! ".l:netrw_line."G0".l:netrw_col."\<bar>"

	" <CR> is used to 'redraw' the diff
	nnoremap <CR> :call SvnCommitReadDiff()<CR>
endfunction
silent call SvnCommitReadDiff()

" vim: ts=2:sw=2
