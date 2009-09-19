# Env
export PS1='${SSH_CONNECTION+"%n@%m:"}%~$(parse_git_branch)%# '
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

# Use 'cat -v' to obtain the keycodes
bindkey "^[[2~" overwrite-mode       ## Inser
bindkey "^[[3~" delete-char          ## Del
bindkey "^[[7~" beginning-of-line    ## Home
bindkey "^[[8~" end-of-line          ## End
bindkey "^[[5~" up-line-or-history   ## PageUp
bindkey "^[[6~" down-line-or-history ## PageDown
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

# Completion
fpath=(~/.zsh/Completion $fpath)
zmodload -i zsh/complist
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion::complete:*' cache-path ~/.zsh/cache
autoload -U ~/.zsh/Completion/*(:t)
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
alias lh='ls $LS_OPTIONS -lah'
alias less='less -R'
alias grep='grep --color'
alias ack='ack-grep'
alias ftp='lftp'
alias mplayer='mplayer -fs'
alias serve='thin -A file start'

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
hash -d gem="$GEM_HOME/gems"

# Rails
alias sc="./script/console"
alias ss="./script/server thin"
alias sd="./script/dbconsole"
alias sg="./script/generate"
alias mi='rake db:migrate'

# Git
alias g='git'
alias gs='git status'
function parse_git_dirty {
  [[ $(git status 2> /dev/null | tail -n1) != "nothing to commit (working directory clean)" ]] && echo "*"
}
function parse_git_branch {
  git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/ [\1$(parse_git_dirty)] /"
}

# Svn
alias svnclear='find . -name .svn -print0 | xargs -0 rm -rf'
alias svnaddall='svn status | grep "^\?" | awk "{print \$2}" | xargs svn add'

