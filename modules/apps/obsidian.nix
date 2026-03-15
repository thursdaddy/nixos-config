_: {
  flake.modules.nixos.apps =
    { lib, pkgs, ... }:
    {
      nixpkgs.config = {
        permittedInsecurePackages = [
          "electron-25.9.0"
        ];
        allowUnfreePredicate =
          pkg:
          let
            name = lib.getName pkg;
          in
          name == "obsidian" || lib.hasPrefix "obsidian" name;
      };

      nixpkgs.config.allowUnfree = true;
      environment.systemPackages = with pkgs; [
        obsidian
      ];
    };

  flake.modules.darwin.apps = {
    homebrew.casks = [ "obsidian" ];

    system.defaults.dock.persistent-apps = [ "/Applications/Obsidian.app" ];
  };
}
