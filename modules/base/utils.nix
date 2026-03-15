{ inputs, ... }:
{
  flake.modules.generic.base =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      sysadmin =
        with pkgs;
        [
          attic-client
          bind
          dig
          gnupg
          ncdu
          nmap
          unixtools.netstat
          wakeonlan
        ]
        ++ lib.optionals (!pkgs.stdenv.hostPlatform.isAarch64) [
          rar
        ];
    in
    {
      options.mine.base.utils = {
        sysadmin.enable = lib.mkEnableOption "Sysadmin focused utils";
      };

      config = {
        environment.systemPackages =
          with pkgs;
          [
            inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.siomon
            bottom
            curl
            eza
            fastfetch
            file
            killall
            p7zip
            ripgrep
            tree
            wget
          ]
          ++ lib.optionals (config.mine.base.utils.sysadmin.enable) sysadmin;

        nixpkgs.config.allowUnfreePredicate =
          pkg:
          builtins.elem (lib.getName pkg) [
            "rar"
          ];
      };
    };
}
