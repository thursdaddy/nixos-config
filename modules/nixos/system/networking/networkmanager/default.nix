{ lib, config, pkgs, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.system.networking.networkmanager;
  inherit (config.mine) user;

in
{
  options.mine.system.networking.networkmanager = {
    enable = mkEnableOption "Enable NetworkManager";
    hostname = mkOpt types.str "" "Hostname";
    applet = mkEnableOption "Enable desktop applet";
  };

  config = mkIf cfg.enable {
    networking = {
      hostName = "${cfg.hostname}";
      networkmanager.enable = true;
      networkmanager.plugins = with pkgs; [
        networkmanager-openvpn
      ];
    };

    users.users.${user.name}.extraGroups = [ "networkmanager" ];
    systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
    programs.nm-applet.enable = mkIf cfg.applet true;
  };
}
