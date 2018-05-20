# Path to your oh-my-zsh installation.
export ZSH=$OH_MY_ZSH

ZSH_THEME="robbyrussell"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
plugins=(
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
  commit="${1:-head}"
  git show --pretty="" --name-only "${commit}" | cat
}

alias git='hub'

alias gbdd='git branch -D'
alias gbm='git branch --merged'
alias gcan='git commit --no-edit --amend'
alias gdh='git diff head~ head'
alias gds='git diff --staged'
alias gfl='git-files'
alias gfx='git commit --fixup'
alias gi='git init'
alias glp="git log --graph --pretty=format:'%Cred%h%Creset -%Cblue %an %Creset - %C(yellow)%d%Creset %s %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"
alias gpf='git push --force'
alias gpop='git reset head~'
alias gpr='git pull-request'
alias gprom='git pull --rebase origin master'
alias gpu='git push -u origin "$(git symbolic-ref --short HEAD)"'
alias grhr='git reset --hard'
alias gril='rm .git/index.lock'
alias gsbu='git status -sbu'
alias gsn='git add .; git commit --no-verify -m "wip"; git reset head~'
alias gtt='git-task-types'
alias pulls='open "https://github.com:/$(git remote -v | /usr/bin/grep -oP "(?<=git@github.com:).+(?=\.git)" | head -n 1)/pulls"'

################################################################################
# nix
alias nqp='nix-env -qaP'

################################################################################
# repeats
# defaults write -g KeyRepeat -int 1
# defaults write -g InitialKeyRepeat -int 20

################################################################################
# shell
alias zz='source ~/.zshrc'

################################################################################
# autojump
[ -f /usr/local/etc/profile.d/autojump.sh ] && . /usr/local/etc/profile.d/autojump.sh
