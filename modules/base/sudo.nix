_: {
  flake.modules.nixos.base = {
    security = {
      pam.sshAgentAuth.enable = true;
      sudo-rs.enable = true;
    };
  };
}
