# Env
export PATH="$HOME/bin:$PATH"
export PS1='${SSH_CONNECTION+"%n@%m:"}%~%# '
export PS2=' > '
export DIRSTACKSIZE=16
export EDITOR=nvim
export PAGER=less
export BROWSER=x-www-browser
export LS_OPTIONS='--color=auto'
export GREP_COLOR='1;37;41'
umask 022

# disable XON/XOFF flow control (^s/^q)
stty -ixon

# History
HISTFILE=~/.zsh_hist
HISTSIZE=5000
SAVEHIST=1000

# Use 'cat -v' to obtain the keycodes
bindkey "\C-b" backward-word         ## ctrl-b
bindkey "\C-f" forward-word          ## ctrl-f
bindkey "^[[3~" delete-char          ## Del
bindkey "^[[7~" beginning-of-line    ## Home
bindkey "^[[8~" end-of-line          ## End
bindkey "^[[A" up-line-or-search     ## up arrow for back-history-search
bindkey "^[[B" down-line-or-search   ## down arrow for fwd-history-search
bindkey " " magic-space              ## do history expansion on space

# Zsh
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt RM_STAR_SILENT
setopt HASH_CMDS
setopt HASH_DIRS
setopt PRINT_EXIT_VALUE
setopt NO_BG_NICE
setopt NO_BEEP
setopt PROMPT_SUBST

# Completion & prompt
fpath=(~/.zsh/Completion ~/.zsh/functions $fpath)
zmodload -i zsh/complist
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion::complete:*' cache-path ~/.zsh/cache
zstyle ':completion::complete:cd::' tag-order local-directories path-directories
zstyle ':completion:*:processes' command 'ps -au$USER'
zstyle ':completion:*:*:kill:*:processes' list-colors "=(#b) #([0-9]#)*=36=31"
autoload -U ~/.zsh/Completion/*(:t)
autoload -U compinit
compinit -u
autoload -U promptinit && promptinit
export DEFAULT_USER=nono
prompt unpure

source ~/config/zsh/base16-bright.dark.sh
source /etc/zsh_command_not_found

# Aliases
alias -g L='|less'
alias -g G='|grep'
alias -g W='|wc'

alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -la'
alias lh='ls $LS_OPTIONS -lah'
alias sl=ls
alias cd..='cd ..'
alias less='less -R'
alias grep='grep --color'
alias v=nvim
alias o=xdg-open
alias ftp='lftp'
alias notes="ag 'TODO|FIXME|XXX|HACK'"
alias serve='thin -A file start'
alias mysql='mysql --select_limit=1000'
alias chromium=chromium-browser
alias pop=popcorn-time
alias ps42='ps -eo pid,wchan:42,cmd'
alias ssh='TERM=rxvt-unicode ssh'

mp() { xrandr --output DVI-I-1 --mode 1920x1080 ; sleep 2 ; mpv $@ ; xrandr --output DVI-I-1 --mode 2560x1440 }
font() { echo -ne "\\033]710;xft:Droid Sans Mono for Powerline:pixelsize=$1\\007" }

# Colored manpages
man() {
  env LESS_TERMCAP_mb=$'\E[01;31m' \
  LESS_TERMCAP_md=$'\E[01;38;5;74m' \
  LESS_TERMCAP_me=$'\E[0m' \
  LESS_TERMCAP_se=$'\E[0m' \
  LESS_TERMCAP_so=$'\E[38;5;246m' \
  LESS_TERMCAP_ue=$'\E[0m' \
  LESS_TERMCAP_us=$'\E[04;38;5;146m' \
  man "$@"
}

# Change displays
function videoproj {
  xrandr --output LVDS1 --mode 1024x768 --pos 0x0
  xrandr --output VGA1  --mode 1024x768 --pos 0x0
}
function one_screen {
  xrandr --output LVDS1 --mode 1600x900 --pos 0x0
  xrandr --output VGA1 --off
}
function two_screens {
  xrandr --output LVDS1 --mode 1600x900 --pos 0x0
  xrandr --output VGA1 --mode 1920x1080 --right-of LVDS1
}

# Aptitude
alias ai='sudo apt install'
alias au='sudo apt update'
alias ad='sudo apt upgrade'
alias aud='sudo apt-get autoremove && sudo apt update && sudo apt upgrade'
alias arm='sudo apt remove'
alias as='apt search'

# Golang
export GOPATH="$HOME"

# Node.js
export PATH="node_modules/.bin:$PATH"
export NODE_PATH="./lib"
. <(npm completion)

# Ruby
export RUBYLIB="./ext:./lib"
export NOKOGIRI_USE_SYSTEM_LIBRARIES="true"
source ~/share/chruby/chruby.sh && chruby 2.2
hash -d gem=$HOME/.gem/ruby/2.2.0/gems
alias be="bundle exec"

# Rails
alias rs="rails s"
alias rc="rails c"

# Git
alias g='LANGUAGE=C.UTF-8 git'
alias gs='g status -s'
alias gg='g grep'

# MongoDB
alias mongogen="mongo --eval 'a=[]; for(var i=0;i<10;i++) a.push(ObjectId()); a.join(\"\\n\")'"

# Path
export PATH="bin:$PATH"
