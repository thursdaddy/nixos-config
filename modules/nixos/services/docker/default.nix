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

  container-version-check-env = pkgs.python311.withPackages (
    p: with p; [ pkgs.python311Packages.requests ]
  );

  container-version-check = pkgs.substituteAll {
    name = "_container-check";
    src = ./scripts/container-version-check.py;
    dir = "/bin";
    isExecutable = true;
    py = "${container-version-check-env}/bin/python";
  };

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
      (mkIf cfg.scripts.check-versions container-version-check)
    ];

    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";

    programs.fish.shellAliases = mkIf (
      user.shell.package == pkgs.fish || config.mine.system.shell.fish.enable
    ) aliases.docker;
  };
}
