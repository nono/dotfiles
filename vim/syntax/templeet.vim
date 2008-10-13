" Vim syntax file
" Language:    Templeet
" Maintainer:  Bruno Michel <brmichel@free.fr>
" Last Change: Dec 09, 2006
" Version:     0.1.3
" URL:         http://templeet.org

if exists("b:current_syntax") && b:current_syntax =~ "templeet"
  finish
endif

if version < 700
  set filetype=html
endif

" Lists, functions and expressions
syn region  templeetFunc       start="\~" matchgroup=templeetParen end=")" fold transparent
  \ contains=templeetTilde,@templeetFuncName,templeetList
syn region  templeetList       contained matchgroup=templeetParen start="(" end=")"me=e-1
  \ contains=templeetComma,templeetWhite,templeetFunc,templeetQString,templeetDQString,templeetNumber,templeetExpr
syn region  templeetExpr       contained matchgroup=templeetParen2 start="!\?(" end=")"
  \ contains=templeetFunc,templeetExpr

" Atoms
syn match   templeetTilde      contained "\~\(\a\)\@="  nextgroup=@templeetFuncName
syn match   templeetComma      contained ","
syn match   templeetWhite      contained "\s\+"

" Strings
syn region  templeetQString    contained  start=+'+ skip=+\\'+ end=+'+  contains=templeetFunc
syn region  templeetDQString   contained  start=+"+ skip=+\\"+ end=+"+  contains=templeetFunc

" Numbers
syn match   templeetNumber     "-\=\(\.\d\+\|\d\+\(\.\d*\)\=\)\(e[-+]\=\d\+\)\="
syn match   templeetNumber     "0x[0-9a-f]\+"
syn match   templeetNumber     "0X[0-9A-F]\+"

" Functions
syn cluster templeetFuncName   contains=templeetSFuncName,linuxfrFuncName

" Standard functions
syn keyword templeetSFuncName  contained absolute_templeet add_word addslashes
syn keyword templeetSFuncName  contained array_fld array_flip array_keys
syn keyword templeetSFuncName  contained array_list array_merge array_unique
syn keyword templeetSFuncName  contained base64_decode base64_encode bwand
syn keyword templeetSFuncName  contained bwlshift bwor call ceil checkdnsrr
syn keyword templeetSFuncName  contained cleanstr compactdir createdir cuthtml
syn keyword templeetSFuncName  contained defunc delete_files diff dont_cache
syn keyword templeetSFuncName  contained empty ereg ereg_replace eval
syn keyword templeetSFuncName  contained executedtime file_exists fld floor
syn keyword templeetSFuncName  contained format_timestamp format_unixtimestamp
syn keyword templeetSFuncName  contained get get_dirname get_filename
syn keyword templeetSFuncName  contained get_filenamevar getconf getcookie getget
syn keyword templeetSFuncName  contained gethostbyaddr getip getpost gets
syn keyword templeetSFuncName  contained getserver header hex2ip htmlentities
syn keyword templeetSFuncName  contained htmlspecialchars http_error iconv if
syn keyword templeetSFuncName  contained include includewithcache integer ip2hex
syn keyword templeetSFuncName  contained is_numeric lines lines_fld list
syn keyword templeetSFuncName  contained list_tree listtotaltime ls ls_fld mail
syn keyword templeetSFuncName  contained md5 microtime minus mktime nl2br now
syn keyword templeetSFuncName  contained parseparam plus pow preg preg_match
syn keyword templeetSFuncName  contained preg_replace rand random rdf rdf_fld
syn keyword templeetSFuncName  contained readfile recent_users redirect
syn keyword templeetSFuncName  contained relative_base relative_templeet rem
syn keyword templeetSFuncName  contained round serialize set set_expiretime
syn keyword templeetSFuncName  contained set_time_limit setcookie sets sparam
syn keyword templeetSFuncName  contained spell split str_replace strictize string
syn keyword templeetSFuncName  contained strip_tags strlen strtolower substr
syn keyword templeetSFuncName  contained switch tempnam texted_image time
syn keyword templeetSFuncName  contained timestamp2day timestamp2month
syn keyword templeetSFuncName  contained timestamp2year trim ucfirst uncache
syn keyword templeetSFuncName  contained uncache_include unlink unserialize while

" LinuxFR.org functions
syn keyword linuxfrFuncName    contained adapt_to_res_type_1 adapt_to_res_type_2
syn keyword linuxfrFuncName    contained adapt_to_res_type_3 adapt_to_res_type_4
syn keyword linuxfrFuncName    contained adapt_to_res_type_5 adapt_to_res_type_6
syn keyword linuxfrFuncName    contained adapt_to_res_type_7 add_new_word
syn keyword linuxfrFuncName    contained admin_voted author bar body category
syn keyword linuxfrFuncName    contained countall countpost cuturl date
syn keyword linuxfrFuncName    contained defaultbox display_help display_isnew
syn keyword linuxfrFuncName    contained display_isnewnot displaynews
syn keyword linuxfrFuncName    contained display_spelled display_state
syn keyword linuxfrFuncName    contained groupid2name includediv infocomments
syn keyword linuxfrFuncName    contained linktologin list_group listsection
syn keyword linuxfrFuncName    contained list_users myoption news_infos paginate
syn keyword linuxfrFuncName    contained pct_recent_users previousname
syn keyword linuxfrFuncName    contained removecomments removeinclude
syn keyword linuxfrFuncName    contained removejournal sendemail timestamp2date
syn keyword linuxfrFuncName    contained title topic_name tostrike url votelink


" HTML integration
syn cluster htmlTop            add=templeetFunc
syn clear   htmlString
syn region  htmlString         contained start=+"+ end=+"+ contains=htmlSpecialChar,javaScriptExpression,templeetFunc,@htmlPreproc
syn region  htmlString         contained start=+'+ end=+'+ contains=htmlSpecialChar,javaScriptExpression,templeetFunc,@htmlPreproc
syn region  htmlTag            start=+<[^/]+   end=+>+ contains=htmlTagN,htmlString,htmlArg,htmlValue,htmlTagError,htmlEvent,htmlCssDefinition,templeetFunc,@htmlPreproc,@htmlArgCluster

" synchronization
syn sync lines=100

" case sensitive
syn case match


" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_lisp_syntax_inits")
  if version < 508
    let did_lisp_syntax_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  HiLink templeetParen         Delimiter
  HiLink templeetParen2        Operator

  HiLink templeetTilde         Special
  HiLink templeetComma         Special
  HiLink templeetNumber        Number
  HiLink templeetQString       String
  HiLink templeetDQString      String

  HiLink templeetSFuncName     Statement
  HiLink linuxfrFuncName       Identifier

  delcommand HiLink
endif

if !exists('b:current_syntax')          
  let b:current_syntax = "templeet"      
else
  let b:current_syntax = b:current_syntax.'.templeet'
endif

" vim: ts=8 nowrap
