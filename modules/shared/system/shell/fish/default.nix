{ lib, config, pkgs, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.system.shell.fish;

in
{
  options.mine.system.shell.fish = {
    enable = mkEnableOption "fish";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      fishPlugins.colored-man-pages
      fishPlugins.done
      fishPlugins.fzf-fish
      fishPlugins.forgit
      fishPlugins.grc
      grc
    ];

    # set fish_color_valid_path
    programs.fish = {
      enable = true;
      useBabelfish = true;
      interactiveShellInit = ''
        set -U fish_greeting ""
        set -g fish_pager_color_prefix 444444
        if test -d /opt/homebrew
          starship init fish | source
          # Homebrew is installed on MacOS
          /opt/homebrew/bin/brew shellenv | source
        end
      '';
    };

    environment.pathsToLink = [ "/share/fish " ];
  };
}
