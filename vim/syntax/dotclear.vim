" Vim syntax file
" Language:     Dotclear 2 (wiki2xhtml)
" Maintainer:   Bruno Michel <bmichel@menfin.info>
" Last Change:  2006-07-06
"
" El�ments de syntaxe :
" !!!      un titre tr�s important
" !!       un titre important
" !        un titre normal
" ----     <hr> un trait horizontal
" *        liste � puces
" #        liste num�rot�e
"          texte pr�format� (mettre un espace devant)
" > ou ;:  bloc de citation
" ''txt''  <em> italique
" __txt__  <strong> gras
" %%%      <br> retour forc� � la ligne
" ++txt++  <ins> insertion (soulign� ?)
" --txt--  <del> suppression (barr�)
" ~txt~    <anchor> ancre
" ??acr??  <acronym> acronyme, ou ??acronyme|titre??
" {{txt}}  <q> citation, ou {{citation|langue}}
" @@foo@@  <code> code
" /// ///  <pre> (?)
" $$txt$$  note de bas de page
" [url]    <a> lien, ou [nom|url] ou encore [nom|url|langue]
" ((url||alt)) <img> image


if version < 600
	syntax clear
elseif exists("b:current_syntax")
	finish
endif


" Headings
syn match       dcHeader              /^\(!\{1,4}\).\+$/

" Inline markup
syn match       dcItalic              /\('\{2}\)[^']\+\1/
syn match       dcBold                /\(_\{2}\).\{-}\1/
syn match       dcAdd                 /\(+\{2}\).\{-}\1/
syn match       dcDelete              /\(-\{2}\).\{-}\1/
syn match       dcCode                /\(@\{2}\).\{-}\1/
syn match       dcFooter              /\(\$\{2}\).\{-}\1/
syn match       dcAnchor              /\~.\{-}\~/

" Cite
syn match       dcCite                /^>\s\zs.\+$/
syn match       dcCite                /^;:\s\zs.\+$/
syn match       dcCite                /{{.\{-}}}/

" Codeblocks
syn region      dcPreformatted        start=/^\/\/\/$/ end=/^\/\/\/$/

" Links
syn match       dcLink                /\[.\{-}\]/
syn match       dcImage               /((.\{-}))/
syn match       dcAccr                /??.\{-}??/

" Lists
syn match       dcBulletList          /^\*\ze\s/
syn match       dcNumberedList        /^\#\ze\s/

" Rules
syn match       dcRule                /^-\{4,}/
syn match       dcNewLine             /%%%/


if version >= 508 || !exists("did_dotclear_syntax_inits")
	if version < 508
		let did_dotclear_syntax_inits = 1
		command -nargs=+ HiLink hi link <args>
	else
		command -nargs=+ HiLink hi def link <args>
	endif

	HiLink      dcHeader        Title
	HiLink      dcItalic        Statement
	HiLink      dcBold          Statement
	HiLink      dcCode          Statement
	HiLink      dcAdd           DiffAdd
	HiLink      dcDelete        DiffDelete
	HiLink      dcFooter        Question
	HiLink      dcAnchor        Question
	HiLink      dcCite          Constant
	HiLink      dcPreformatted  String
	HiLink      dcLink          Identifier
	HiLink      dcImage         Identifier
	HiLink      dcAccr          Identifier
	HiLink      dcBulletList    NonText
	HiLink      dcNumberedList  NonText
	HiLink      dcRule          PreProc
	HiLink      dcNewLine       PreProc

	delcommand HiLink
endif

let b:current_syntax = "dotclear"
