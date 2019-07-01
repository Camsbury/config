# -*- shell-script -*-

if [ $(uname -s) = "Linux" ]; then
  # Path to your oh-my-zsh installation.
  export ZSH=$OH_MY_ZSH

  # autojump integration
  source $AUTOJUMP/autojump.zsh

  plugins=(
    git
    zsh-autosuggestions
  )
fi

if [ $(uname -s) = "Darwin" ]; then

  # If you come from bash you might have to change your $PATH.
  export PATH=$HOME/bin:/usr/local/bin:$PATH

  # Path to your oh-my-zsh installation.
  export ZSH=$HOME/.oh-my-zsh

  # zsh completions
  fpath=(~/.zsh/completion $fpath)

  # docker completions?
  autoload -Uz compinit && compinit -i

  # postgres in path...
  export PATH=/usr/local/Cellar/postgresql/11.1_1/bin:$PATH

  # Secrets stuff
  if [ -f "$HOME/.secrets.zsh.inc" ]; then source "$HOME/.secrets.zsh.inc" ; fi

  # drone env variables
  export DRONE_TOKEN=$DRONE_TOKEN_PRIVATE
  export DRONE_SERVER=https://ci.urbinternal.com

  # stack Haskell path add
  export PATH=$PATH:$HOME/.local/bin

  # cabal path add
  export PATH=$PATH:$HOME/.cabal/bin

  # anaconda path add
  export PATH=$PATH:~/anaconda/bin

  # export nix related
  source $HOME/.nix-profile/etc/profile.d/nix.sh
  export NIX_PATH=darwin-config=$HOME/.nixpkgs/darwin-configuration.nix:$HOME/.nix-defexpr/channels:$NIX_PATH
  export NIX_PATH=darwin=$HOME/.nix-defexpr/channels/darwin:$NIX_PATH
  # Add darwin-nix to path
  export PATH=$(nix-build '<darwin>' -A system --no-out-link)/sw/bin/:$PATH

  # zsh plugins
  plugins=(git zsh-autosuggestions alias-tips kubetail)
fi

ZSH_THEME="robbyrussell"

# get oh-my-zsh
source $ZSH/oh-my-zsh.sh

if [ $(uname -s) = "Linux" ]; then
  # fzf integration
  source $FZF/key-bindings.zsh

  # set up keychain
  export GPG_TTY=$(tty)
  eval $(keychain --eval --agents ssh id_rsa)
  eval $(keychain --eval --agents gpg D3F6CEF58C6E0F38)
fi

