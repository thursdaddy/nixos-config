_: {
  flake.modules.nixos.desktop = {
    programs.seahorse.enable = true; # keyring GUI

    security.pam.services = {
      greetd.enableGnomeKeyring = true;
      login.enableGnomeKeyring = true;
    };

    services = {
      gnome = {
        gnome-keyring.enable = true;
        gcr-ssh-agent.enable = false;
      };
    };
  };
}
