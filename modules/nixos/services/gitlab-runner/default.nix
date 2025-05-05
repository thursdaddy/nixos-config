{
  lib,
  config,
  pkgs,
  inputs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.services.gitlab-runner;

  localNix = import (inputs.nix.outPath + "/docker.nix") {
    pkgs = pkgs;
    name = "local/nix";
    tag = "latest";
    bundleNixpkgs = false;
    extraPkgs = with pkgs; [ cachix ];
    nixConf = {
      cores = "0";
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  localNixDaemon = pkgs.dockerTools.buildLayeredImageWithNixDb {
    fromImage = localNix;
    name = "local/nix-daemon";
    tag = "labuildLayeredImagetest";
    contents = with pkgs; [
      attic-client
    ];
    config = {
      Volumes = {
        "/nix/store" = { };
        "/nix/var/nix/db" = { };
        "/nix/var/nix/daemon-socket" = { };
      };
    };
    maxLayers = 125;
  };
in
{
  options.mine.services.gitlab-runner = {
    enable = mkEnableOption "Attic cache";
  };

  config = mkIf cfg.enable {
    sops = {
      secrets."gitlab/runner/C137" = { };
      templates."gitlab-runner.env".content = ''
        CI_SERVER_URL="https://git.thurs.pw"
        CI_SERVER_TOKEN=${config.sops.placeholder."gitlab/runner/C137"}
      '';
    };

    virtualisation.oci-containers = {
      backend = "docker";
      containers.gitlabnix = {
        imageFile = localNixDaemon;
        image = "local/nix-daemon:latest";
        cmd = [
          "nix"
          "daemon"
        ];
      };
    };

    services.gitlab-runner = {
      enable = true;

      services.nix-runner = {
        description = "Nix Runner (NixOS)";

        registrationFlags = [
          "--docker-volumes-from"
          "gitlabnix:ro"

          "--docker-pull-policy"
          "if-not-present"

          "--docker-allowed-pull-policies"
          "if-not-present"
        ];
        authenticationTokenConfigFile = config.sops.templates."gitlab-runner.env".path;

        executor = "docker";

        dockerImage = "local/nix:latest";

        environmentVariables = {
          NIX_REMOTE = "daemon";
          ENV = "/etc/profile.d/nix-daemon.sh";
          BASH_ENV = "/etc/profile.d/nix-daemon.sh";
        };
      };
    };
  };
}
