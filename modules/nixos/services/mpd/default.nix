{ lib, pkgs, config, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.services.mpd;
  user = config.mine.user;

in
{
  options.mine.services.mpd = {
    enable = mkEnableOption "Enable MPD";
  };

  config = mkIf cfg.enable {
    services.mympd = {
      enable = true;
      openFirewall = true;
      settings = {
        http_port = 8444;
      };
    };

    systemd.services.mpd.environment = {
      # https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/609
      XDG_RUNTIME_DIR = "/run/user/${toString config.users.users.${user.name}.uid}";
    };

    services.mpd = {
      enable = true;
      user = "${user.name}";
      musicDirectory = "/music/";
      extraConfig = ''
        auto_update "yes"
        audio_output {
          type "pipewire"
          name "PipeWire Output"
        }'';
      network.listenAddress = "any"; # if you want to allow non-localhost connections
      startWhenNeeded = true; # systemd feature: only start MPD service upon connection to its socket
    };
  };
}
