{ user, pkgs, lib, ... }: {

  programs.home-manager.enable = true;

  home.username = "${user.name}";
  home.homeDirectory = "${user.homeDir}";
  home.stateVersion = "23.11";

  home.extraActivationPath = with pkgs; [
    rsync
    dockutil
    gawk
  ];

  # https://github.com/nix-community/home-manager/issues/1341#issuecomment-1870352014
  home.activation.trampolineApps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${builtins.readFile ./trampoline-apps.sh}
    fromDir="$HOME/Applications/Home Manager Apps"
    toDir="$HOME/Applications/Home Manager Trampolines"
    sync_trampolines "$fromDir" "$toDir"
  '';

}
