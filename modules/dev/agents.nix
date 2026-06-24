_: {
  flake.modules.generic.dev =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.mine.dev.agents;
    in
    {
      options.mine.dev.agents = lib.mkOption {
        description = "Agentic coding tools";
        default = { };
        type = lib.types.submodule {
          options = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable agentic coding tools";
            };
            crush = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable Crush";
            };
            antigravity = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable Google Antigravity";
            };
          };
        };
      };

      config = lib.mkIf cfg.enable {
        nixpkgs.config.allowUnfreePredicate =
          pkg:
          cfg.crush && builtins.elem (lib.getName pkg) [ "crush" ];

        environment.systemPackages =
          (lib.optional cfg.crush pkgs.unstable.crush)
          ++ (lib.optional cfg.antigravity pkgs.unstable.antigravity-cli);
      };
    };
}
