{ user, pkgs, lib, inputs, ... }:
with lib;
{
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  config = {
    programs.home-manager.enable = true;

    home = {
      username = "${user.name}";
      homeDirectory = "${user.homeDir}";
      stateVersion = "24.11";

      extraActivationPath = with pkgs; [
        rsync
        dockutil
        gawk
      ];

      # https://github.com/nix-community/home-manager/issues/1341#issuecomment-1870352014
      activation.trampolineApps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${builtins.readFile ./trampoline-apps.sh}
        fromDir="$HOME/Applications/Home Manager Apps"
        toDir="$HOME/Applications/Home Manager Trampolines"
        sync_trampolines "$fromDir" "$toDir"
      '';
    };
  };
}
