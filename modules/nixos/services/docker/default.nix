{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  inherit (config.mine) user;
  cfg = config.mine.services.docker;
  aliases = import ../../../shared/aliases.nix;

  version_script = builtins.readFile ./scripts/container-version-check.py;
  version_check = pkgs.writers.writePython3Bin "_container-check" {
    flakeIgnore = [
      "W503"
      "E501"
    ];
    libraries = with pkgs.python3Packages; [
      requests
    ];
  } version_script;
in
{
  options.mine.services.docker = {
    enable = mkEnableOption "docker";
    scripts = mkOption {
      default = { };
      description = "Docker related scripts";
      type = types.submodule {
        options = {
          check-versions = mkEnableOption "script to get current and latest container tags";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${user.name}.extraGroups = mkIf user.enable [ "docker" ];

    environment.systemPackages = [
      (mkIf cfg.scripts.check-versions version_check)
    ];

    virtualisation = {
      oci-containers.backend = "docker";
      docker = {
        enable = true;
        autoPrune = {
          enable = true;
          dates = "daily";
        };
      };
    };

    programs.fish.shellAliases = mkIf (
      user.shell.package == pkgs.fish || config.mine.system.shell.fish.enable
    ) aliases.docker;
  };
}
