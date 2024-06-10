{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.cli-tools.ncmpcpp;
  user = config.mine.user;

in
{
  options.mine.cli-tools.ncmpcpp = {
    enable = mkEnableOption "Enable ncmpcpp";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      programs.ncmpcpp = {
        enable = true;
        package = (pkgs.ncmpcpp.override { visualizerSupport = true; });
        mpdMusicDir = "/music";
        settings = {
          mpd_host = "127.0.0.1";
          mpd_port = "6600";
        };
      };
    };
  };
}
