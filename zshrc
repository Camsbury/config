# -*- shell-script -*-
# Path to your oh-my-zsh installation.
export ZSH=$OH_MY_ZSH

ZSH_THEME="robbyrussell"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
plugins=(
  # autojump
  git
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

# set up keychain
eval $(keychain --eval --agents ssh id_rsa)

# User configuration

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

################################################################################
# git

function git-task-types {
  echo "fix - bug patching"
  echo "feat - introducing a new feature"
  echo "test - adding tests"
  echo "perf - improving performance"
  echo "wip - placeholder tag signifying ongoing work"
  echo "deps - updating related to project dependencies"
  echo "docs - updating related to project documentation"
  echo "refactor - changing structure; functionality remains unchanged"
  echo "build - updating anything related to building and deploying"
}

function git-files() {
  commit="${1:-HEAD}"
  git show --pretty="" --name-only "${commit}" | cat
}

alias git='hub'

alias gbdd='git branch -D'
alias gbm='git branch --merged'
alias gcan='git commit --no-edit --amend'
alias gdh='git diff HEAD~ head'
alias gds='git diff --staged'
alias gfl='git-files'
alias gfx='git commit --fixup'
alias gi='git init'
alias glf='git fetch && git reset --hard origin/master'
alias glp="git log --graph --pretty=format:'%Cred%h%Creset -%Cblue %an %Creset - %C(yellow)%d%Creset %s %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"
alias gpf='git push --force'
alias gpop='git reset HEAD~'
alias gpr='git pull-request'
alias gprom='git fetch && git pull --rebase origin master'
alias gpu='git push -u origin "$(git symbolic-ref --short HEAD)"'
alias grhr='git reset --hard'
alias gril='rm .git/index.lock'
alias gsbu='git status -sbu'
alias gsn='git add .; git commit --no-verify -m "wip"; git reset HEAD~'
alias gtt='git-task-types'
alias pulls='open "https://github.com:/$(git remote -v | /usr/bin/grep -oP "(?<=git@github.com:).+(?=\.git)" | HEAD -n 1)/pulls"'

################################################################################
# C

alias gseg='gdb --batch --ex run --ex bt --ex q --args'
alias bam='bear -a make'

################################################################################
# redshift

alias red='redshift -O 1000k'
alias orng='redshift -O 2000k'
alias blue='redshift -O 6000k'

################################################################################
# nix

function nix-store-references() {
  nix-store -q --references `which "${1}"`
}

function nix-store-referrers() {
  nix-store -q --referrers `which "${1}"`
}

function nix-store-deps() {
  nix-store -qR `which "${1}"`
}

function nix-store-deps-tree() {
  nix-store -q --tree `which "${1}"`
}

function nix-store-path() {
  readlink -f `which "${1}"`
}

function nix-query () {
  local CACHE="$HOME/.cache/nq-cache"
  if ! ( [ -e $CACHE ] && [ $(stat -c %Y $CACHE) -gt $(( $(date +%s) - 3600 )) ] ); then
    echo "update cache" && nix-env -qa --json > "$CACHE"
  fi
  jq -r 'to_entries | .[] | .key + "|" + .value.meta.description' < "$CACHE" |
    {
       if [ $# -gt 0 ]; then
          # double grep because coloring breaks column's char count
          # $* so that we include spaces (could do .* instead?)
            grep -i "$*" | column -t -s "|" | grep --color=always -i "$*"
       else
            column -t -s "|"
       fi
    }
}

alias nb='nix-build'
alias ne='nix-env'
alias nhash='nix-prefetch-url --type sha256'
alias nq='nix-query'
alias nqu='NIXPKGS_ALLOW_UNFREE=1 nix-env -qaP'
alias nr='nix repl'
alias ns='nix-shell'
alias nsu="nix-shell --arg nixpkgs 'import <nixpkgs-unstable> {}'"
alias nsp='nix-shell -p'
alias nst='nix-store'
alias nsref='nix-store-references'
alias nsrefr='nix-store-referrers'
alias ndeps='nix-store-deps'
alias ndtree='nix-store-deps-tree'
alias nstp='nix-store-path'
alias nxs='cd ~ && sudo nixos-rebuild switch; cd -'
alias nxsr='cd ~ && sudo nixos-rebuild switch && sudo reboot'
alias nxt='cd ~ && sudo nixos-rebuild test; cd -'

################################################################################
# cabal

alias nhs='nix-shell --arg nixpkgs "import <nixpkgs-unstable> {}" --run "cabal new-repl"'
alias cbw='ghcid -c "cabal repl lib:bobby" | source-highlight -s haskell -f esc'
alias ctw='ghcid -c "cabal repl test:bobby-tests" --warnings --test "Main.main" | source-highlight -s haskell -f esc'
alias cbi='cabal build --ghc-option=-ddump-minimal-imports'

################################################################################
# shell

function take-dir() {
  mkdir -p "$1" && cd "$1"
}

alias cat='bat'
alias cclip='xclip -selection clipboard'
alias ls='exa --long'
alias ll='exa --long --all'
alias la='exa --long --all'
alias lnf='readlink -f'
alias take='take-dir'
alias xmrg='xrdb -merge ~/.Xresources'
alias zz='source ~/.zshrc'

################################################################################
# fzf integration - fix to be intelligent

source $FZF/key-bindings.zsh

################################################################################
# autojump integration - needs fixing just like fzf

source $AUTOJUMP/autojump.zsh
