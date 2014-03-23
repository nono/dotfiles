# Env
export PATH="$HOME/bin:$PATH"
export PS1='${SSH_CONNECTION+"%n@%m:"}%~$(parse_git_branch)%# '
export PS2=' > '
export DIRSTACKSIZE=16
export EDITOR=vim
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

# Completion
fpath=(~/.zsh/Completion $fpath)
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
alias ftp='lftp'
alias notes="ag 'TODO|FIXME|XXX|HACK'"
alias serve='thin -A file start'
alias mysql='mysql --select_limit=1000'
alias dec2hex="ruby -ne 'printf \"%d = 0x%02x\n\", \$_, \$_'"
alias epoch2date="ruby -ne 'puts Time.at(\$_.to_i)'"

mplay() { xrandr --output DVI-I-1 --mode 1920x1080 ; sleep 3 ; mplayer -fs $@ ; xrandr --output DVI-I-1 --mode 2560x1440 }
font() { echo -ne "\\033]710;xft: Inconsolata:pixelsize=$1\\007" }
pretty() { pygmentize -f terminal "$1" | less -R }

# Aptitude
alias ai='sudo aptitude install'
alias au='sudo aptitude update'
alias ad='sudo aptitude upgrade'
alias arm='sudo aptitude remove'
alias as='aptitude search'

# Golang
export GOPATH="$HOME"
source $(go env GOROOT)/misc/zsh/go

# Node.js
export NODE_PATH="./lib"
. <(npm completion)

# Ruby
export RUBYLIB="./lib"
export NOKOGIRI_USE_SYSTEM_LIBRARIES="true"
source ~/share/chruby/chruby.sh && chruby 2.1
hash -d gem=$HOME/.gem/ruby/2.1.1/gems
alias be="bundle exec"

# Rails
alias rs="./script/rails s thin"
alias rc="./script/rails c"

# Git
alias gs='git st'
parse_git_dirty() { [[ $(git status 2> /dev/null | tail -n1) != "nothing to commit, working directory clean" ]] && echo "*" }
parse_git_branch() { git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/ [\1$(parse_git_dirty)] /" }

# MongoDB
alias mongogen="mongo --eval 'a=[]; for(var i=0;i<10;i++) a.push(ObjectId()); a.join(\"\\n\")'"
