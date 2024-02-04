{ pkgs, ... }:

{
    nix = {
      package = pkgs.nixFlakes;
      extraOptions = ''
        experimental-features = nix-command flakes
      '';
    };

    networking.interfaces.eth0.ipv4.addresses = [ {
      address = "192.168.20.222";
      prefixLength = 24;
    } ];
    networking.defaultGateway = "192.168.20.1";
    networking.nameservers = [ "192.168.20.80" ];

    system.stateVersion = "23.11";
}
