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
          fastfetch
          file
          gnupg
          inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.siomon
          ncdu
          nmap
          p7zip
          ripgrep
          unixtools.netstat
          usbutils
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
            bottom
            curl
            eza
            jq
            just
            killall
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
