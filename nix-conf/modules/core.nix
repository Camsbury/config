# The modules every machine imports. Settings live in the module that owns
# their subject; this file only lists them.
{
  imports = [
    /etc/nixos/hardware-configuration.nix
    ../overlays/core.nix
    ../private.nix

    ./audio.nix
    ./boot.nix
    ./browsers.nix
    ./cmacs.nix
    ./communication.nix
    ./credentials.nix
    ./desktop.nix
    ./dev.nix
    ./display.nix
    ./documentation.nix
    ./documents.nix
    ./dropbox.nix
    ./keyboard.nix
    ./locale.nix
    ./media.nix
    ./networking.nix
    ./nix.nix
    ./observability.nix
    ./search.nix
    ./shell.nix
    ./storage.nix
    ./study.nix
    ./transmission.nix
    ./user.nix
  ];
}
