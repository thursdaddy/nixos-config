_: {
  flake.modules.generic.dev =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.mine.dev.crush;
    in
    {
      options.mine.dev.crush = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Agentic coding tool";
        };
      };

      config = lib.mkIf cfg.enable {
        nixpkgs.config.allowUnfreePredicate =
          pkg:
          builtins.elem (lib.getName pkg) [
            "crush"
          ];

        environment.systemPackages = [
          pkgs.unstable.crush
        ];
      };
    };
}
