_: {
  flake.modules.nixos.desktop =
    {
      pkgs,
      ...
    }:
    {
      security.pam = {
        u2f = {
          enable = true;
          settings.cue = true;
        };

        rssh.enable = true;

        services.sudo = {
          u2fAuth = true;
          rssh = true;
        };
      };
    };
}
