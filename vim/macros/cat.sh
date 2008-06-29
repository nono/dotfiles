#!/bin/sh
# Require the script vim2ansi.
# http://www.vim.org/scripts/script.php?script_id=1127

if test $# = 0; then
  vim -c ':TOansi' -c ':w! ~/.vim_cat' -c ':q!' -c ':q!' -
else
  vim -c ':TOansi' -c ':w! ~/.vim_cat' -c ':q!' -c ':q!' "$@"
fi
cat ~/.vim_cat

