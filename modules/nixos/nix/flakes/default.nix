{ inputs, lib, config, ... }:
with lib;
let
cfg = config.mine.nixos.flakes;

in {
  options.mine.nixos.flakes = {
    enable = mkEnableOption "Enable Flakes";
  };

  config = mkIf cfg.enable {
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    # https://discourse.nixos.org/t/problems-after-switching-to-flake-system/24093/8
    nix.nixPath = [ "/etc/nix/path" ];
    nix.registry.nixpkgs.flake = inputs.nixpkgs;
    environment.etc."nix/path/nixpkgs".source = inputs.nixpkgs;
  };

}
