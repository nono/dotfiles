# Env
export PATH="$HOME/bin:$PATH"
export PS1='${SSH_CONNECTION+"%n@%m:"}%~$(parse_git_branch)%# '
export PS2=' > '
export DIRSTACKSIZE=16
export EDITOR=vim
export PAGER=less
export BROWSER=firefox-trunk
export LS_OPTIONS='--color=auto'
export GREP_COLOR='1;37;41'
cdpath=(~ ~/dev)
umask 022

# disable XON/XOFF flow control (^s/^q)
stty -ixon

# History
HISTFILE=~/.zsh_hist
HISTSIZE=5000
SAVEHIST=1000

# Use 'cat -v' to obtain the keycodes
bindkey "^[[2~" overwrite-mode       ## Inser
bindkey "^[[3~" delete-char          ## Del
bindkey "^[[7~" beginning-of-line    ## Home
bindkey "^[[8~" end-of-line          ## End
bindkey "^[[5~" up-line-or-history   ## PageUp
bindkey "^[[6~" down-line-or-history ## PageDown
bindkey "^[[A" up-line-or-search     ## up arrow for back-history-search
bindkey "^[[B" down-line-or-search   ## down arrow for fwd-history-search
bindkey "\C-b" backward-word         ## ctrl-b
bindkey "\C-f" forward-word          ## ctrl-f
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

# Completion
fpath=(~/.zsh/Completion $fpath)
zmodload -i zsh/complist
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion::complete:*' cache-path ~/.zsh/cache
zstyle ':completion::complete:cd::' tag-order local-directories path-directories
zstyle ':completion:*:(all-|)files' ignored-patterns '*.rbc'
zstyle ':completion:*:processes' command 'ps -au$USER'
zstyle ':completion:*:*:kill:*:processes' list-colors "=(#b) #([0-9]#)*=36=31"
autoload -U ~/.zsh/Completion/*(:t)
autoload -U compinit
compinit -u

source /etc/zsh_command_not_found

# Aliases
alias -g L='|less'
alias -g G='|grep'
alias -g W='|wc'
alias -g C='|colordiff'

alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -la'
alias lh='ls $LS_OPTIONS -lah'
alias less='less -R'
alias grep='grep --color'
alias ack='ack-grep'
alias ftp='lftp'
alias notes="ack 'TODO|FIXME|XXX|HACK'"
alias serve='thin -A file start'
alias mysql='mysql --select_limit=1000'
alias mplayer='mplayer -fs'
alias dec2hex="ruby -ne 'printf \"%d = 0x%02x\n\", \$_, \$_'"
alias epoch2date="ruby -ne 'puts Time.at(\$_.to_i)'"

alias cd..='cd ..'
alias sl=ls

# Change font size in urxvt
function font {
  echo -ne "\\033]710;xft: Inconsolata:pixelsize=$1\\007"
}

# Aptitude
alias ai='sudo aptitude install'
alias au='sudo aptitude update'
alias ad='sudo aptitude safe-upgrade'
alias arm='sudo aptitude remove'
alias as='aptitude search'

# Golang
export GOROOT="/usr/lib/go"

# Python
export PYTHONPATH="$HOME/py:$PYTHONPATH"

# Node.js
export NODE_PATH="./lib"

# Ruby
[[ -s $HOME/.rvm/scripts/rvm ]] && source $HOME/.rvm/scripts/rvm && hash -d gem="$(rvm gemdir)/gems"
export RUBYLIB="./lib"
export USE_BUNDLER=try
alias irb=pry

# Rails
alias ss="rails server thin"
alias sc="rails console"
alias sp="rspec spec"

# Git
alias gs='git st'
function parse_git_dirty {
  [[ $(git status 2> /dev/null | tail -n1) != "nothing to commit (working directory clean)" ]] && echo "*"
}
function parse_git_branch {
  git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/ [\1$(parse_git_dirty)] /"
}

# Svn
alias unsvn='find . -name .svn -print0 | xargs -0 rm -rf'
alias svnaddall='svn status | grep "^\?" | awk "{print \$2}" | xargs svn add'

# MongoDB
alias start_mongo="mongod --fork --logpath /home/nono/var/log/mongo.log --dbpath /home/nono/var/data"
