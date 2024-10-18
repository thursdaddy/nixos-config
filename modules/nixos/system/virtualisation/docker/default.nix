{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.system.virtualisation.docker;
  user = config.mine.user;

  container-version-check-env = (pkgs.python311.withPackages (p:
    with p; [ pkgs.python311Packages.requests ]));

  container-version-check = pkgs.substituteAll ({
    name = "_container-check";
    src = ./scripts/container-version-check.py;
    dir = "/bin";
    isExecutable = true;
    py = "${container-version-check-env}/bin/python";
  });

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
      (mkIf cfg.scripts.check-versions container-version-check)
    ];

    virtualisation.docker.enable = true;
    virtualisation.oci-containers.backend = "docker";
  };
}
