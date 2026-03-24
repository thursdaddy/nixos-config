_: {
  flake.modules.nixos.base = {
    security.pam.sshAgentAuth.enable = true;
    security.sudo-rs.enable = true;
  };
}
