" Options globales {{{

syntax on       " active la coloration syntaxique
filetype on
filetype indent on
filetype plugin on
if has("gui_running")
	colo solarized
	set bg=light
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
	set bg=dark
endif

set ai          " indente automatiquement
set autoread    " auto-reload modified files (with no local changes)
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
set nowrap      " ne pas afficher sur plusieurs lignes les lignes trop longues
set nospell     " pas de correction orthographique par défaut
set spl=fr,en   " utiliser le français et l'anglais pour la correction orthographique
set sps=best,10 " afficher seulement les 10 meilleures propositions pour la correction orthographique
set spf=~/.vim/spell/perso.add " dictionnaire supplémentaire pour la correction orthographique
set tags+=../tags
set shell=/bin/bash
set ve=block
set wildmenu
set wildignore+=*.o,*.so,*.a,*.pyc,*.rbc,*.8
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

" Ctrl-+ pour augmenter la taille de la police
noremap <C-kplus> :let &guifont=substitute(&guifont, '\d\+', '\=eval(submatch(0)+1)', '')<CR>
noremap <C-kminus> :let &guifont=substitute(&guifont, '\d\+', '\=eval(submatch(0)-1)', '')<CR>

" Control + touches fléchées pour naviguer entre les vues
noremap <C-Up> <C-W><Up>
noremap <C-Down> <C-W><Down>
noremap <C-Right> <C-W><Right>
noremap <C-Left> <C-W><Left>

" Alt + touches fléchées pour déplacer des lignes de code
nnoremap <A-Down> :m+<CR>==
nnoremap <A-Up> :m-2<CR>==
vnoremap <A-Down> :m'>+<CR>gv=gv
vnoremap <A-Up> :m-2<CR>gv=gv

" Complétion
inoremap <C-@> <C-P>

" Se placer au bon endroit
inoremap () ()<Left>
inoremap '' ''<Left>
inoremap "" ""<Left>

" exporter en html
let html_use_css = 1
let use_xhtml = 1
map <F12> :runtime! syntax/2html.vim<CR>

" Utilise ce navigateur pour l'aide en ligne
let g:browser = 'x-www-browser'


" }}}
" Autodetect filetypes {{{ "

au BufRead,BufNewFile bip.conf set ft=bip
au BufRead,BufNewFile haproxy.cfg set ft=haproxy
au BufRead,BufNewFile nginx.*,/etc/nginx/**/* set ft=nginx
au BufRead,BufNewFile Gemfile,Capfile,Vagrantfile,Guardfile set ft=ruby
au BufRead,BufNewFile *.dc set ft=dotclear
au BufRead,BufNewFile *.wiki set ft=moin
au BufRead,BufNewFile *.t2t set ft=txt2tags
au BufRead,BufNewFile *.textile set ft=textile
au BufRead,BufNewFile *.{txt,md,mkd,markdown} set ft=markdown et tw=78
au BufRead,BufNewFile *.ditaa set ft=ditaa
au BufRead,BufNewFile Xdefaults set ft=xdefaults
au BufRead,BufNewFile README,INSTALL,ChangeLog set ft=txt
au BufRead,BufNewFile ~/.vim/doc/*.txt set ft=help nospell
au BufRead,BufNewFile *.jade set ft=jade
au BufRead,BufNewFile *.haml set ft=haml
au BufRead,BufNewFile *.sass set ft=sass
au BufRead,BufNewFile *.scss set ft=scss
au BufRead,BufNewFile *.mustache set ft=mustache
au BufRead,BufNewFile *.{handlebars,hbs} set ft=handlebars
au BufRead,BufNewFile *.{jst,ejs} set ft=html
au BufRead,BufNewFile *.coffee,Cakefile set ft=coffee et ts=2 sw=2
au BufRead,BufNewFile *.go set ft=go


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
let g:SuperTabDefaultCompletionType = "<C-P>"

" SQL autocomplete
let g:ftplugin_sql_omni_key_left  = '<C-Left>'
let g:ftplugin_sql_omni_key_right = '<C-Right>'

" Vim-markdown-preview
let g:VMPhtmlreader = g:browser

" Syntastic
let g:syntastic_auto_loc_list = 1
let g:syntastic_enable_signs = 1
let g:syntastic_disabled_filetypes = ['c', 'cpp', 'sh', 'coffee']

" }}}
" Autres {{{ "

" Show trailing white-space
let ruby_space_errors = 1
let c_space_errors = 1
let javascript_space_errors = 1

" Abréviations
source $HOME/.vim/abbrev.vim

" Commentaires
vmap / :s#^#//\ #<CR>gv:s#^//\ //\ ##<CR>
vmap # :s/^/#\ /<CR>gv:s/^#\ #\ //<CR>

" Sauvegarder automatiquement les feuilles de styles
au FocusLost *.css,*.sass :up

" SudoW permet d'enregistrer un fichier même quand on n'a pas les droits dessus
command! -bar -nargs=0 SudoW   :silent exe "write !sudo tee % >/dev/null"|silent edit!

" Un petit alias pour se simplifier la vie
command E :Explore

" Automatically give executable permissions if file begins with #! and contains '/bin/' in the path
function MakeScriptExecuteable()
	if getline(1) =~ "^#!.*/bin/"
		silent !chmod +x <afile>
	endif
endfunction

" vimbits
au BufWritePost * call MakeScriptExecuteable()
au BufWritePost .vimrc so ~/.vimrc
au InsertLeave * set nopaste
vnoremap < <gv
vnoremap > >gv

" }}}
