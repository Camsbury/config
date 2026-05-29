{ config, pkgs, ... }:

{
  services.xserver.inputClassSections = [
    ''
    Identifier   "Razer Razer DeathAdder V2"
    MatchProduct "Razer"
    MatchUSBID     "1532:0084"
    MatchIsPointer "on"
    Driver       "libinput"
    Option       "AccelProfile" "adaptive"
    Option       "AccelSpeed"   "1.0"
    Option       "ButtonMapping" "1 2 3 4 5 6 7 0 0"
    ''
  ];
  # Hack to get the DPI on the mose to be consistent
  # set this if you change it in razergenie
  systemd.user.services.razer-dpi = let
    py = pkgs.python3.withPackages (p: [ p.openrazer ]);
  in {
    description = "Apply DeathAdder V2 DPI (openrazer persistence is unreliable)";
    after    = [ "openrazer-daemon.service" ];
    wants    = [ "openrazer-daemon.service" ];
    partOf   = [ "openrazer-daemon.service" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${py}/bin/python3 -c 'import openrazer.client as r; r.DeviceManager().devices[0].dpi = (1800, 1800)'";
    };
  };
  hardware.openrazer.enable = true;
  users.extraGroups.openrazer.members = [
    "${toString config.users.users.default.name}"
  ];
  environment.systemPackages = [pkgs.razergenie];
}
