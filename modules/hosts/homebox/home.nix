{ inputs, config, ... }:
{
  configurations.nixos.homebox.module = {
    imports = [ config.flake.modules.nixos.home ];

    home-manager.users.${config.mine.base.user.name}.imports = with inputs.self.modules.homeManager; [
      dev
    ];
  };
}
