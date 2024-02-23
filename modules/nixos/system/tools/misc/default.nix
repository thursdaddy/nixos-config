{ pkgs, ... }: {

    environment.systemPackages = with pkgs; [
      curl
      file
      fzf
      glow
      jq
      killall
      ripgrep
      unzip
      wget
    ];

}
