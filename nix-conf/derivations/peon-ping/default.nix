# peon-ping, built from its npins pin with this system's nixpkgs.
#
# Upstream defines the package inline in its flake.nix. Calling that flake
# (builtins.getFlake) evaluates a second nixpkgs from its flake.lock, and no
# GC root keeps those inputs. This file ports the Linux part of upstream's
# recipe instead, in the same order and wording where it can, so the two
# are easy to compare.
#
# The port must follow upstream. `portedFrom.flake` is the sha256 of the
# flake.nix this recipe was ported from. When a pin update changes that
# file, evaluation stops until the recipe is re-checked against it and the
# hash is updated.
{
  lib,
  stdenv,
  makeWrapper,
  bash,
  python3,
  curl,
  coreutils,
  gzip,
  src,
}:

let
  # sha256 of the upstream file this recipe was ported from.
  portedFrom = {
    flake = "d1fe850a9f77dbf073cdacdbbf5c5935e783b5ae15f217f64be4d49a17675f34";
  };
  flakeSha256 = builtins.hashFile "sha256" "${src}/flake.nix";

  runtimeDeps = [
    bash
    python3
    curl
    coreutils # sha256sum, nohup
    gzip
  ];
in
assert lib.assertMsg (flakeSha256 == portedFrom.flake) ''
  peon-ping: upstream flake.nix changed since the recipe was ported.
  Re-check this recipe (nix-conf/derivations/peon-ping/default.nix)
  against ${src}/flake.nix, then set portedFrom.flake to ${flakeSha256}.
'';
stdenv.mkDerivation {
  pname = "peon-ping";
  version = lib.strings.trim (builtins.readFile "${src}/VERSION");
  inherit src;

  nativeBuildInputs = [ makeWrapper ];
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    share="$out/share/peon-ping"
    mkdir -p "$share/scripts"

    # Core scripts
    cp peon.sh relay.sh install.sh "$share/"
    chmod +x "$share/peon.sh" "$share/relay.sh" "$share/install.sh"

    # Bundled helper scripts (find_bundled_script looks here)
    for f in scripts/pack-download.sh scripts/notify.sh \
             scripts/remote-hook.sh scripts/hook-handle-use.sh \
             scripts/hook-handle-rename.sh \
             scripts/mac-overlay.js; do
      [ -f "$f" ] && cp "$f" "$share/scripts/"
    done
    chmod +x "$share/scripts/"*.sh 2>/dev/null || true

    # Wrap hook scripts so they find python3 and the other runtime deps
    # whatever PATH the calling agent passes to its hooks.
    for s in "$share/scripts/hook-handle-use.sh" \
             "$share/scripts/hook-handle-rename.sh"; do
      [ -f "$s" ] && wrapProgram "$s" \
        --prefix PATH : ${lib.makeBinPath runtimeDeps}
    done

    # Runtime data. config.json is user state, so it is not copied.
    cp VERSION "$share/"
    cp -r trainer "$share/trainer"
    mkdir -p "$share/docs"
    cp docs/peon-icon.png "$share/docs/"

    # MCP server
    mkdir -p "$share/mcp"
    cp mcp/peon-mcp.js mcp/package.json "$share/mcp/"

    # Skills + adapters
    cp -r skills "$share/skills"
    cp -r adapters "$share/adapters"

    # Shell completions
    mkdir -p "$out/share/bash-completion/completions"
    mkdir -p "$out/share/fish/vendor_completions.d"
    cp completions.bash "$out/share/bash-completion/completions/peon"
    cp completions.fish "$out/share/fish/vendor_completions.d/peon.fish"
    # Not in upstream's recipe: it ships completions.zsh but does not
    # install it.
    mkdir -p "$out/share/zsh/site-functions"
    cp completions.zsh "$out/share/zsh/site-functions/_peon"

    # bin/peon wrapper
    mkdir -p "$out/bin"
    makeWrapper ${bash}/bin/bash "$out/bin/peon" \
      --add-flags "$share/peon.sh" \
      --prefix PATH : ${lib.makeBinPath runtimeDeps}

    runHook postInstall
  '';

  meta = {
    description = "Warcraft III Peon voice lines for Claude Code hooks";
    homepage = "https://github.com/PeonPing/peon-ping";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "peon";
  };
}
