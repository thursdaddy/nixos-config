{ config, lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.container.gitlab-runner;
in
{
  options.mine.container.gitlab-runner = {
    enable = mkEnableOption "gitlab-runner";
  };

  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers."gitlab-runner" = {
      image = "gitlab/gitlab-runner:latest";
      volumes = [
        "${config.mine.container.settings.configPath}/gitlab-runner:/etc/gitlab-runner"
        "/var/run/docker.sock:/var/run/docker.sock"
      ];
      extraOptions = [
        "--network=traefik"
        "--pull=always"
        "--dns=192.168.10.57"
        "--dns=192.168.10.201"
      ];
      labels = {
        "enable.versions.check" = "false";
      };
    };
  };
}
