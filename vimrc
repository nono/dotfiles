" Options globales {{{

syntax on       " active la coloration syntaxique
filetype on
filetype indent on
filetype plugin on
if has("gui_running")
	colo darkblue2
	set gfn=Inconsolata\ 13
	"set gfn=Droid\ Sans\ Mono\ 12
	"set gfn=Bitstream\ Vera\ Sans\ Mono\ 11
	"set gfn=Monaco\ 11
	set gcr=a:blinkon0
	set go-=T
	set go-=m
	set go+=c
else
	colo nejnej
endif

set ai          " indente automatiquement
set bs=2        " tout supprimer avec backspace
set dir-=.      " ne pas mettre de fichiers temporaires dans le répertoire courant
set ek          " utiliser les touches fléchées en mode insertion
set ff=unix     " fin de ligne au format UNIX
set is          " recherche incrémentale
set ls=2        " avoir en permanence la barre de status
set lz          " ne pas rafraîchir l'écran pendant une macro
set mouse=h     " n'utiliser la souris que dans l'aide
set noea        " ne pas redimensionner automatiquement les vues après un découpage
set nocp        " ne limite pas Vim aux fonctionnalités de VI
set noet        " ne pas transformer les tabs en spaces
set nohls       " ne pas mettre en surbrillance les termes recherchés
set noic        " tenir compte de la casse lors des recherches
set nojs        " pas 2 espaces après '.', '?' et '!' pour la commande J(oin)
set noml        " pas de modelines (trou de sécu dans les anciennes versions de Vim)
set nows        " ne pas retourner au début du fichier lorsqu'une recherche atteint la fin du fichier
set pt=<F11>    " pour coller du code sans avoir une double indentation (celle de départ + celle de Vim)
set si          " indentation intelligente (enfin presque)
set ruler       " affiche la position du curseur dans la barre d'état
set so=3        " toujours afficher au moins 3 lignes au-dessus et en dessous du curseur
set siso=2      " toujours afficher au moins 2 caractères à coté du curseur
set sm          " Afficher la parenthèse correspondante
set sw=4        " les tabulations s'arrêtent toujours sur une colonne multiple de 4
set ts=4        " les tabulations font 4 caractères (à l'affichage)
set tw=0        " ne pas couper les lignes
set title       " affiche le nom du fichier dans la barre de titre du term
set ve=block
set nowrap      " ne pas afficher sur plusieurs lignes les lignes trop longues
set nospell     " pas de correction orthographique par défaut
set spl=fr,en   " utiliser le français et l'anglais pour la correction orthographique
set sps=best,10 " afficher seulement les 10 meilleures propositions pour la correction orthographique
set spf=~/.vim/spell/perso.add " dictionnaire supplémentaire pour la correction orthographique
set tags+=../tags
set shell=/bin/bash
set wildmenu
set wildignore+=*.o,*.so,*.a,*.pyc,*.8
" set ballooneval
set omnifunc=syntaxcomplete#Complete
set cot=menuone
set grepprg=ack
set grepformat=%f:%l:%m
set shortmess=atI


" }}}
" Mappings {{{

nmap <F1> K
map <F2> <C-T>
map <F3> <C-]>
nmap <F4> :silent make<CR>:cw<CR>
nmap <F5> :cp<CR>
nmap <F6> :cn<CR>
nmap <F7> :AV<CR>
" nmap <F8> :AS<CR>
nmap <F8> :set spell!<CR>

" Don't make a # force column zero.
inoremap # X<BS>#

" Control + touches fléchées pour naviguer entre les vues
noremap <C-Up> <C-W><Up>
noremap <C-Down> <C-W><Down>
noremap <C-Right> <C-W><Right>
noremap <C-Left> <C-W><Left>

" Shift + touches fléchées pour naviger entre les tabs
noremap <S-Left> :tabprev<CR>
noremap <S-Right> :tabnext<CR>
noremap <S-Up> :tabnew<CR>

" Ctrl-t pour ouvrir de nouveaux fichiers facilement
map <C-t> :FuzzyFinderTextMate<CR>

