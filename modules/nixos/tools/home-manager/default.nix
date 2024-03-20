{ lib, config, inputs, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.tools.home-manager;
  user = config.mine.user;
  allowed-unfree-packages = [
    "discord"
  ];

in {
  options.mine.tools.home-manager = {
    enable = mkEnableOption "Enable Home-Manager";
  };

  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  config = mkIf cfg.enable {
    home-manager.useUserPackages = true;
    home-manager.extraSpecialArgs = { inherit inputs; inherit user; inherit allowed-unfree-packages; };
    home-manager.users.${user.name}.imports = [
      inputs.hyprlock.homeManagerModules.hyprlock
      ./home.nix
    ];
  };
}
