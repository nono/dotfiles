" Vim syntax support file
" Author: Rogerz Zhang <rogerz.zhang@gmail.com>
" Create: 2004 Nov 10
" Update:
"	2004 Nov 15,	Greatly improved processing speed
"	2004 Nov 12,	Guess color from RGB when in gui
"	2004 Nov 11,	Correct bugs when T_co =16
"			Set bold as default attribute when in gui
"			Correct bug of unmatched AnsiOpening and AnsiClosing
"	2004 Nov 10,	Initial Version
" Transform a file into ANSI sequence, using the current syntax highlighting.
"
" This script is based on 2html.vim
" Thanks: Bram Moolenaar <Bram@vim.org>
"	  dodowolf@drl


" Number lines when explicitely requested or when `number' is set
if exists("ansi_number_lines")
  let s:numblines = ansi_number_lines
else
  let s:numblines = &number
endif

" Guess color from RGB
if has("gui_running")
  let s:whatterm = "gui"
else
  let s:whatterm = "cterm"
endif

if s:whatterm == "gui"
  function! s:GetR(rgb)
    return "0x".strpart(a:rgb,1,2)
  endfun

  function! s:GetG(rgb)
    return "0x".strpart(a:rgb,3,2)
  endfun

  function! s:GetB(rgb)
    return "0x".strpart(a:rgb,5,2)
  endfun

  function! s:GetAnsiColor(rgb)
    let red = s:GetR(a:rgb)
    let green = s:GetG(a:rgb)
    let blue = s:GetB(a:rgb)
    let bold = (red>=0xc0 || green>=0xc0 || blue>=0xc0)
    if bold | let color=(red>0x7f)*1+(green>0x7f)*2+(blue>0x7f)*4
    else | let color=(red>0x3f)*1+(green>0x3f)*2+(blue>0x3f)*4
    endif
    return color+bold*8
  endfun
endif

" Return opening Ansi Sequence tag for given highlight id
function! s:AnsiOpening(id)
  let s:normal = 0
  let fg = synIDattr(a:id, "fg#")
  let bg = synIDattr(a:id, "bg#")
  let inv = synIDattr(a:id, "inverse")
  let ul = synIDattr(a:id, "underline")
  let bd = synIDattr(a:id, "bold")
" When in gui guess the ansi color
  if s:whatterm == "gui"
    let fg = s:GetAnsiColor(fg)
    let bg = s:GetAnsiColor(bg)
  endif
" Check if it is normal text
  if !(fg || bg || inv || ul || bd) | let s:normal = 1 | return "" | endif
" When in 16 color term
  if fg > 7 | let fg = fg - 8 | let bd = 1 | endif
  if bg > 7 | let bg = bg - 8 | endif
" Resume system color
  if fg == -1 | let bd = 0 | endif
" Add modifiers
  let a = "\<C-[>["
  " For inverse
  if inv
    let a = a . "7"
  else
  " Bold control
    if bd | let a = a . "1" | else | let a = a . "0" | endif
  " Underline control
    if ul | let a = a . ";4" | endif
  " Frontgroud color and Background color control
    if fg!=-1 | let a = a . ";3" . fg | endif
    let x = synIDattr(a:id, "bg", "cterm")
    if bg!=-1&&bg!=0 | let a = a . ";4" . bg | endif
  endif
  " End modifiers
  let a = a . "m"
  return a
endfun

" Return closing Ansi Sequence for given highlight id
function! s:AnsiClosing(id)
  if !(s:normal) | let a = "\<C-[>[m" | else | let a = "" | endif
  return a
endfun


" Set some options to make it work faster.
let s:old_title = &title
let s:old_icon = &icon
let s:old_et = &l:et
let s:old_search = @/
let s:old_report = &report

set notitle noicon
setlocal et
set report=10000000

" Split window to create a buffer with the Ansi file.
let s:orgbufnr = winbufnr(0)
if expand("%") == ""
  new Untitled.ansi
else
  new %.ansi
endif
let s:newwin = winnr()
let s:orgwin = bufwinnr(s:orgbufnr)

set modifiable
%d
let s:old_paste = &paste
set paste
let s:old_magic = &magic
set magic

exe s:orgwin . "wincmd w"

" Loop over all lines in the original text.
" Use ansi_start_line and ansi_end_line if they are set.
if exists("ansi_start_line")
  let s:lnum = ansi_start_line
  if s:lnum < 1 || s:lnum > line("$")
    let s:lnum = 1
  endif
else
  let s:lnum = 1
endif
if exists("ansi_end_line")
  let s:end = ansi_end_line
  if s:end < s:lnum || s:end > line("$")
    let s:end = line("$")
  endif
else
  let s:end = line("$")
endif

" List of all id's
let s:idlist = ","

while s:lnum <= s:end

  " Get the current line
  let s:line = getline(s:lnum)
  let s:len = strlen(s:line)
  let s:new = ""

  " Loop over each character in the line
  let s:col = 1
  while s:col <= s:len
    let s:startcol = s:col " The start column for processing text
    let s:id = synID(s:lnum, s:col, 1)
    let s:col = s:col + 1
    " Speed loop (it's small - that's the trick)
    " Go along till we find a change in synID
    while s:col <= s:len && s:id == synID(s:lnum, s:col, 1) | let s:col = s:col + 1 | endwhile

    " Output the text with the same synID enclosed by ansi sequence
    let s:id = synIDtrans(s:id)
    let s:id_name = synIDattr(s:id, "name", s:whatterm)
    let s:new = s:new . '<span class="' . s:id_name . '">' . strpart(s:line, s:startcol - 1, s:col - s:startcol) . '</span>'

    " Add the class to class list if it's not there yet
    if stridx(s:idlist, ",".s:id.",") == -1
      let s:idlist = s:idlist . s:id . ","
    endif
    if s:col > s:len
      break
    endif
  endwhile

  exe s:newwin . "wincmd w"
  exe "normal! a" . s:new .  "\n\e"
  exe s:orgwin . "wincmd w"
  let s:lnum = s:lnum + 1
  +
endwhile

exe s:newwin . "wincmd w"

" Gather attributes for all other classes
let s:idlist = strpart(s:idlist, 1)
while s:idlist != ""
  let s:attr = ""
  let s:col = stridx(s:idlist, ",")
  let s:id = strpart(s:idlist, 0, s:col)
  let s:idlist = strpart(s:idlist, s:col + 1)
  let s:id_name = synIDattr(s:id, "name", s:whatterm)
  " Apply the class attribute
  execute '%s+<span class="' . s:id_name . '">\(.\{-}\)</span>+' . s:AnsiOpening(s:id) . '\1' . s:AnsiClosing(s:id) . '+g'
endwhile

" Restore old settings
let &title = s:old_title
let &icon = s:old_icon
let &paste = s:old_paste
let &magic = s:old_magic
let @/ = s:old_search
let &report = s:old_report
exe s:orgwin . "wincmd w"
let &l:et = s:old_et
exe s:newwin . "wincmd w"

" Save a little bit of memory (worth doing?)
unlet s:old_et s:old_paste s:old_icon s:old_title s:old_search s:old_report
unlet s:lnum s:end s:old_magic
unlet! s:col s:id s:attr s:len s:line s:new s:numblines
unlet s:orgwin s:newwin s:orgbufnr
