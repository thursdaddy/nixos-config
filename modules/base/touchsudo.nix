_: {
  flake.modules.darwin.base =
    { pkgs, ... }:
    {
      security.pam.services.sudo_local.touchIdAuth = true;

      environment.systemPackages = [
        pkgs.pam-reattach
      ];
    };
}
