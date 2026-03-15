_: {
  flake.modules.generic.apps =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.brave
      ];
    };
}
