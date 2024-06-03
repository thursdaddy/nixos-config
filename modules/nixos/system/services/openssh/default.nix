{ lib, config, ... }:
with lib;
let

  cfg = config.mine.system.services.openssh;

in
{
  options.mine.system.services.openssh = {
    enable = mkEnableOption "Enable OpenSSH";
    root = mkEnableOption "Allow root login via SSH Keys";
  };

  config = mkIf cfg.enable {
    users.users.root.openssh.authorizedKeys.keys = mkIf cfg.root [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDf3iS7lXUebJun3jQ3EJWkFoZcCrfaaAJaZWE1FFqEkLUFXhuBxITRXXqVyPjBHrY52RoAmg6RQejQDBcyV4sSs1IWMhHr50RzdM1FXGJunel6l3gvg36vUZ8OU+KU3N7E41it8we8IvV+QeDfV3QhXWAvCHIwA7UdTha00YDPaZxmZPOOnq0tE16d/9u8F8jYyuuBPwtE8PilaY5q6HI151hNTxb7vxru3H6faUjO1JKnY3UjU32FyTkz4o4IkvmdAWoft38gmtdr1VU0Fg/aZ8H6ltUPGdj8d/Nr6iUvxT41cIMmPNEeKJQ1mrVlIZ2AMN9LggLVIx02LbIQ2Pabbvyhq4FHCTztYkYjPnBBEbqKcsSMObqzGhQQxiOkrbVjmx8qei0NvnmPUHpoPCKzcJhApTBRKd7Pck2+nl56BJG9YqnELjAiogolELyJgnB88g4zKKGi/o21GW1vRXGMMn/gCWkiPBjBlBzYjGDaVFfMLc9GVhVfgnJFFiVZmMk= thurs@nixos"
    ];

    # Passwordless sudo when SSH'ing with keys
    security.pam.sshAgentAuth.enable = true;

    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin =
          if (cfg.root)
          then "prohibit-password"
          else mkDefault "no";
      };
    };
  };
}
