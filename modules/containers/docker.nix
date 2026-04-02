_: {
  flake.modules.nixos.containers =
    {
      lib,
      ...
    }:
    {
      options.mine.containers = {
        settings = {
          configPath = lib.mkOption {
            description = "Base path for storing container configs";
            type = lib.types.path;
            default = "/opt/configs/";
          };
        };
      };

      config = {
        mine.services.docker.enable = true;
      };
    };
}