if [ $(uname -s) = "Darwin" ]; then
  # fzf things
  [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

  # key repeat speed up
  defaults write -g KeyRepeat -int 1
  defaults write -g InitialKeyRepeat -int 20

  # autojump
  [ -f /usr/local/etc/profile.d/autojump.sh ] && . /usr/local/etc/profile.d/autojump.sh

  # The next line updates PATH for the Google Cloud SDK.
  if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then source "$HOME/google-cloud-sdk/path.zsh.inc"; fi

  # The next line enables shell command completion for gcloud.
  if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then source "$HOME/google-cloud-sdk/completion.zsh.inc"; fi
fi


# User configuration

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

################################################################################
# gpg

# git config --global commit.gpgsign true
# git config --global user.signingkey $KEY

function sign-and-send {
  gpg --sign-key "${1}" && gpg --send-keys "${1}"
}

alias pgz='gpg --list-secret-keys --keyid-format LONG'
alias pgr='gpg --recv-keys'
alias pgl='gpg --list-keys'
alias pgs='sign-and-send'


################################################################################
# tmux

function tt() {
  sessionName="${1}"
  if ! tmux has-session -t "${sessionName}" 2> /dev/null; then
    oldTMUX="${TMUX}"
    unset TMUX
    tmux new -d -s "${sessionName}"
    export TMUX="${oldTMUX}"
    unset oldTMUX
  fi
  if [[ -n "${TMUX}" ]]; then
    tmux switch-client -t "${sessionName}"
  else
    tmux attach -t "${sessionName}"
  fi
}

alias tls='tmux list-sessions'


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

function cd-git-head() {
  cd "$(git rev-parse --show-toplevel)"
}

function git-branch-delete-pattern() {
  git branch -D `git branch | grep -E ${1}`
}

function git-branch-checkout-pattern() {
  git checkout `git branch | grep -E ${1} | sed -n 1p`
}

function git-force-pull() {
  commit="${1:-$(git symbolic-ref --short HEAD)}"
  git fetch && git reset --hard origin/"${commit}"
}

alias git='hub'

alias gb='git branch | cat'
alias gbdd='git branch -D'
alias gbdp='git-branch-delete-pattern'
alias gbm='git branch --merged'
alias gcan='git commit --no-edit --amend'
alias gcop='git-branch-checkout-pattern'
alias gdh='git diff HEAD~ HEAD'
alias gds='git diff --staged'
alias gfl='git-files'
alias gfx='git commit --fixup'
alias gi='git init'
alias glf='git-force-pull'
alias glfm='git fetch && git reset --hard origin/master'
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
alias ghsh="git rev-parse --short head"

alias cdg='cd-git-head'


################################################################################
# Python aliases

function grid-create-revision() {
  nix-shell --run "alembic revision -m '${1}'"
}

alias auh='nix-shell --run "alembic upgrade head"'
alias adw='nix-shell --run "alembic downgrade -1'
alias grev='grid-create-revision'


################################################################################
# C

alias gseg='gdb --batch --ex run --ex bt --ex q --args'
alias bam='bear -a make'

################################################################################
# redshift

alias red='redshift -PO 1000k -b 0.3'
alias orng='redshift -PO 2000k -b 0.6'
alias blue='redshift -x'

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
    echo "update cache" && NIXPKGS_ALLOW_UNFREE=1 nix-env -qa --json > "$CACHE"
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

if [ $(uname -s) = "Darwin" ]; then
  alias dxs='darwin-rebuild switch'
fi
if [ $(uname -s) = "Linux" ]; then
  alias npk="sudo nixos-option environment.systemPackages | head -2 | tail -1 | \
    sed -e 's/ /\n/g' | cut -d- -f2- | sort | uniq"
  alias npka="sudo nix-store --query --requisites /run/current-system | cut -d- -f2- | sort | uniq"
  alias nxs='cd ~ && sudo nixos-rebuild switch; cd -'
  alias nxsr='cd ~ && sudo nixos-rebuild switch && sudo reboot'
  alias nxt='cd ~ && sudo nixos-rebuild test; cd -'
fi
alias nb='nix-build'
alias ndeps='nix-store-deps'
alias ndtree='nix-store-deps-tree'
alias ndx='nix-index'
alias ne='nix-env'
alias nev='nix eval'
alias nhash='nix-prefetch-url --type sha256'
alias nq='nix-query'
alias nl='nix-env -q'
alias nq='nix-query'
alias nqu='NIXPKGS_ALLOW_UNFREE=1 nix-env -qaP'
alias nr='nix repl'
alias nrp="nix repl '<nixpkgs>'"
alias ns='nix-shell'
alias nsp='nix-shell --pure'
alias nsref='nix-store-references'
alias nsrefr='nix-store-referrers'
alias nst='nix-store'
alias nstp='nix-store-path'
alias nsu="nix-shell --arg nixpkgs 'import <nixpkgs-unstable> {}'"

# shells
alias dana='nix-shell ~/.shells/dataAnalysis.nix'
alias fpy='nix-shell ~/.shells/yapf.nix'


################################################################################
# cabal

# Write scripts for these to make them available in the shell
# use a default shell.nix bash script to set all these aliases up!
alias nbhs="nix-build -E 'with import <nixpkgs> {}; haskellPackages.callCabal2nix "foo" ./. {}'"
alias nshs="nix-shell -E 'with import <nixpkgs> {}; (haskellPackages.callCabal2nix "foo" ./. {}).env'"
alias cbw='ghcid -c "cabal repl lib:bobby" | source-highlight -s haskell -f esc'
alias ctw='ghcid -c "cabal repl test:bobby-tests" --warnings --test "Main.main" | source-highlight -s haskell -f esc'
alias cbi='cabal build --ghc-option=-ddump-minimal-imports'


################################################################################
# chunkwm utility

if [ $(uname -s) = "Darwin" ]; then
  function upgrade-chunkwm() {
      brew reinstall --HEAD chunkwm
      codesign -fs "chunkwm-cert" $(brew --prefix chunkwm)/bin/chunkwm
      brew services restart chunkwm
  }
  alias uch='upgrade-chunkwm'
fi


################################################################################
# slack dark theme

if [ $(uname -s) = "Darwin" ]; then
  function dark-slack() {

  echo "\ndocument.addEventListener('DOMContentLoaded', function() {
   $.ajax({
     url: 'https://cdn.rawgit.com/laCour/slack-night-mode/master/css/raw/black.css',
     success: function(css) {
       \$(\"<style></style>\").appendTo('head').html(css);
     }
   });
  });" >> /Applications/Slack.app/Contents/Resources/app.asar.unpacked/src/static/ssb-interop.js
  }
