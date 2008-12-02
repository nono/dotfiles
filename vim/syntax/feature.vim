" Vim syntax file
" Language:    Cucumber feature
" Maintainer:  Bruno Michel <brmichel@free.fr>
" Last Change: Oct 7, 2008
" Version:     0.2
" URL:         http://github.com/aslakhellesoy/cucumber

" For version 5.x: Clear all syntax items
" For version 6.x: Quit when a syntax file was already loaded
if version < 600
	syntax clear
elseif exists("b:current_syntax")
	finish
endif


syn case match

syn region  fComment  start=/#/        end=/$/
syn region  fFeature  start=/Feature/  end=/$/ contains=fKeywords
syn region  fScenario start=/Scenario/ end=/$/ contains=fKeywords
syn region  fGiven    start=/Given/    end=/$/ contains=ALL
syn region  fWhen     start=/When/     end=/$/ contains=ALL
syn region  fThen     start=/Then/     end=/$/ contains=ALL
syn region  fAnd      start=/And/      end=/$/ contains=ALL
syn region  fBut      start=/But/      end=/$/ contains=ALL

syn match   fNumber   /\d\+/                   contained
syn region  fQString  matchgroup=fDelimiter    contained start=/'/ skip=/\\'/ end=/'/
syn region  fDQString matchgroup=fDelimiter    contained start=/"/ skip=/\\"/ end=/"/

syn keyword fKeywords Feature Scenario GivenScenario Given When Then And But contained


" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version < 508
	command -nargs=+ HiLink hi link <args>
else
	command! -nargs=+ HiLink hi def link <args>
endif

HiLink      fComment    Comment
HiLink      fFeature    Statement
HiLink      fScenario   Statement
HiLink      fGiven      Normal
HiLink      fWhen       Normal
HiLink      fThen       Normal
HiLink      fAdd        Normal
HiLink      fBut        Normal

HiLink      fNumber     Number
HiLink      fQString    String
HiLink      fDQString   String
HiLink      fDelimiter  SpecialChar

HiLink      fKeywords   Identifier

let b:current_syntax = "feature"
