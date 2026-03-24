_: {
  flake.modules.darwin.base =
    { pkgs, ... }:
    {
      security.pam.services.sudo_local.touchIdAuth = true;

      # fix touchid auth in tmux
      environment = {
        etc."pam.d/sudo_local".text = ''
          # Managed by Nix Darwin
          auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so ignore_ssh
          auth       sufficient     pam_tid.so
        '';
      };

      environment.systemPackages = [
        pkgs.pam-reattach
      ];
    };
}
