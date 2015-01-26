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

The config for openbox is in `~/.config/openbox`, not `~/.openbox`.
Same for git and fbpanel.

I'm using some submodules for vendor modules, but I'm moving to
[subtrees](http://blogs.atlassian.com/2013/05/alternatives-to-git-submodule-git-subtree/).
