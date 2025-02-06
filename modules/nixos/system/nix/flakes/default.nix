{ inputs, lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.system.nix.flakes;

in
{
  options.mine.system.nix.flakes = {
    enable = mkEnableOption "Enable Flakes";
  };

  config = mkIf cfg.enable {
    nix = {
      settings.experimental-features = [ "nix-command" "flakes" ];
      registry.nixpkgs.flake = inputs.nixpkgs;
      # https://discourse.nixos.org/t/problems-after-switching-to-flake-system/24093/8
      nixPath = [ "/etc/nix/path" ];
      extraOptions = ''
        warn-dirty = false
      '';
    };
    environment.etc."nix/path/nixpkgs".source = inputs.nixpkgs;
  };
}
