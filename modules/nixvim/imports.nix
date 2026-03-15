{ inputs, ... }:
{
  flake.modules.nixos.nixvim =
    { config, ... }:
    {
      imports = [
        inputs.nixvim.nixosModules.nixvim
        inputs.self.modules.generic.nixvim
      ];
      config = {
        programs.nixvim = {
          enable = true;
          vimAlias = true;
        };
      };
    };

  flake.modules.darwin.nixvim =
    { config, ... }:
    {
      imports = [
        inputs.nixvim.darwinModules.nixvim
        inputs.self.modules.generic.nixvim
      ];
      config = {
        programs.nixvim = {
          enable = true;
          vimAlias = true;
        };
      };
    };
}
