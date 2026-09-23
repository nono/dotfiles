My dotfiles
===========

## Install

```
git clone git://github.com/nono/dotfiles ~/dotfiles
git submodule update --init
cd ~/dotfiles
```
And then copy/symlink the relevant files


## Notes

The config for neovim is in `~/.config/nvim`, not `~/.nvim`.
Same for git, mise and ghostty.

`claude/skills/` holds my Claude Code skills, `claude/agents/` the subagents they
dispatch:

```
ln -s ~/dotfiles/claude/skills ~/.claude/skills
ln -s ~/dotfiles/claude/agents ~/.claude/agents
```

Middle-click paste in Ghostty needs two settings. `scrollbar = never` in
`ghostty/config`, because the GTK scrollbar takes the middle click for
autoscroll. And this GSetting, which is `false` by default and which Ghostty
obeys since 1.3.0:

```
gsettings set org.gnome.desktop.interface gtk-enable-primary-paste true
```

I'm using some submodules for vendor modules.


## English coach for Claude Code

`bin/english-coach` writes a weekly review of my English to
`~/Documents/english-coach/`, based on the prompts I typed to Claude Code, and
notifies me on Friday evening:

```
cp systemd/english-coach*.{service,timer} ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now english-coach.timer english-coach-archive.timer
```

