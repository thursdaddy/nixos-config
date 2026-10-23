_: {
  flake.modules.nixos.apps =
    {
      config,
      pkgs,
      ...
    }:
    let
      inherit (config.mine.base) user;
      mark = "0x1000000";
    in
    {
      users.groups.vpn-bypass.members = [ user.name ];

      # pref 30000 runs after tailscale (5270) and before proton (31488).
      # dns is left on the vpn so lookups still work when resolv.conf points at the vpn resolver.
      systemd.services.vpn-bypass-routing = {
        description = "Route vpn-bypass group traffic outside the VPN";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        path = with pkgs; [
          gnugrep
          iproute2
          nftables
        ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          for v in -4 -6; do
            if ! ip $v rule show pref 30000 | grep -q "fwmark ${mark}/${mark}"; then
              ip $v rule add pref 30000 fwmark ${mark}/${mark} lookup main
            fi
          done

          nft -f - <<EOF
          destroy table inet vpn_bypass
          table inet vpn_bypass {
            chain output {
              type route hook output priority mangle; policy accept;
              meta skgid "vpn-bypass" meta l4proto { tcp, udp } th dport 53 return
              meta skgid "vpn-bypass" meta mark set meta mark or ${mark}
            }
            chain postrouting {
              type nat hook postrouting priority srcnat; policy accept;
              meta mark and ${mark} == ${mark} oifname "enp*" masquerade
            }
          }
          EOF
        '';
        preStop = ''
          for v in -4 -6; do
            if ip $v rule show pref 30000 | grep -q "fwmark ${mark}/${mark}"; then
              ip $v rule del pref 30000 fwmark ${mark}/${mark} lookup main
            fi
          done
          nft destroy table inet vpn_bypass
        '';
      };
    };
}
