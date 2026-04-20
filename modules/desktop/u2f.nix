_: {
  flake.modules.nixos.desktop =
    {
      pkgs,
      ...
    }:
    {
      security.pam.u2f = {
        enable = true;
        settings.cue = true;
      };
      security.pam.services.sudo.u2fAuth = true;
    };
}
