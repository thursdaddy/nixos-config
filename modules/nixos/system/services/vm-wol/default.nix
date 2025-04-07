{
  lib,
  config,
  inputs,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.system.services.vm-wol;

  wol_hack = pkgs.writeShellScript "wol-hack" ''
    ${builtins.readFile ./wol-hack.sh}
  '';
  raw_wol_hack = pkgs.writeShellScript "wol-hack" ''
    check_vm_status() {
      echo "checking status of $1"
      local vmid="$1"
      local status=$(${
        lib.getExe' inputs.proxmox-nixos.packages.${pkgs.system}.proxmox-ve "qm"
      } status "$vmid" | grep -oP 'status: \K\w+')

      if [ "$status" == "stopped" ]; then
        echo "VM $vmid status: $status"
        return 0
      elif [ "$status" == "running" ]; then
        echo "VM $vmid status: $status"
        return 1
      else
        echo "Failed to get VM $vmid status."
        return 1 # Failure
      fi
    }

    while true; do
      sleep 5
      WAKE_MAC=$(${lib.getExe pkgs.tcpdump} -c 1 -UlnXi enp2s0 ether proto 0x0842 or udp port 9 |\
      sed -nE 's/^.*20:  (ffff|.... ....) (..)(..) (..)(..) (..)(..).*$/\2:\3:\4:\5:\6:\7/p')
      if [ -n "$WAKE_MAC" ]; then
        echo "Captured magic packet for address: \"$WAKE_MAC\""
        FOUND_VM=$(grep -il $WAKE_MAC /etc/pve/qemu-server/* | head -n 1)
        if [ -n "$FOUND_VM" ]; then
          echo "MAC address found in VM configuration: $FOUND_VM"
          VMID=$(basename "$FOUND_VM" .conf)
          echo "VM ID: $VMID"
          if check_vm_status "$VMID"; then
            /root/testing_wol.sh
          fi
        else
          echo "MAC Address not found in any config."
        fi
      else
        echo "No WOL packet detected."
      fi
    done
  '';
in
{
  options.mine.system.services.vm-wol = {
    enable = mkEnableOption "Enable vm-wol";
  };

  config = mkIf cfg.enable {
    systemd.services.vm-wol = {
      enable = true;
      description = "Wake-on-LAN for Proxmox Virtual Environments";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        # User = "root";
        ExecStart = "${raw_wol_hack}";
        ExecStop = "${pkgs.coreutils}/bin/kill -SIGTERM $MAINPID";
        Restart = "always";
        CapabilityBoundingSet = [
          "CAP_NET_ADMIN"
          "CAP_NET_RAW"
        ];
        AmbientCapabilities = [
          "CAP_NET_ADMIN"
          "CAP_NET_RAW"
        ];
      };
    };
  };
}
