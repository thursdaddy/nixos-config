_: {
  configurations.darwin.mbp.module =
    { config, ... }:
    {
      nixpkgs.hostPlatform = "aarch64-darwin";

      system = {
        stateVersion = 5;
        primaryUser = config.mine.base.user.name;
      };
    };
}