fi


################################################################################
# docker

function docker-restart-and-log() {
  docker-compose restart "$1" && docker-compose logs -f "$1"
}

alias dcud='docker-compose up -d'
alias dclf='docker-compose logs -f'
alias dc='docker-compose'
alias dcub='docker-compose up --build -d'
alias dcr='docker-compose restart'
alias dps='docker ps'
alias dsac='docker stop $(docker ps -aq)'
alias drac='docker rm $(docker ps -aq)'
alias dcrf="docker-restart-and-log"
if [ $(uname -s) = "Darwin" ]; then
  alias dcrb="docker-compose restart server internal_server celery celery-beat celery-process-video celery-classify-frames celery-upload-video-to-gcs"
  alias dclb="docker-compose logs -f server internal_server celery celery-beat celery-process-video celery-classify-frames celery-upload-video-to-gcs"
fi
alias dk="docker"
alias drni="docker rmi $(docker images | grep '^<none>' | awk '{print $3}')"
alias drdi="docker rmi $(docker images -q -f "dangling=true")"
alias drmc="docker rm $(docker ps -q -f 'status=exited')"


################################################################################
# kubernetes

function kpods-by-app() {
  kubectl get pods --selector="app=${1}"
}

function kube-get-secret() {
  kubectl get secret "$1" -o json | jq -r "$2" | base64 -D | cat
}

alias kc='kubectl'
alias kt='kubetail'
if [ $(uname -s) = "Darwin" ]; then
  alias klj='kubetail grid-jobs'
  alias kls='kubetail server'
  alias klb='kubetail "grid-(server|jobs|celery\S*)" --regex'
fi
alias kp='kubectl get pods'
alias ks='kubernetes_switch_project.sh'
alias kpn='kpods-by-app'
alias kdys='kubectl get deployments'
alias kgs='kube-get-secret'
alias ksrvs='kubectl get services'
alias kpw='kubectl get pods -w'
alias klf='kubectl logs -f'
alias gclc='gcloud container clusters get-credentials' # followed by the cluster name


################################################################################
# Stackdriver

function google-logs() {
  gcloud logging read "labels.\"compute.googleapis.com/resource_name\"=$1 $2" --limit 10 --format json
}

alias lglg='google-logs'


################################################################################
# server ssh

alias sshml="ssh cameron@${ML_1_IP_ADDR}"
alias sshmll="ssh cameron@${ML_2_IP_ADDR}"
alias sshvpn="ssh cameron@${VPN_IP_ADDR}"
alias sshadmin="ssh cameron@${ADMIN_IP_ADDR}"


################################################################################
# R
alias nsr='nix-shell ~/projects/Camsbury/config/rSetup.nix --run emacs'


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
# 1Pass retrieval

function op-retrieve() {
  op get item "${1}" | jq '.details.password' | tr -d \" | tr -d '\n' | xclip -selection clipboard
}

alias opl="op list items | jq -c 'map(.overview.title) | sort'"
alias opp='op-retrieve'
alias opg="op get item GPG | jq '.details.password'"
alias ops='eval $(op signin urbint)'


################################################################################
# emacs

alias emd='emacs --debug-init'


################################################################################
# yarn

alias yin='yarn install'
alias ybw='yarn build:watch'
alias nprm='rm -rf */node_modules'
alias ybwr='cd ~/projects/urbint/grid && rm -rf */node_modules && yarn install && cd urbint-components && yarn build:watch'


################################################################################
# Ergodox Flashing

alias ezs='sudo teensy-loader-cli -vw --mcu atmega32u4'

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/ckingsbury/google-cloud-sdk/path.zsh.inc' ]; then source '/Users/ckingsbury/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/ckingsbury/google-cloud-sdk/completion.zsh.inc' ]; then source '/Users/ckingsbury/google-cloud-sdk/completion.zsh.inc'; fi
