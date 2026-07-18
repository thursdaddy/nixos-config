{ inputs, ... }:
{
  flake.modules.generic.base =
    {
      config,
      options,
      pkgs,
      lib,
      ...
    }:
    let
      cfg = config.mine.base.utils;
      celler-client = inputs.celler.packages.${pkgs.stdenv.hostPlatform.system}.default;
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
            fastfetch
            jq
            just
            killall
            tree
            wget
          ]
          ++ lib.optionals (cfg.sysadmin.enable) [
            celler-client
            bind
            dig
            file
            gnupg
            pkgs.siomon
            ncdu
            nmap
            p7zip
            unixtools.netstat
            usbutils
            wakeonlan
          ]
          ++ lib.optionals (!pkgs.stdenv.hostPlatform.isAarch64 && cfg.sysadmin.enable) [ rar ]
          ++ lib.optionals (options ? mine.dev) [
            glow
            nixfmt-rfc-style
            nixpkgs-fmt
            shellcheck
            statix
          ]
          ++ lib.optionals (!(options ? mine.dev)) [ neovim ];

        nixpkgs.config.allowUnfreePredicate =
          pkg:
          builtins.elem (lib.getName pkg) [
            "rar"
          ];
      };
    };
}
