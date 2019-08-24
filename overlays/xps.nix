self: super:
let
  machine = import ../machine.nix;
in
  if machine.xps
  then {
    firmwareLinuxNonfree = super.firmwareLinuxNonfree.overrideAttrs (
      old: {
        src = super.fetchgit{
          url = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git";
          rev = "bf13a71b18af229b4c900b321ef1f8443028ded8";
          sha256 = "1dcaqdqyffxiadx420pg20157wqidz0c0ca5mrgyfxgrbh6a4mdj";
        };
        postInstall = ''
          rm $out/lib/firmware/iwlwifi-cc-a0-48.ucode
        '';
        # outputHash = "0dq48i1cr8f0qx3nyq50l9w9915vhgpwmwiw3b4yhisbc3afyay4";
      }
    );
  } else {}
