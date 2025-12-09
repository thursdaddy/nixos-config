{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.system.services.keyring;

in
{
  options.mine.system.services.keyring = {
    enable = mkEnableOption "Enable Gnome keyring";
  };

  config = mkIf cfg.enable {
    services.gnome.gnome-keyring.enable = true;

    security.pam.services.login.enableGnomeKeyring = true;

    programs.seahorse.enable = true; # keyring GUI
    services.gnome.gcr-ssh-agent.enable = false;
  };
}
