# -*- shell-script -*-

################################################################################
# gpg

function sign-and-send {
  gpg --sign-key "${1}" && gpg --send-keys "${1}"
}


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


################################################################################
# Python aliases

function grid-create-revision() {
  nix-shell --run "alembic revision -m '${1}'"
}

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

# shells
function uuid-gen-n() {
  nix-shell --argstr "$1" ~/.shells/uuid.nix --run "echo \"$UUID_GEN_N\""
}


################################################################################
# docker

function docker-compose-restart-and-log() {
  docker-compose restart "$1" && docker-compose logs -f "$1"
}

function docker-compose-hard-restart() {
  docker-compose stop "$1" && yes | docker-compose rm "$1" && docker-compose up -d "$1"
}

function docker-compose-hard-restart-and-log() {
  docker-compose stop "$1" && yes | docker-compose rm "$1" && docker-compose up -d "$1" && docker-compose logs -f "$1"
}


################################################################################
# kubernetes

function kpods-by-app() {
  kubectl get pods --selector="app=${1}"
}

function kube-get-secret() {
  kubectl get secret "$1" -o json | jq -r "$2" | base64 -D | cat
}


################################################################################
# Stackdriver

function google-logs() {
  gcloud logging read "labels.\"compute.googleapis.com/resource_name\"=$1 $2" --limit 10 --format json
}


################################################################################
  # dev servers

  alias sshml="ssh cameron@${ML_1_IP_ADDR}"
  alias sshmll="ssh cameron@${ML_2_IP_ADDR}"
  alias sshvpn="ssh cameron@${VPN_IP_ADDR}"
  alias sshadmin="ssh cameron@${ADMIN_IP_ADDR}"

################################################################################
# shell

function take-dir() {
  mkdir -p "$1" && cd "$1"
}

################################################################################
# 1Pass retrieval

function op-retrieve() {
  op get item "${1}" | jq '.details.password' | tr -d \" | tr -d '\n' | xclip -selection clipboard
}
function op-retrieve-vpn() {
  op get item VPN | jq '.details.fields[0].value' | tr -d \" | tr -d '\n' | xclip -selection clipboard
}
function op-list() {
  op list "${1}" | jq -c 'map(.overview.title) | sort'
}
function op-retrieve-tripwire() {
  op get item "Tripwire Local Passphrase" | jq '.details.password' | tr -d \" | tr -d '\n' | xclip -selection clipboard
}

################################################################################
# Productivity

function timer() {
  $(sleep "$1" && notify-send "$2" && espeak "$2" 2>/dev/null) &
}

################################################################################
# Urbint VPN

# come up with a nice way to put this in the bg while passing these args later
function urbint-vpn() {
  sudo openvpn --config ~/urbint.ovpn --auth-user-pass
}
