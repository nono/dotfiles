# Env
export PS1='%~ $(git_branch)%# '
export PS2=' > '
export DIRSTACKSIZE=16
export EDITOR=vim
export PAGER=less
export BROWSER=w3m
export PATH=/opt/bin:$PATH
export MANPATH=/opt/share/man:$MANPATH
export LS_OPTIONS='--color=auto'
export GREP_COLOR='1;37;41'
# eval `dircolors ~/.dir_colors`
umask 022

# disable XON/XOFF flow control (^s/^q)
stty -ixon

# History
HISTFILE=~/.zsh_hist
HISTSIZE=5000
SAVEHIST=1000

# VI bindings
# Use 'cat -v' to obtain the keycodes
bindkey -v
bindkey "^[[2~" overwrite-mode       ## Inser
bindkey "^[[3~" delete-char          ## Del
bindkey "^[[7~" beginning-of-line    ## Home
bindkey "^[[8~" end-of-line          ## End
bindkey "^[[5~" up-line-or-history   ## PageUp
bindkey "^[[6~" down-line-or-history ## PageDown
bindkey "^[[A" up-line-or-search     ## up arrow for back-history-search
bindkey "^[[B" down-line-or-search   ## down arrow for fwd-history-search
bindkey " " magic-space              ## do history expansion on space

# zsh
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt RM_STAR_SILENT
setopt HASH_CMDS
setopt HASH_DIRS
setopt PRINT_EXIT_VALUE
setopt NO_BG_NICE
setopt NO_BEEP
setopt PROMPT_SUBST

zmodload -i zsh/complist
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion::complete:*' cache-path ~/.zsh/cache

autoload -U compinit
compinit

source /etc/zsh_command_not_found

# Aliases
alias -g L='|less'
alias -g G='|grep'
alias -g T='|tail'
alias -g H='|head'
alias -g N='&>/dev/null&'
alias -g W='|wc'
alias -g C='|colordiff'

alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -la'
alias less='less -R'
alias grep='grep --color'
alias ack='ack-grep'
alias ftp='lftp'
alias cal='LANG=fr_FR cal -m'
alias minicom="TERM=xterm minicom"

alias cd..='cd ..'
alias sl=ls

# Aptitude
alias ai='sudo aptitude install'
alias au='sudo aptitude update'
alias ad='sudo aptitude dist-upgrade'
alias as='aptitude search'

# Ruby
export RI="--system -Tf ansi"
alias dec2hex="ruby -ne 'printf \"%d = 0x%02x\n\", \$_, \$_'"
alias epoch2date="ruby -ne 'puts Time.at(\$_.to_i)'"

# Gems
export RUBYOPT="-rubygems"
export GEM_HOME="$HOME/gem"
export RUBYLIB="$HOME/lib:./lib:./ext"
export PATH="$HOME/bin:$GEM_HOME/bin:$PATH"
alias cdgem="cd $GEM_HOME/gems"

# Rails
alias sc=./script/console
alias ss=./script/server

# Merb
alias m="merb -a thin"
alias mi="merb -i"

# Git
alias gs='git status'
function git_branch {
  git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1) /'
}

