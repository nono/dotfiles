" nmap <F4> :silent !pdflatex % && gv %:r.pdf<CR><C-L>
setlocal makeprg=pdflatex\ %
setlocal spell

iab noeud n\oe{}ud
iab noeuds n\oe{}uds
