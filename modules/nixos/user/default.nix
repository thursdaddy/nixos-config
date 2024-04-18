{ lib, config, pkgs, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.user;
  home-directory = "/home/${cfg.name}";

in
{
  options.mine.user = {
    enable = mkEnableOption "Enable User";
    name = mkOpt types.str "thurs" "User account name";
    alias = mkOpt types.str "thursdaddy" "Full alias";
    email = mkOpt types.str "thursdaddy@pm.me" "My Email";
    homeDir = mkOpt types.str "${home-directory}" "Home Directory Path";
  };

  config = mkIf cfg.enable {
    nix.settings.trusted-users = [ "${cfg.name}" ];

    environment.variables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    users.users.${cfg.name} = {
      isNormalUser = true;
      createHome = true;
      uid = 1000;
      openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDf3iS7lXUebJun3jQ3EJWkFoZcCrfaaAJaZWE1FFqEkLUFXhuBxITRXXqVyPjBHrY52RoAmg6RQejQDBcyV4sSs1IWMhHr50RzdM1FXGJunel6l3gvg36vUZ8OU+KU3N7E41it8we8IvV+QeDfV3QhXWAvCHIwA7UdTha00YDPaZxmZPOOnq0tE16d/9u8F8jYyuuBPwtE8PilaY5q6HI151hNTxb7vxru3H6faUjO1JKnY3UjU32FyTkz4o4IkvmdAWoft38gmtdr1VU0Fg/aZ8H6ltUPGdj8d/Nr6iUvxT41cIMmPNEeKJQ1mrVlIZ2AMN9LggLVIx02LbIQ2Pabbvyhq4FHCTztYkYjPnBBEbqKcsSMObqzGhQQxiOkrbVjmx8qei0NvnmPUHpoPCKzcJhApTBRKd7Pck2+nl56BJG9YqnELjAiogolELyJgnB88g4zKKGi/o21GW1vRXGMMn/gCWkiPBjBlBzYjGDaVFfMLc9GVhVfgnJFFiVZmMk= thurs@nixos" ];
      extraGroups = [ "wheel" ];
      shell = pkgs.zsh;
    };

  };
}
