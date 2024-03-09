{ lib, config, pkgs, ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.nixos.network;

in {
  options.mine.nixos.network = {
    enable = mkOpt types.bool false "Enable network";
    hostname = mkOpt types.str "" "Hostname";
    applet = mkOpt types.bool false "Enable desktop applet";
  };

  config = mkIf cfg.enable {
    networking = {
      hostName = "${cfg.hostname}";
      networkmanager.enable = true;
      networkmanager.plugins = with pkgs; [
        networkmanager-openvpn
      ];
    };

    programs.nm-applet.enable = mkIf cfg.applet true;

  };

}
