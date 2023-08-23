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
HISTSIZE=100000
SAVEHIST=100000

# Use 'cat -v' to obtain the keycodes
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "$key[Up]" up-line-or-beginning-search
bindkey "$key[Down]" down-line-or-beginning-search
bindkey "^[[1;5D" backward-word      ## ctrl-right
bindkey "^[[1;5C" forward-word       ## ctrl-left
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
source /etc/zsh_command_not_found
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Automatically list files after cd
autoload -U add-zsh-hook
add-zsh-hook -Uz chpwd (){ exa; }

# fzf
source ~/.fzf/shell/key-bindings.zsh
source ~/.fzf/shell/completion.zsh
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

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
alias ll='exa -la'
alias lt='exa -laT'
alias less='less -RXFS'
alias v=nvim
alias o=xdg-open
alias m=make
alias pw='diceware -d _ -n 5 -s 5'
alias notes="rg 'TODO|FIXME|XXX|HACK'"
alias serve='thin -A file start'
alias mysql='mysql --select_limit=1000'
alias ssh='TERM=xterm ssh'

mkcd() { mkdir -p "$1" && cd "$1" }
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

# Alloy
export _JAVA_OPTIONS='-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true -Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel -Dswing.crossplatformlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel'

# Golang
export GOPATH="$HOME/go"
export PATH="$GOPATH/bin:$HOME/vendor/go/bin:$PATH"
alias gr='go run .'
alias doc='GODOCC_STYLE=native godocc'

# Node.js
export VOLTA_HOME="$HOME/.volta"
export PATH="node_modules/.bin:$VOLTA_HOME/bin:$PATH"
export NODE_PATH="./lib"

# Ruby
export RUBYLIB="./ext:./lib"
export NOKOGIRI_USE_SYSTEM_LIBRARIES="true"
export GEM_HOME=$HOME/.gem
export PATH="$GEM_HOME/bin:$PATH"
alias be="bundle exec"

# Git
alias g='LANGUAGE=C.UTF-8 git'
alias gs='g status -s'
alias gd='g diff'
alias gp='g pull origin $(git default-branch) --rebase'
alias gpf='g push --force-with-lease'
alias gri='git rebase -i $(git merge-base $(git rev-parse --abbrev-ref HEAD) $(basename $(git symbolic-ref refs/remotes/origin/HEAD)))'

# Gleam
alias gl=gleam

# Cozy
alias ng="cd ~/cc/desktop/ng"
alias sta="cd ~/cc/stack"
alias nua="cd ~/cc/nuagerie"
alias ddp="cd ~/cc/dedup"
alias cs=cozy-stack
alias csls="cozy-stack instances ls --fields=domain,context,prefix"
export COZY_FS_URL=file://localhost/home/nono/cc/stack/storage
export COZY_DESKTOP_DIR=tmp
cozy_token() {
  export CLIENT_ID=$(cozy-stack instances client-oauth cozy.localhost:8080 http://localhost/ cli github.com/cozy/cozy-stack)
  export TOKEN=$(cozy-stack instances token-oauth cozy.localhost:8080 $CLIENT_ID "$@")
  echo "TOKEN is available as \$TOKEN: $TOKEN (and \$CLIENT_ID for the client id)"
}
alias remove_cozy_test="cozy-stack instances ls | grep test | awk '{ print \$1 }' | xargs -n1 cozy-stack instances rm --force"
alias tunnel_couch_int="ssh -L 5981:ha-couch-int.service.consul-dev:5984 bounce"
alias tunnel_couch_stg="ssh -L 5982:ha-couch-stg.service.consul:5984 bounce"
alias tunnel_couch_prod="ssh -L 5983:ha-couch-prod.service.consul:5984 bounce"
alias tunnel_couch_maif="ssh -L 5980:ha-couch-01.maif.cozycloud.cc:5984 bounce-maif"