" Complétion
inoremap <C-@> <C-P>

" exporter en html
let html_use_css = 1
let use_xhtml = 1
map <F12> :runtime! syntax/2html.vim<CR>


" }}}
" Autodetect filetypes {{{ "

au BufRead,BufNewFile bip.conf set ft=bip
au BufRead,BufNewFile arpalert.conf set ft=arpalert
au BufRead,BufNewFile haproxy.cfg set ft=haproxy
au BufRead,BufNewFile nginx.*,/etc/nginx/**/* set ft=nginx
au BufRead,BufNewFile *.mustache set ft=mustache
au BufRead,BufNewFile *.coffee set ft=coffee
au BufRead,BufNewFile Gemfile,Capfile,Vagrantfile set ft=ruby
au BufRead,BufNewFile *.go set ft=go
au BufRead,BufNewFile *.dc set ft=dotclear
au BufRead,BufNewFile *.wiki set ft=moin
au BufRead,BufNewFile *.{txt,md,mkd,markdown} set ft=markdown et
au BufRead,BufNewFile *.rl set ft=ragel
au BufRead,BufNewFile .mrxvtrc,mrxvtrc set ft=mrxvtrc
au BufRead,BufNewFile Xdefaults set ft=xdefaults
au BufRead,BufNewFile README,INSTALL,ChangeLog set ft=txt
au BufRead,BufNewFile *.t2t set ft=txt2tags
au BufRead,BufNewFile *.tmpl,*.send,*.ok,*.form,*.visu
    \ if (version < 700) |
	\     set ft=templeet |
	\ elseif (getline(2) =~? "^<rss ") |
    \     set ft=xml.templeet |
    \ else |
    \     set ft=html.templeet nospell |
    \ endif
au BufRead,BufNewFile ~/.vim/doc/*.txt set ft=help nospell
au BufRead,BufNewFile *.haml set ft=haml
au BufRead,BufNewFile *.sass set ft=sass
au BufRead,BufNewFile *.scss set ft=css
au BufRead,BufNewFile */public/javascripts/*.js set ft=javascript syntax=jquery


" }}}
" Plugins {{{ "

" Alternate :
" http://www.vim.org/scripts/script.php?script_id=31
let g:alternateSearchPath = '../src,../include'
let g:alternateNoDefaultAlternate = 1

" LoadHeader :
set path+=include,src
set path+=**
nmap <F9>  :call LoadHeader(getline("."),0)<cr>
nmap <F10> :call LoadHeader(getline("."),1)<cr>

" Increment Column :
vnoremap <c-a> :call IncrementColumn()<cr>

" Doxygen
let g:load_doxygen_syntax = 1

" SuperTab
" http://www.vim.org/scripts/script.php?script_id=182
let g:SuperTabRetainCompletionType = 2
let g:SuperTabDefaultCompletionType = "<C-P>"

" FuzzyFinder: TextMate
" http://github.com/jamis/fuzzyfinder_textmate/tree/master
let g:fuzzy_match_limit = 100

" SQL autocomplete
let g:ftplugin_sql_omni_key_left  = '<C-Left>'
let g:ftplugin_sql_omni_key_right = '<C-Right>'

" }}}
" Autres {{{ "

" Utilise ce navigateur pour l'aide en ligne
let g:browser = 'firefox -new-tab'

" Abréviations
source $HOME/.vim/abbrev.vim

" Commentaires
vmap / :s#^#//\ #<CR>gv:s#^//\ //\ ##<CR>
vmap # :s/^/#\ /<CR>gv:s/^#\ #\ //<CR>

" Sauvegarder automatiquement les feuilles de styles
au FocusLost *.css,*.sass :up

" SudoW permet d'enregistrer un fichier même quand on n'a pas les droits dessus
command! -bar -nargs=0 SudoW   :silent exe "write !sudo tee % >/dev/null"|silent edit!

" Tags
" set tags+=../tags

" Local
if filereadable(".vimrc.local")
	source ~/.vimrc.local
endif

" }}}
