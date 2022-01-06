My dotfiles
===========

Install
-------

```
git clone git://github.com/nono/dotfiles ~/dotfiles
git submodule update --init
cd ~/dotfiles
```
And then copy/symlink the relevant files

Notes
-----

The config for neovim is in `~/.config/nvim`, not `~/.nvim`.
Same for git and tilix themes.

Tilix also use [dconf](https://github.com/gnunn1/tilix/issues/571#issuecomment-293097876):

```
dconf dump /com/gexperts/Tilix/ > tilix.dconf
dconf load /com/gexperts/Tilix/ < tilix.dconf
```

I'm using some submodules for vendor modules, but I'm moving to
[subtrees](http://blogs.atlassian.com/2013/05/alternatives-to-git-submodule-git-subtree/).
