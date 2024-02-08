{ ... }: {

  services.openssh = {
      enable = true;
      settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "no";
          # Automatically remove stale sockets
          StreamLocalBindUnlink = "yes";
      };
  };

  # Passwordless sudo when SSH'ing with keys
  security.pam.enableSSHAgentAuth = true;
}
