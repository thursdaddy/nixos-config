{ inputs, ... }:
{
  flake.modules.nixos.dev =
    { config, ... }:
    {
      imports = [
        inputs.nixvim.nixosModules.nixvim
        inputs.self.modules.generic.nixvim
      ];

      config = {
        programs.nixvim.enable = true;
      };
    };

  flake.modules.darwin.dev =
    { config, ... }:
    {
      imports = [
        inputs.nixvim.nixDarwinModules.nixvim
        inputs.self.modules.generic.nixvim
      ];

      config = {
        programs.nixvim.enable = true;
      };
    };
}
