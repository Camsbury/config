{ config, pkgs, ... }:

{
  services.postgresql = {
    enable = true;
    enableTCPIP = true;
    # port = 5432;
    package = pkgs.postgresql;
    authentication = pkgs.lib.mkOverride 10 ''
      local all all              trust
      host  all all 127.0.0.1/32 trust
      host  all all ::1/128      trust
    '';
      # #type database  DBuser  auth-method optional_ident_map
      # local sameuser  all     peer        map=superuser_map

    identMap = ''
      # ArbitraryMapName systemUser DBUser
         superuser_map      root      postgres
         superuser_map      postgres  postgres
         # Let other names login as themselves
         superuser_map      /^(.*)$   \1
    '';
  };
}
