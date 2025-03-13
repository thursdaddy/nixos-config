{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  inherit (config.mine) user;
  cfg = config.mine.cli-tools.ncmpcpp;

in
{
  options.mine.cli-tools.ncmpcpp = {
    enable = mkEnableOption "Enable ncmpcpp";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      programs.ncmpcpp = {
        enable = true;
        package = pkgs.ncmpcpp.override { visualizerSupport = true; };
        mpdMusicDir = "/music";
        settings = {
          mpd_host = "127.0.0.1";
          mpd_port = "6600";
        };
      };
    };
  };
}
