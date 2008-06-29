" Vim syntax file
" Language: Bip configuration file
" Copyright: Copyright (C) 2004 Arnaud Cornet and Loïc Gomez
" License: This file is part of the bip project. See the file 'COPYING' for
"          the exact licensing terms.
"
"
" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
  syntax clear
elseif exists("b:current_syntax")
  finish
endif

syn case ignore

" Global elements
syn match	bipComment	contained %\s*#.*$%
syn match	bipEndError	contained /\(#.*\)\@<![^;{]$/

" Possible values types.
syn region	bipString	contained start=+"+ end=+"+
syn keyword	bipBool		contained true false
syn match	bipNumeric	contained /\d\d*/
syn region	bipIP		contained start=+"+ end=+"+
		\ contains=bipAddrTk,bipDot
syn region	bipNetmask	contained start=+"+ end=+"+
		\ contains=bipAddrTk,bipDot,bipSlash,bipMask
syn match	bipAddrTk	contained #\d\{1,3}#
syn match	bipDot		contained #\.#
syn match	bipSlash	contained #/#
syn match	bipMask		contained #\d\{1,2}#
syn match	bipWhite	contained +#\@!\s*+
" wrong
" syn match	bipWhite	contained +^\s*\ze[^#]*+

" Values syntax
syn region	bipStringV	contained matchgroup=Delimiter start=/\s*=\s*/
	\ end=/\s*;\s*/ contains=bipString
syn region	bipBoolV	contained matchgroup=Delimiter start=/\s*=\s*/
	\ end=/\s*;\s*/ contains=bipBool
syn region	bipNumericV	contained matchgroup=Delimiter start=/\s*=\s*/
	\ end=/\s*;\s*/ contains=bipNumeric
syn region	bipIPV		contained matchgroup=Delimiter start=/\s*=\s*/
	\ end=/\s*;\s*/ contains=bipIP
syn region	bipNetmaskV	contained matchgroup=Delimiter start=/\s*=\s*/
	\ end=/\s*;\s*/ contains=bipNetmask


syn region	bipMain		start=/\%^/ end=/\%$/
	\ contains=bipKeyword,bipNetwork,bipUser,bipComment,bipEndError

" Top level elements
syn keyword	bipKeyword	contained nextgroup=bipBoolV client_side_ssl
	\ no_backlog always_backlog
syn keyword	bipKeyword	contained nextgroup=bipStringV log_root
	\ log_format pid_file
syn keyword	bipKeyword	contained nextgroup=bipNumericV port log_level
	\ backlog_lines log_sync_interval
syn keyword	bipKeyword	contained nextgroup=bipIPV ip

" Network block (level 1)
syn region	bipNetwork	contained matchgroup=Macro 
	\ start=/network\s*{\s*/ end=/};/
	\ contains=bipNKeyword,bipServer,bipComment,bipEndError,bipWhite
syn keyword	bipNKeyword	contained nextgroup=bipStringV name
syn keyword	bipNKeyword	contained nextgroup=bipBoolV ssl

" User block (level 1)
syn region	bipUser		contained matchgroup=Macro start=/user\s*{\s*/
	\ end=/};/
	\ contains=bipUKeyword,bipConnection,bipComment,bipEndError,bipWhite
syn keyword	bipUKeyword	contained nextgroup=bipStringV password name

" Connection block (level 2)
syn region	bipConnection	contained matchgroup=Macro
	\ start=/connection\s*{\s*/ end=/};/
	\ contains=bipCoKeyword,bipChannel,bipComment,bipEndError,bipWhite
syn keyword	bipCoKeyword	contained nextgroup=bipBoolV ssl follow_nick
	\ ignore_first_nick
syn keyword	bipCoKeyword	contained nextgroup=bipStringV name user nick
	\ network password vhost away_nick on_connect_send login realname
syn keyword	bipCoKeyword	contained nextgroup=bipNumericV source_port

" Channel elements (lvl 2)
syn region	bipChannel	contained matchgroup=Macro
	\ start=/channel\s*{\s*/ end=/};/
	\ contains=bipCKeyword,bipComment,bipEndError,bipWhite
syn keyword	bipCKeyword	contained nextgroup=bipStringV name key

" Server elements (lvl 2)
syn region	bipServer	contained matchgroup=Macro
	\ start=/server\s*{\s*/ end=/};/
	\ contains=bipSKeyword,bipComment,bipEndError,bipWhite
syn keyword	bipSKeyword	contained nextgroup=bipStringV host
syn keyword	bipSKeyword	contained nextgroup=bipNumericV port 

" Client elements (lvl 2)
"syn region	bipClient	contained matchgroup=Macro
"	\ start=/client\s*{\s*/ end=/};/
"	\ contains=bipCLKeyword,bipComment,bipEndError,bipWhite
"syn keyword	bipCLKeyword	contained nextgroup=bipStringV user password

" Synchronization
syn sync match bipSyncNet grouphere bipNetwork /\_.\s*\(network\s*{\)\@=+/
syn sync match bipSyncUser grouphere bipUser /\_.\s*\(user\s*{\)\@=+/

" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version < 508
	command -nargs=+ HiLink hi link <args>
else
	command -nargs=+ HiLink hi def link <args>
endif

HiLink	bipMain	Error
HiLink	bipNetwork	Error
HiLink	bipChannel	Error
HiLink	bipServer	Error
HiLink	bipUser		Error
HiLink	bipConnection	Error

" We do not HiLink bipWhite, siec we only want to ignore it.
HiLink	bipKeyword	Keyword
HiLink	bipNKeyword	Keyword
HiLink	bipUKeyword	Keyword
HiLink	bipCKeyword	Keyword
HiLink	bipSKeyword	Keyword
HiLink	bipCoKeyword	Keyword

HiLink	bipComment	Comment

HiLink	bipMatch	Include

HiLink	bipStringV	Error
HiLink	bipBoolV	Error
HiLink	bipNumericV	Error
HiLink	bipIPV	Error

HiLink	bipEndError	Error

HiLink	bipString	String
HiLink	bipBool	Boolean
HiLink	bipNumeric	Number
HiLink	bipIP	String
HiLink	bipAddrTk	String
HiLink	bipDot	Delimiter
HiLink	bipSlash	Delimiter
HiLink	bipMask	Number

delcommand HiLink

let b:current_syntax = "bip"
" vim: ts=8
