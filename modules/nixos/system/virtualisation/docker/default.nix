{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.system.virtualisation.docker;
  user = config.mine.user;

  check-versions-script = pkgs.writeShellApplication {
    name = "_docker-check-versions";
    runtimeInputs = with pkgs; [ coreutils gnused ];
    excludeShellChecks = [ "SC2059" ];
    text = (builtins.readFile ./scripts/check-container-versions.sh);
  };

in
{
  options.mine.system.virtualisation.docker = {
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

    environment.systemPackages = with pkgs; [
      (mkIf cfg.scripts.check-versions check-versions-script)
    ];

    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";
  };
}
