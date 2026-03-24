{ inputs, ... }:
{
  flake.modules.nixos.dev =
    { config, pkgs, ... }:
    {
      imports = [
        inputs.nixvim.nixosModules.nixvim
        inputs.self.modules.generic.nixvim
      ];

      config = {
        programs.nixvim.enable = true;

        environment.systemPackages = [
          pkgs.ripgrep
        ];
      };
    };

  flake.modules.darwin.dev =
    { config, pkgs, ... }:
    {
      imports = [
        inputs.nixvim.nixDarwinModules.nixvim
        inputs.self.modules.generic.nixvim
      ];

      config = {
        programs.nixvim.enable = true;

        environment.systemPackages = [
          pkgs.ripgrep
        ];
      };
    };
}
