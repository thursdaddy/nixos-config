{ ... }:

{
    networking.interfaces.eth0.ipv4.addresses = [ {
      address = "192.168.20.222";
      prefixLength = 24;
    } ];
    networking.defaultGateway = "192.168.20.1";
    networking.nameservers = [ "192.168.20.80" ];

}
