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
      options.mine.base = {
        packages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
          description = "User-space base packages shared by hosts and the dev profile";
        };
        utils = {
          sysadmin.enable = lib.mkEnableOption "Sysadmin focused utils";
        };
      };

      config = {
        environment.interactiveShellInit = ''
          export GPG_TTY=$(tty)
        '';

        mine.base.packages = with pkgs; [
          bottom
          curl
          eza
          fastfetch
          (if pkgs.stdenv.hostPlatform.isDarwin then pkgs.darwinGit else pkgs.git)
          jq
          just
          killall
          tree
          wget
        ];

        environment.systemPackages =
          with pkgs;
          config.mine.base.packages
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
          ++ lib.optionals (!(options ? mine.dev)) [ neovim ];

        nixpkgs.config.allowUnfreePredicate =
          pkg:
          builtins.elem (lib.getName pkg) [
            "rar"
          ];
      };
    };
}
