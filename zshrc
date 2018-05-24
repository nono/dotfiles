# Env
export PS1='${SSH_CONNECTION+"%n@%m:"}%~%# '
export PS2=' > '
export DIRSTACKSIZE=16
export EDITOR=nvim
export PAGER=less
export BROWSER=firefox
umask 022

# disable XON/XOFF flow control (^s/^q)
stty -ixon

# History
setopt HIST_IGNORE_SPACE
HISTFILE=~/.zsh_hist
HISTSIZE=10000
SAVEHIST=3000

# Use 'cat -v' to obtain the keycodes
bindkey "^[[1;5D" backward-word      ## ctrl-right
bindkey "^[[1;5C" forward-word       ## ctrl-left
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
fpath=(~/.zsh/Completion ~/.zsh/functions ~/.nix-profile/share/zsh/site-functions $fpath)
zmodload -i zsh/complist
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion::complete:*' cache-path ~/.zsh/cache
zstyle ':completion::complete:cd::' tag-order local-directories path-directories
zstyle ':completion:*:processes' command 'ps -au$USER'
zstyle ':completion:*:*:kill:*:processes' list-colors "=(#b) #([0-9]#)*=36=31"
autoload -U compinit
compinit -u
autoload -U promptinit && promptinit
export DEFAULT_USER=nono
prompt unpure

# Add some colors
source ~/config/zsh/base16-bright.dark.sh
source /etc/zsh_command_not_found
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Automatically list files after cd
autoload -U add-zsh-hook
add-zsh-hook -Uz chpwd (){ exa; }

# Nix
source ~/.nix-profile/etc/profile.d/nix.sh
alias ni='nix-env -i'
alias ns='nix search'
alias nrm='nix-env -e'

# Apt
alias ai='sudo apt install'
alias au='sudo apt update'
alias ad='sudo apt upgrade'
alias aud='sudo apt-get autoremove --purge && sudo apt update && sudo apt upgrade'
alias arm='sudo apt remove'
alias as='apt search'

# Aliases
alias -g L='|less'
alias -g G='|rg'
alias -g W='|wc'

alias ls='exa'
alias ll='exa -la --git'
alias lt='exa -laT'
alias less='less -RXFS'
alias v=nvim
alias o=xdg-open
alias beep='mpv /usr/share/sounds/freedesktop/stereo/complete.oga'
alias ftp='lftp'
alias pw='diceware -d _ -n 5 -s 5'
alias notes="rg 'TODO|FIXME|XXX|HACK'"
alias serve='thin -A file start'
alias mysql='mysql --select_limit=1000'
alias pop='~/.Popcorn-Time/Popcorn-Time'
alias ssh='TERM=rxvt-unicode ssh'

mkcd() { mkdir "$1" && cd "$1" }
font() { echo -ne "\\033]710;xft:Fira Code:pixelsize=$1\\007" }
rule() { printf "%$(tput cols)s\n" | tr " " "-" }

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

# For git diff
strip_diff_leading_symbols() {
  color_code_regex="(\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K])"
  sed -r "s/^($color_code_regex)diff --git .*$//g" | \
    sed -r "s/^($color_code_regex)index .*$/\n\1$(rule)/g" | \
    sed -r "s/^($color_code_regex)\+\+\+(.*)$/\1+++\5\n\1$(rule)\x1B\[m/g" |\
    sed -r "s/^($color_code_regex)[\+\-]/\1 /g"
}

# Golang
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$PATH"

# Node.js
export PATH="node_modules/.bin:$PATH"
export NODE_PATH="./lib"
export NODE_ENV=development
export NVM_DIR="/home/nono/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
. <(npm completion)

# Ruby
export RUBYLIB="./ext:./lib"
export NOKOGIRI_USE_SYSTEM_LIBRARIES="true"
export GEM_HOME=$HOME/.gem
export PATH="$GEM_HOME/bin:$PATH"
hash -d gem=$GEM_HOME
alias be="bundle exec"

# Rails
alias rs="rails s"
alias rc="rails c"

# Git
alias g='LANGUAGE=C.UTF-8 git'
alias gs='g status -s'
alias gg='g grep --color'
alias gp='g pull upstream master --rebase'
alias gu='g push upstream && g push'
alias gpf='g push --force-with-lease'
gd() { g diff --color $@ | diff-highlight | strip_diff_leading_symbols | less }

# Cozy
hash -d stack="$GOPATH/src/github.com/cozy/cozy-stack"
alias sta="cd ~stack"
alias cs=cozy-stack
export COZY_FS_URL=file://localhost/home/nono/go/src/github.com/cozy/cozy-stack/storage
export COZY_DESKTOP_DIR=tmp
alias create_cozy_tools="COZY_ADMIN_TIMEOUT=5m cozy-stack instances add cozy.tools:8080 --dev --passphrase cozy --apps drive,photos,settings,collect,contacts --email bruno@cozycloud.cc --locale fr --public-name Bruno --context-name dev"
cozy_token() {
  export CLIENT_ID=$(cozy-stack instances client-oauth cozy.tools:8080 http://localhost/ cli github.com/cozy/cozy-stack)
  export TOKEN=$(cozy-stack instances token-oauth cozy.tools:8080 $CLIENT_ID "$@")
}
alias remove_cozy_test="cozy-stack instances ls | grep sharing_test | awk '{ print \$1 }' | xargs -n1 cozy-stack instances rm --force"
