{ lib, config, pkgs, username, inputs,  ... }:
with lib;
let
  cfg = config.mine.home-manager;

  in {
      options.mine.home-manager = {
          enable = mkEnableOption "Git";
      };

      imports = [ inputs.home-manager.nixosModules.home-manager ];

      config = {

        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit username; inherit inputs; };
        home-manager.users.${username}.imports = [ ./home.nix ];

      };

}
