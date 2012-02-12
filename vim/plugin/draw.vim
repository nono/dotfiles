" Vim plugin for drawing rectangles and lines using blockwise Visual selection.
" Maintainer:	Bruno Michel <brmichel@free.fr>
" Last Change:	2012-02-12
"
" This plugin is based on draw.vim by Timo Frenay:
" http://www.vim.org/scripts/script.php?script_id=452


" This plugin allows you to draw rectangles and lines using blockwise Visual
" mode, which makes it ideal for drawing tables and such. Simply move the cursor
" to the start position, hit CTRL-V to enter blockwise Visual mode and move the
" cursor to define the rectangle or line. Finally, type <leader>d to draw the
" rectangle or line. If you don't know what <leader> is, \d should do the trick.
"
" Note: I strongly recommend ":set virtualedit+=block" when using this script,
" so you can define rectangles beyond the end of the line.


" Map <leader>d in Visual mode to the Draw() function below
vnoremap <silent> <leader>d  <Esc>:call Draw()<CR>
vnoremap <silent> ;          <Esc>:call Draw()<CR>


fun! Draw()
    if (visualmode() != "\<C-V>")
        " Beep!
        execute "normal! \<Esc>"
        echoerr "DrawRect() requires a blockwise Visual selection"
        return
    endif
    " Backup options
    let l:virtualedit = &virtualedit
    let l:wrap = &wrap
    " Set options
    set virtualedit=all nowrap
    " Get rectangle boundaries
    let l:top = line("'<")
    let l:left = virtcol("'<")
    let l:bottom = line("'>")
    let l:right = virtcol("'>")
    " Get cursor position
    let l:line = line(".")
    let l:col = virtcol(".")

    if (l:top == l:bottom)
        normal! `<
        if (l:left == l:right)
            " Draw a cross. I hope that's what you wanted...
            normal! r+
        else
            " Draw a horizontal arrow
            if (l:left == l:col)
                normal! r<l
            else
                normal! r-l
            endif
            let l:count = l:right - l:left - 1
            while (l:count)
                normal! r-l
                let l:count = l:count - 1
            endwhile
            if (l:right == l:col)
                normal! r>
            else
                normal! r-
            endif
        endif

    elseif (l:left == l:right)
        " Draw a vertical line
        normal! `<
        if (l:top == l:line)
            normal! r^j
        else
            normal! r|j
        endif
        let l:count = l:bottom - l:top - 1
        while (l:count)
            normal! r|j
            let l:count = l:count - 1
        endwhile
        if (l:bottom == l:line)
            normal! rV
        else
            normal! r|
        endif

    else
        " Draw a rectangle
        if (l:right < l:left)
            " Blockwise Visual selection is right-to-left, mirror it first
            execute "normal! gvO\<Esc>"
            let l:left = virtcol("'<")
            let l:right = virtcol("'>")
        endif
        normal! `>
        " Draw bottom side
        let l:count = l:right - l:left - 1
        while (l:count)
            normal! hr-
            let l:count = l:count - 1
        endwhile
        " Draw bottom-left corner
        normal! hr\
        " Draw left side
        let l:count = l:bottom - l:top - 1
        while (l:count)
            normal! kr|
            let l:count = l:count - 1
        endwhile
        " Draw top-left corner
        normal! kr/
        " Draw top side
        let l:count = l:right - l:left - 1
        while (l:count)
            normal! lr-
            let l:count = l:count - 1
        endwhile
        " Draw top-right corner
        normal! lr\
        " Draw right side
        let l:count = l:bottom - l:top - 1
        while (l:count)
            normal! jr|
            let l:count = l:count - 1
        endwhile
        " Draw bottom-right corner
        normal! jr/
    endif

    " Restore options
    let &virtualedit = l:virtualedit
    let &wrap = l:wrap
endfunction
