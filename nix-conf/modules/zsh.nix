{ lib, config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;

    autosuggestions = {
      enable = true;
      highlightStyle = "fg=7";
    };

    interactiveShellInit =
      ''
      export TERM=xterm-256color # needed for autocompletions
      export FZF="${pkgs.fzf}/share/fzf" # this doesn't work until after omz is loaded
      source "${pkgs.autojump}/share/autojump/autojump.zsh"
      source "${pkgs.google-cloud-sdk}/google-cloud-sdk/path.zsh.inc"
      source "${../../helpers.zsh.inc}"

      ################################################################################
      # set up keychain
      export GPG_TTY=$(tty)
      eval $(keychain --eval --agents ssh id_rsa)
      eval $(keychain --eval --agents gpg D3F6CEF58C6E0F38)

      ################################################################################
      # set up direnv
      eval "$(direnv hook zsh)"
    '';

    ohMyZsh = {
      enable = true;
      plugins = [
        "alias-tips"
        "docker"
        "docker-compose"
        "git"
        "kubectl"
        "yarn"
      ];
      customPkgs = with pkgs; [
        alias-tips
        nix-zsh-completions
      ];

      theme = "robbyrussell";
    };

    shellAliases = {
      # shell
      apr = "apropos";
      cat = "bat";
      cclip = "xclip -selection clipboard";
      du = "dua";
      la = "exa --long --all";
      ll = "exa --long --all";
      lnf = "readlink -f";
      ls = "exa --long";
      psu = "ps -u";
      take = "take-dir";
      xmrg = "xrdb -merge ~/.Xresources";
      zz = "source /etc/zshenv; source /etc/zshrc; source $HOME/.zshrc";

      # gpg
      pgz = "gpg --list-secret-keys --keyid-format LONG";
      pgr = "gpg --recv-keys";
      pgl = "gpg --list-keys";
      pgs = "sign-and-send";

      # ssh
      # copy public key
      csh = "xclip -sel clip < ~/.ssh/id_rsa.pub";

      # systemd
      rsys = "systemctl --user daemon-reload";

      # git
      git = "hub";
      gb = "git branch | cat";
      gbdd = "git branch -D";
      gbdp = "git-branch-delete-pattern";
      gbm = "git branch --merged";
      gcan = "git commit --no-edit --amend";
      gcop = "git-branch-checkout-pattern";
      gdh = "git diff HEAD~ HEAD";
      gds = "git diff --staged";
      gfl = "git-files";
      gfx = "git commit --fixup";
      gi = "git init";
      glf = "git-force-pull";
      glfm = "git fetch && git reset --hard origin/master";
      glp = ''git log --graph --pretty=format:'%Cred%h%Creset -%Cblue %an %Creset - %C(yellow)%d%Creset %s %Cgreen(%cr)%Creset' --abbrev-commit --date=relative'';
      gpf = "git push --force";
      gpop = "git reset HEAD~";
      gpr = "git pull-request";
      gprom = "git fetch && git pull --rebase origin master";
      grhr = "git reset --hard";
      gril = "rm .git/index.lock";
      gsbu = "git status -sbu";
      gtt = "git-task-types";
      gpu = ''git push -u origin "$(git symbolic-ref --short HEAD)"'';
      gsn = '''git add .; git commit --no-verify -m "wip"; git reset HEAD~'';
      pulls = '''open "https://github.com:/$(git remote -v | /usr/bin/grep -oP "(?< = git@github.com:).+(? = \.git)" | HEAD -n 1)/pulls"'';
      cdg = "cd-git-head";
      ghsh = "git rev-parse --short head";

      # C
      gseg = "gdb --batch --ex run --ex bt --ex q --args";
      bam = "bear -a make";

      # redshift
      red = "redshift -PO 1000k";
      orng = "redshift -PO 2000k";
      blue = "redshift -x";

      # nix
      ncu = "sudo nix-channel --update";
      npk = ''
        sudo nixos-option environment.systemPackages | head -n -2 | tail -n -1 |
        sed -e 's/ /\n/g' | cut -d- -f2- | sort | uniq;
      '';
      npka = "sudo nix-store --query --requisites /run/current-system | cut -d- -f2- | sort | uniq";
      nxp = "lorri init && direnv allow";
      nxs = "sudo nixos-rebuild switch";
      nxsr = "cd ~ && sudo nixos-rebuild switch && sudo reboot";
      nxt = "cd ~ && sudo nixos-rebuild test; cd -";
      nb = "nix-build";
      ndeps = "nix-store-deps";
      ndtree = "nix-store-deps-tree";
      ndx = "nix-index";
      ne = "nix-env";
      nev = "nix eval";
      nhash = "nix-prefetch-url --type sha256";
      nl = "nix-env -q";
      nq = "nix-query";
      nqu = "NIXPKGS_ALLOW_UNFREE=1 nix-env -qaP";
      nr = "nix repl";
      nrn = ''nix repl "<nixpkgs/nixos>"'';
      nrp = ''nix repl "<nixpkgs>"'';
      ns = "nix-shell";
      nsd = "nix show-derivation";
      nsp = "nix-shell --pure";
      nsref = "nix-store-references";
      nsrefr = "nix-store-referrers";
      nst = "nix-store";
      nstp = "nix-store-path";
      nsu = "nix-shell --arg nixpkgs 'import <nixpkgs-unstable> {}'";
      # nix shells
      dana = "nix-shell ~/.shells/dataAnalysis.nix";
      fpy = "nix-shell ~/.shells/yapf.nix";
      ipy = "nix-shell -p python36Packages.ipython --run ipython";
      ugen = "uuid-gen-n";
      nsr = "nix-shell ~/projects/Camsbury/config/rSetup.nix --run emacs";

      # cabal
      cbw = ''ghcid -c "cabal repl lib:bobby" | source-highlight -s haskell -f esc'';
      ctw = ''ghcid -c "cabal repl test:bobby-tests" --warnings --test "Main.main" | source-highlight -s haskell -f esc'';
      cbi = "cabal build --ghc-option=-ddump-minimal-imports";

      # docker
      dcud = "docker-compose up -d";
      dclf = "docker-compose logs -f";
      dc = "docker-compose";
      dcub = "docker-compose up --build -d";
      dcr = "docker-compose restart";
      dchr = "docker-compose-hard-restart";
      dchrf = "docker-compose-hard-restart-and-log";
      dps = "docker ps";
      dsac = ''docker stop $(docker ps -aq)'';
      drac = ''docker rm $(docker ps -aq)'';
      dcrf = "docker-compose-restart-and-log";
      dk = "docker";
      drni = "docker rmi $(docker images | grep '^<none>' | awk '{print $3}')";
      drdi = ''docker rmi $(docker images -q -f "dangling=true")'';
      drmc = "docker rm $(docker ps -q -f 'status=exited')";

      # kubernetes
      kc = "kubectl";
      kt = "kubetail";
      kp = "kubectl get pods";
      ks = "kubernetes_switch_project.sh";
      kpn = "kpods-by-app";
      kdys = "kubectl get deployments";
      kgs = "kube-get-secret";
      ksrvs = "kubectl get services";
      kpw = "kubectl get pods -w";
      klf = "kubectl logs -f";
      gclc = "gcloud container clusters get-credentials"; # followed by the cluster name

      # stackdriver
      lglg = "google-logs";
      lgl = "gcloud logging read --format json";

      # elixir
      mex = "iex -S mix";
      mt = "mix test";
      md = "mix deps.get && mix deps.compile";
      mdi = "mix deps";
    };
  };
}
