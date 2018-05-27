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
alias gprom='git pull --rebase origin master'
alias gpu='git push -u origin "$(git symbolic-ref --short HEAD)"'
alias grhr='git reset --hard'
alias gril='rm .git/index.lock'
alias gsbu='git status -sbu'
alias gsn='git add .; git commit --no-verify -m "wip"; git reset HEAD~'
alias gtt='git-task-types'
alias pulls='open "https://github.com:/$(git remote -v | /usr/bin/grep -oP "(?<=git@github.com:).+(?=\.git)" | HEAD -n 1)/pulls"'

################################################################################
# nix
alias nxt='cd ~ && sudo nixos-rebuild test; cd -'
alias nxs='cd ~ && sudo nixos-rebuild switch; cd -'
alias nxsr='cd ~ && sudo nixos-rebuild switch && sudo reboot'
alias nq='nix-env -qaP'
alias nqu='NIXPKGS_ALLOW_UNFREE=1 nix-env -qaP'
alias ne='nix-env'

################################################################################
# repeats
# defaults write -g KeyRepeat -int 1
# defaults write -g InitialKeyRepeat -int 20

################################################################################
# shell
function check-time() {
  timedatectl | grep "Local" | sed -r "s/^\s*(\S+\s+){4}(\S+)\s+\S+$/\2/"
}
function check-battery() {
  percentage=`upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep "percentage:" \
    | sed -r "s/\s*\S+\s+(.*)$/\1/"`
  echo "Battery is at $percentage."
}

alias zz='source ~/.zshrc'
alias xmrg='xrdb -merge ~/.Xresources'
alias tm='check-time'
alias bat='check-battery'

################################################################################
# redshift
alias red='redshift -O 1000k -b 0.5'
alias orng='redshift -O 2000k'
alias blue='redshift -O 6000k'
